import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../../models/poi_translation.dart';
import '../../core/config/backend_config.dart';

class POITranslationService {
  static final POITranslationService _instance =
      POITranslationService._internal();
  factory POITranslationService() => _instance;
  POITranslationService._internal();

  final Map<String, POITranslation> _memoryCache = {};
  static const List<String> supportedCities = [
    '北京', '上海', '广州', '深圳', '成都', '西安',
  ];

  late Connection _db;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _db = await Connection.open(
      Endpoint(
        host: BackendConfig.databaseHost,
        port: BackendConfig.databasePort,
        database: BackendConfig.databaseName,
        username: BackendConfig.databaseUsername,
        password: BackendConfig.databasePassword,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    await _preloadCorePOIs();
    _initialized = true;
    print('✅ POITranslationService initialized (${_memoryCache.length} POIs)');
  }

  Future<void> _preloadCorePOIs() async {
    try {
      final result = await _db.execute(
        Sql.named('''
          SELECT * FROM poi_translations
          WHERE city = ANY(@cities)
            AND category_en IN (
              'Attraction', 'Metro Station', 'Transport Hub', 'Museum', 'Park'
            )
          ORDER BY priority_score DESC
          LIMIT 2000
        '''),
        parameters: {'cities': supportedCities},
      );
      for (final row in result) {
        final poi = POITranslation.fromJson(row.toColumnMap());
        _memoryCache[poi.gaodePoiId] = poi;
      }
    } catch (e) {
      print('⚠️ 预加载POI失败: $e');
    }
  }

  Future<Map<String, POITranslation>> getTranslations({
    required List<String> gaodePoiIds,
    required AppLanguage language,
  }) async {
    final result = <String, POITranslation>{};
    final missedIds = <String>[];

    for (final id in gaodePoiIds) {
      if (_memoryCache.containsKey(id)) {
        result[id] = _memoryCache[id]!;
      } else {
        missedIds.add(id);
      }
    }
    if (missedIds.isEmpty) return result;

    final dbMissed = await _queryFromDatabase(missedIds, result);
    if (dbMissed.isNotEmpty) {
      print('ℹ️ ${dbMissed.length} POIs not in DB, use translateRawPOIs()');
    }
    return result;
  }

  Future<List<String>> _queryFromDatabase(
    List<String> ids,
    Map<String, POITranslation> result,
  ) async {
    try {
      final dbResult = await _db.execute(
        Sql.named('SELECT * FROM poi_translations WHERE gaode_poi_id = ANY(@ids)'),
        parameters: {'ids': ids},
      );
      for (final row in dbResult) {
        final poi = POITranslation.fromJson(row.toColumnMap());
        result[poi.gaodePoiId] = poi;
        _memoryCache[poi.gaodePoiId] = poi;
      }
      return ids.where((id) => !result.containsKey(id)).toList();
    } catch (e) {
      print('⚠️ DB查询失败: $e');
      return ids;
    }
  }

  /// 翻译高德原始POI数据（含中文名），用于实时翻译未缓存的POI
  /// rawPOIs 每条需包含: gaode_poi_id, name_zh, category_zh, city, lat, lng
  Future<List<POITranslation>> translateRawPOIs({
    required List<Map<String, dynamic>> rawPOIs,
    AppLanguage primaryLanguage = AppLanguage.english,
  }) async {
    if (rawPOIs.isEmpty) return [];

    final uncached = rawPOIs
        .where((p) => !_memoryCache.containsKey(p['gaode_poi_id']))
        .toList();

    if (uncached.isEmpty) {
      return rawPOIs
          .map((p) => _memoryCache[p['gaode_poi_id']])
          .whereType<POITranslation>()
          .toList();
    }

    final translated = await _callDeepSeekBatch(uncached);
    for (final poi in translated) {
      _memoryCache[poi.gaodePoiId] = poi;
      await _saveToDB(poi);
    }

    // 合并缓存命中 + 新翻译
    return rawPOIs
        .map((p) => _memoryCache[p['gaode_poi_id']])
        .whereType<POITranslation>()
        .toList();
  }

  Future<List<POITranslation>> _callDeepSeekBatch(
    List<Map<String, dynamic>> rawPOIs,
  ) async {
    final poiList = rawPOIs
        .map((p) =>
            '${p['gaode_poi_id']}|${p['name_zh']}|${p['category_zh'] ?? '地点'}')
        .join('\n');

    final prompt = '''
Translate the following Chinese POI names to English for a travel app for foreign tourists in China.
Return ONLY a valid JSON object: {"translations": [{"id":"...","name_en":"...","category_en":"..."}]}

Rules:
- Use well-known English names (e.g. "West Lake" not "Xihu")
- Metro stations: "XXX Station" format
- Streets: keep pinyin + "Road/Street/Avenue"
- category_en: one of Attraction, Restaurant, Hotel, Metro Station, Transport Hub, Museum, Park, Shopping, Hospital, Bank, Other

POIs:
$poiList
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${BackendConfig.deepseekApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional Chinese-English translator for travel apps.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
          'max_tokens': 2000,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final jsonData = jsonDecode(content);
        final translations = (jsonData['translations'] ?? []) as List;

        final result = <POITranslation>[];
        for (final t in translations) {
          final original = rawPOIs.firstWhere(
            (p) => p['gaode_poi_id'] == t['id'],
            orElse: () => {},
          );
          if (original.isEmpty) continue;
          result.add(POITranslation(
            gaodePoiId: t['id'] as String,
            nameZh: original['name_zh'] as String,
            nameEn: t['name_en'] as String,
            categoryEn: t['category_en'] as String?,
            city: original['city'] as String,
            coordinates: LatLng(
              (original['lat'] as num).toDouble(),
              (original['lng'] as num).toDouble(),
            ),
            source: TranslationSource.deepseek,
            cachedAt: DateTime.now(),
          ));
        }
        return result;
      }
    } catch (e) {
      print('⚠️ DeepSeek批量翻译失败: $e');
    }

    // 拼音回退
    return rawPOIs
        .map((p) => POITranslation(
              gaodePoiId: p['gaode_poi_id'] as String,
              nameZh: p['name_zh'] as String,
              nameEn: p['name_zh'] as String, // TODO: 接入拼音转换包
              city: p['city'] as String,
              coordinates: LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ),
              source: TranslationSource.fallback,
              cachedAt: DateTime.now(),
            ))
        .toList();
  }

  Future<void> _saveToDB(POITranslation poi) async {
    try {
      await _db.execute(
        Sql.named('''
          INSERT INTO poi_translations
            (gaode_poi_id, name_zh, name_en, name_fr, name_es,
             category_en, city, lat, lng, source, cached_at)
          VALUES
            (@id, @zh, @en, @fr, @es, @cat, @city, @lat, @lng, @src, @time)
          ON CONFLICT (gaode_poi_id) DO UPDATE SET
            name_en   = EXCLUDED.name_en,
            source    = EXCLUDED.source,
            cached_at = EXCLUDED.cached_at
        '''),
        parameters: {
          'id': poi.gaodePoiId,
          'zh': poi.nameZh,
          'en': poi.nameEn,
          'fr': poi.nameFr,
          'es': poi.nameEs,
          'cat': poi.categoryEn,
          'city': poi.city,
          'lat': poi.coordinates.latitude,
          'lng': poi.coordinates.longitude,
          'src': poi.source.name,
          'time': poi.cachedAt.toIso8601String(),
        },
      );
    } catch (e) {
      print('⚠️ 保存翻译到DB失败: $e');
    }
  }

  void dispose() {
    _db.close();
    _initialized = false;
  }
}
