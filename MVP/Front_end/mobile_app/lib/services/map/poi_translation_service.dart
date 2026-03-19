import 'package:flutter/foundation.dart';
// lib/services/map/poi_translation_service.dart
import 'package:x_amap_base/x_amap_base.dart';
import '../../models/poi_translation.dart';
import '../api_client.dart';

class POITranslationService {
  static final POITranslationService _instance = POITranslationService._internal();
  factory POITranslationService() => _instance;
  POITranslationService._internal();

  final Map<String, POITranslation> _memoryCache = {};

  /// 获取附近 POI 翻译（调用 get_nearby_pois 云函数）
  Future<List<POITranslation>> getNearbyPOIs({
    required double latitude,
    required double longitude,
    String lang = 'en',
    int radius = 2000,
    int limit = 50,
  }) async {
    try {
      final result = await ApiClient.post(ApiClient.nearbyUrl, {
        'latitude': latitude,
        'longitude': longitude,
        'lang': lang,
        'radius': radius,
        'limit': limit,
      });

      final pois = (result['pois'] as List).map((p) => POITranslation(
        gaodePoiId: p['poi_id'],
        nameZh: p['name_zh'],
        nameEn: p['name_translated'] ?? '',
        categoryEn: p['category'],
        city: '',
        coordinates: LatLng(
          (p['lat'] as num).toDouble(),
          (p['lng'] as num).toDouble(),
        ),
        source: TranslationSource.database,
        cachedAt: DateTime.now(),
      )).toList();

      // 更新内存缓存
      for (final poi in pois) {
        _memoryCache[poi.gaodePoiId] = poi;
      }

      return pois;
    } catch (e) {
      debugPrint('[POI] getNearbyPOIs failed: $e');
      return [];
    }
  }

  /// 获取翻译（先查内存缓存，再查云函数 Redis 缓存）
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

    // 未命中的通过云函数批量查
    for (final id in missedIds) {
      try {
        final langStr = language == AppLanguage.french ? 'fr'
            : language == AppLanguage.spanish ? 'es' : 'en';
        final cacheResult = await ApiClient.post(ApiClient.dbWriteUrl, {
          'poi_id': id,
          'action': 'get',
          'target_lang': langStr,
        });
        if (cacheResult['cached'] == true && cacheResult['translated_text'] != null) {
          // 构造 POITranslation 对象加入结果
          // 注意：这里只有单语翻译文本，不是完整 POI 对象
          // 如果需要完整信息，需从 _memoryCache 或其他途径获取
        }
      } catch (e) {
        debugPrint('[POI] Cache query failed for $id: $e');
      }
    }

    return result;
  }

  /// 翻译原始 POI（调用 DeepSeek + 写入 DB）
  Future<List<POITranslation>> translateRawPOIs({
    required List<Map<String, dynamic>> rawPOIs,
    AppLanguage primaryLanguage = AppLanguage.english,
  }) async {
    final results = <POITranslation>[];

    for (final poi in rawPOIs) {
      final poiId = poi['gaode_poi_id'] as String;
      final nameZh = poi['name_zh'] as String;

      // 先检查内存缓存
      if (_memoryCache.containsKey(poiId)) {
        results.add(_memoryCache[poiId]!);
        continue;
      }

      try {
        // 调用 DeepSeek 翻译
        final translated = await ApiClient.post(ApiClient.translateUrl, {
          'text': nameZh,
          'target_lang': 'en',
        });

        final nameEn = translated['translated_text'] as String;

        // 保存到 DB + Redis
        await ApiClient.post(ApiClient.dbWriteUrl, {
          'poi_id': poiId,
          'name_zh': nameZh,
          'name_en': nameEn,
          'latitude': poi['lat'],
          'longitude': poi['lng'],
          'city': poi['city'],
          'action': 'save',
        });

        final poiTrans = POITranslation(
          gaodePoiId: poiId,
          nameZh: nameZh,
          nameEn: nameEn,
          city: poi['city'] ?? '',
          coordinates: LatLng(
            (poi['lat'] as num).toDouble(),
            (poi['lng'] as num).toDouble(),
          ),
          source: TranslationSource.deepseek,
          cachedAt: DateTime.now(),
        );

        _memoryCache[poiId] = poiTrans;
        results.add(poiTrans);
      } catch (e) {
        debugPrint('[POI] Translation failed for $poiId: $e');
      }
    }

    return results;
  }

  void dispose() {
    _memoryCache.clear();
  }
}
