# WanderChina — 地图翻译蒙层 + 语音翻译 实现规范

> **写给 Claude Code：** 本文档包含完整的实现规范和所有代码。按顺序执行即可，无需额外询问。

---

## 1. 功能概述

### 1.1 地图翻译蒙层（Map Translation Overlay）

在高德地图（中文底图）上叠加英文/法文/西班牙文标注，帮助外国游客识别中文地名。

**核心设计决策：**
- 高德SDK负责地图渲染和POI搜索（中国本土数据最全）
- Flutter `Stack + IgnorePointer` 叠加翻译标签（不阻断地图手势）
- 三级缓存：内存 → 腾讯云PostgreSQL → DeepSeek实时翻译
- 300ms防抖：地图停止移动后再刷新标签

### 1.2 语音翻译（Voice Translation）

外国游客在景点、餐厅、问路时的实时双向语音翻译。

**链路：** 百度ASR（语音识别）→ DeepSeek（翻译）→ 百度TTS（语音播放）

**两个方向：**
- 外语 → 中文：帮游客用中文交流（问路、点餐、砍价）
- 中文 → 外语：帮游客听懂本地人回复

---

## 2. 技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| 地图底图 | 高德SDK `amap_flutter_map` | 中国本土POI数据最准确 |
| POI翻译存储 | 腾讯云PostgreSQL | 已有数据库，迁移自Supabase |
| 实时翻译 | DeepSeek API | 已在项目中使用 |
| 语音识别 | 百度语音 ASR | 中文识别最强，外语识别够用，国内无墙 |
| 语音合成 | 百度语音 TTS | 与ASR同平台，简化Token管理 |
| 录音 | `record` 包 | Flutter跨平台录音 |
| 音频播放 | `audioplayers` 包 | TTS结果播放 |
| 状态管理 | `ChangeNotifier` | 与现有项目保持一致 |

---

## 3. 文件结构

```
lib/
├── models/
│   └── poi_translation.dart           # 数据模型
├── services/
│   ├── map/
│   │   └── map_translation_service.dart   # 翻译服务（三级缓存）
│   └── voice/
│       └── voice_translation_service.dart # 语音翻译服务
├── widgets/
│   └── map/
│       ├── translation_overlay_widget.dart # 翻译标签渲染
│       ├── voice_translation_overlay.dart  # 语音按钮UI
│       └── wander_map.dart                 # 地图主组件（整合以上）
└── screens/
    └── explore/
        └── city_map_screen.dart       # 使用示例

sql/
└── poi_translations_init.sql          # 建表脚本 + 种子数据
```

---

## 4. 依赖配置

### 4.1 pubspec.yaml 新增依赖

```yaml
dependencies:
  # 录音
  record: ^5.1.2
  
  # 音频播放（TTS结果）
  audioplayers: ^6.0.0
  
  # 临时目录（存储音频文件）
  path_provider: ^2.1.3

  # 以下应已存在，确认版本
  http: ^1.1.0
  postgres: ^2.6.2
```

### 4.2 iOS 权限配置（ios/Runner/Info.plist）

```xml
<!-- 麦克风权限 -->
<key>NSMicrophoneUsageDescription</key>
<string>WanderChina needs microphone access for voice translation</string>
```

### 4.3 Android 权限配置（android/app/src/main/AndroidManifest.xml）

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 5. 环境变量配置

在 `lib/core/config/env_config.dart` 中新增：

```dart
class EnvConfig {
  // ... 现有配置保持不变 ...

  // 百度语音 API（在 https://ai.baidu.com 申请）
  static const String baiduApiKey = String.fromEnvironment(
    'BAIDU_API_KEY',
    defaultValue: '',
  );
  static const String baiduSecretKey = String.fromEnvironment(
    'BAIDU_SECRET_KEY',
    defaultValue: '',
  );

  // DeepSeek（应已存在）
  static const String deepseekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );
}
```

---

## 6. 数据库初始化

在腾讯云 PostgreSQL 执行以下 SQL：

```sql
-- ================================================================
-- poi_translations 表初始化
-- ================================================================

CREATE TABLE IF NOT EXISTS poi_translations (
  id              SERIAL PRIMARY KEY,
  gaode_poi_id    TEXT NOT NULL UNIQUE,
  name_zh         TEXT NOT NULL,
  name_en         TEXT NOT NULL,
  name_fr         TEXT,
  name_es         TEXT,
  category_en     TEXT,
  city            TEXT NOT NULL,
  lat             DECIMAL(10, 8) NOT NULL,
  lng             DECIMAL(11, 8) NOT NULL,
  source          TEXT DEFAULT 'database'
                  CHECK (source IN ('database','deepseek','manual','fallback')),
  priority_score  INT DEFAULT 0,
  cached_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_poi_city ON poi_translations(city);
CREATE INDEX IF NOT EXISTS idx_poi_priority ON poi_translations(priority_score DESC);
CREATE INDEX IF NOT EXISTS idx_poi_location ON poi_translations
  USING GIST (ST_MakePoint(lng, lat));

-- 自动更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER poi_translations_updated_at
  BEFORE UPDATE ON poi_translations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ================================================================
-- 种子数据：6城市核心景点（人工校对，priority_score=100）
-- ================================================================

INSERT INTO poi_translations
  (gaode_poi_id, name_zh, name_en, name_fr, name_es, category_en, city, lat, lng, source, priority_score)
VALUES
-- 北京
('B000A7BD6F', '故宫博物院', 'Palace Museum (Forbidden City)',
  'Musée du Palais (Cité Interdite)', 'Museo del Palacio (Ciudad Prohibida)',
  'Attraction', '北京', 39.91633, 116.39720, 'manual', 100),
('B000A7BD72', '天安门广场', 'Tiananmen Square',
  'Place Tiananmen', 'Plaza de Tiananmen',
  'Attraction', '北京', 39.90527, 116.39723, 'manual', 100),
('B000A83JEH', '颐和园', 'Summer Palace',
  'Palais d''Été', 'Palacio de Verano',
  'Attraction', '北京', 39.99901, 116.27551, 'manual', 95),
('B000A83JPW', '天坛公园', 'Temple of Heaven',
  'Temple du Ciel', 'Templo del Cielo',
  'Park', '北京', 39.88249, 116.41115, 'manual', 95),
('B000A7BJUH', '北京首都国际机场', 'Beijing Capital International Airport',
  'Aéroport International de Pékin-Capital', 'Aeropuerto Internacional de Beijing Capital',
  'Transport Hub', '北京', 40.07970, 116.58454, 'manual', 90),
-- 上海
('B00155EFI9', '外滩', 'The Bund',
  'Le Bund', 'El Bund',
  'Attraction', '上海', 31.23963, 121.48910, 'manual', 100),
('B0015FJ66E', '东方明珠广播电视塔', 'Oriental Pearl Tower',
  'Tour de la Perle Orientale', 'Torre de la Perla Oriental',
  'Attraction', '上海', 31.23957, 121.49993, 'manual', 100),
('B0016C3UCQ', '豫园', 'Yu Garden',
  'Jardin Yu', 'Jardín Yu',
  'Attraction', '上海', 31.22740, 121.49214, 'manual', 95),
('B001553LCI', '上海迪士尼乐园', 'Shanghai Disneyland',
  'Disneyland Shanghai', 'Disneyland Shanghái',
  'Attraction', '上海', 31.14461, 121.66363, 'manual', 95),
-- 广州
('B02FH02NWH', '广州塔', 'Canton Tower',
  'Tour de Canton', 'Torre de Cantón',
  'Attraction', '广州', 23.10592, 113.32385, 'manual', 100),
('B02FH0KTJ1', '陈家祠', 'Chen Clan Ancestral Hall',
  'Salle Ancestrale du Clan Chen', 'Sala Ancestral del Clan Chen',
  'Museum', '广州', 23.12663, 113.23897, 'manual', 90),
-- 深圳
('B02F12C1VF', '深圳湾公园', 'Shenzhen Bay Park',
  'Parc de la Baie de Shenzhen', 'Parque de la Bahía de Shenzhen',
  'Park', '深圳', 22.50877, 113.95045, 'manual', 85),
('B02F101DT5', '世界之窗', 'Window of the World',
  'Fenêtre sur le Monde', 'Ventana al Mundo',
  'Attraction', '深圳', 22.53565, 113.97317, 'manual', 90),
-- 成都
('B001C8VMKU', '成都大熊猫繁育研究基地', 'Chengdu Giant Panda Breeding Research Base',
  'Base de Recherche sur les Pandas Géants', 'Base de Investigación de Cría de Pandas Gigantes',
  'Attraction', '成都', 30.73660, 104.14573, 'manual', 100),
('B001C8WL5R', '宽窄巷子', 'Wide and Narrow Alleys',
  'Ruelles Larges et Étroites', 'Callejones Anchos y Estrechos',
  'Attraction', '成都', 30.67139, 104.05626, 'manual', 95),
('B001C8VM3U', '锦里古街', 'Jinli Ancient Street',
  'Rue Ancienne de Jinli', 'Calle Antigua de Jinli',
  'Attraction', '成都', 30.64106, 104.07366, 'manual', 90),
-- 西安
('B001HC6BGN', '秦始皇兵马俑博物馆', 'Terracotta Army Museum',
  'Musée de l''Armée de Terre Cuite', 'Museo del Ejército de Terracota',
  'Museum', '西安', 34.38441, 109.27350, 'manual', 100),
('B001HD13MF', '西安城墙', 'Xi''an City Wall',
  'Muraille de Xi''an', 'Muralla de Xi''an',
  'Attraction', '西安', 34.25919, 108.93060, 'manual', 100),
('B001HC5MV5', '大雁塔', 'Big Wild Goose Pagoda',
  'Grande Pagode de l''Oie Sauvage', 'Gran Pagoda del Ganso Salvaje',
  'Attraction', '西安', 34.22349, 108.96003, 'manual', 95),
('B001HC6DH0', '大唐不夜城', 'Tang Paradise',
  'Cité Resplendissante des Tang', 'Ciudad Brillante de la Dinastía Tang',
  'Attraction', '西安', 34.21950, 108.96302, 'manual', 90)

ON CONFLICT (gaode_poi_id) DO UPDATE SET
  name_en = EXCLUDED.name_en,
  name_fr = EXCLUDED.name_fr,
  name_es = EXCLUDED.name_es,
  priority_score = EXCLUDED.priority_score,
  updated_at = CURRENT_TIMESTAMP;
```

---

## 7. 完整代码

### 7.1 `lib/models/poi_translation.dart`

```dart
import 'package:amap_flutter_map/amap_flutter_map.dart';

class POITranslation {
  final String gaodePoiId;
  final String nameZh;
  final String nameEn;
  final String? nameFr;
  final String? nameEs;
  final String? categoryEn;
  final String city;
  final LatLng coordinates;
  final TranslationSource source;
  final DateTime cachedAt;

  const POITranslation({
    required this.gaodePoiId,
    required this.nameZh,
    required this.nameEn,
    this.nameFr,
    this.nameEs,
    this.categoryEn,
    required this.city,
    required this.coordinates,
    required this.source,
    required this.cachedAt,
  });

  String localizedName(AppLanguage language) {
    switch (language) {
      case AppLanguage.french:
        return nameFr ?? nameEn;
      case AppLanguage.spanish:
        return nameEs ?? nameEn;
      case AppLanguage.english:
      default:
        return nameEn;
    }
  }

  factory POITranslation.fromJson(Map<String, dynamic> json) {
    return POITranslation(
      gaodePoiId: json['gaode_poi_id'] as String,
      nameZh: json['name_zh'] as String,
      nameEn: json['name_en'] as String,
      nameFr: json['name_fr'] as String?,
      nameEs: json['name_es'] as String?,
      categoryEn: json['category_en'] as String?,
      city: json['city'] as String,
      coordinates: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      source: TranslationSource.values.firstWhere(
        (e) => e.name == (json['source'] ?? 'database'),
        orElse: () => TranslationSource.database,
      ),
      cachedAt: DateTime.parse(
          json['cached_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'gaode_poi_id': gaodePoiId,
    'name_zh': nameZh,
    'name_en': nameEn,
    'name_fr': nameFr,
    'name_es': nameEs,
    'category_en': categoryEn,
    'city': city,
    'lat': coordinates.latitude,
    'lng': coordinates.longitude,
    'source': source.name,
    'cached_at': cachedAt.toIso8601String(),
  };
}

enum TranslationSource { database, deepseek, manual, fallback }

enum AppLanguage { english, french, spanish }

class OverlayLabel {
  final POITranslation translation;
  final Offset screenPosition;
  final bool isHighPriority;

  const OverlayLabel({
    required this.translation,
    required this.screenPosition,
    required this.isHighPriority,
  });
}
```

---

### 7.2 `lib/services/map/map_translation_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import '../../models/poi_translation.dart';
import '../../core/config/database_config.dart';
import '../../core/config/env_config.dart';

class MapTranslationService {
  static final MapTranslationService _instance =
      MapTranslationService._internal();
  factory MapTranslationService() => _instance;
  MapTranslationService._internal();

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
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        database: DatabaseConfig.database,
        username: DatabaseConfig.username,
        password: DatabaseConfig.password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    await _preloadCorePOIs();
    _initialized = true;
    print('✅ MapTranslationService initialized (${_memoryCache.length} POIs)');
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
          'Authorization': 'Bearer ${EnvConfig.deepseekApiKey}',
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
```

---

### 7.3 `lib/services/voice/voice_translation_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../../models/poi_translation.dart';
import '../../core/config/env_config.dart';

enum TranslationDirection {
  foreignToChinese, // EN/FR/ES → 中文
  chineseToForeign, // 中文 → EN/FR/ES
}

class VoiceTranslationResult {
  final String originalText;
  final String translatedText;
  final TranslationDirection direction;
  final AppLanguage foreignLanguage;
  final Duration processingTime;

  const VoiceTranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.direction,
    required this.foreignLanguage,
    required this.processingTime,
  });
}

enum VoiceServiceState { idle, recording, processing, playing, error }

class VoiceTranslationService extends ChangeNotifier {
  static final VoiceTranslationService _instance =
      VoiceTranslationService._internal();
  factory VoiceTranslationService() => _instance;
  VoiceTranslationService._internal();

  static const String _baiduASRUrl   = 'https://vop.baidu.com/server_api';
  static const String _baiduTTSUrl   = 'https://tsn.baidu.com/text2audio';
  static const String _baiduTokenUrl =
      'https://aip.baidubce.com/oauth/2.0/token';

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer   _player   = AudioPlayer();

  VoiceServiceState _state = VoiceServiceState.idle;
  VoiceServiceState get state => _state;

  String?   _baiduAccessToken;
  DateTime? _tokenExpiry;

  final List<VoiceTranslationResult> _history = [];
  List<VoiceTranslationResult> get history => List.unmodifiable(_history);

  // ─── 初始化 ───────────────────────────────────────────

  Future<void> initialize() async {
    await _refreshBaiduToken();
    print('✅ VoiceTranslationService initialized');
  }

  Future<void> _refreshBaiduToken() async {
    try {
      final response = await http.post(
        Uri.parse(_baiduTokenUrl),
        body: {
          'grant_type':    'client_credentials',
          'client_id':     EnvConfig.baiduApiKey,
          'client_secret': EnvConfig.baiduSecretKey,
        },
      );
      if (response.statusCode == 200) {
        final data           = jsonDecode(response.body);
        _baiduAccessToken    = data['access_token'] as String;
        _tokenExpiry         = DateTime.now().add(const Duration(days: 29));
        print('✅ 百度Token获取成功');
      }
    } catch (e) {
      print('⚠️ 百度Token获取失败: $e');
    }
  }

  Future<String?> get _validToken async {
    if (_baiduAccessToken == null ||
        (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!))) {
      await _refreshBaiduToken();
    }
    return _baiduAccessToken;
  }

  // ─── 公开接口 ─────────────────────────────────────────

  Future<void> startRecording() async {
    if (_state != VoiceServiceState.idle) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _setState(VoiceServiceState.error);
      throw Exception('麦克风权限未授权');
    }

    final dir  = await getTemporaryDirectory();
    final path =
        '${dir.path}/wander_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder:    AudioEncoder.aacLc,
        bitRate:    128000,
        sampleRate: 16000, // 百度ASR推荐
      ),
      path: path,
    );
    _setState(VoiceServiceState.recording);
  }

  Future<VoiceTranslationResult?> stopAndTranslate({
    required TranslationDirection direction,
    required AppLanguage foreignLanguage,
  }) async {
    if (_state != VoiceServiceState.recording) return null;

    _setState(VoiceServiceState.processing);
    final stopwatch = Stopwatch()..start();

    try {
      final audioPath = await _recorder.stop();
      if (audioPath == null) throw Exception('录音文件为空');

      // Step 1: 百度ASR
      final sourceLang = direction == TranslationDirection.foreignToChinese
          ? foreignLanguage
          : null;
      final recognized = await _baiduASR(audioPath: audioPath, language: sourceLang);
      if (recognized == null || recognized.isEmpty) {
        throw Exception('语音识别失败或无声音');
      }

      // Step 2: DeepSeek翻译
      final translated = await _deepSeekTranslate(
        text:           recognized,
        direction:      direction,
        foreignLanguage: foreignLanguage,
      );

      // Step 3: 百度TTS播放
      await _baiduTTS(
        text:      translated,
        isChinese: direction == TranslationDirection.foreignToChinese,
      );

      stopwatch.stop();
      final result = VoiceTranslationResult(
        originalText:    recognized,
        translatedText:  translated,
        direction:       direction,
        foreignLanguage: foreignLanguage,
        processingTime:  stopwatch.elapsed,
      );
      _history.add(result);

      try { File(audioPath).deleteSync(); } catch (_) {}
      return result;
    } catch (e) {
      print('⚠️ 语音翻译链路失败: $e');
      _setState(VoiceServiceState.error);
      await Future.delayed(const Duration(seconds: 2));
      _setState(VoiceServiceState.idle);
      return null;
    }
  }

  Future<void> cancelRecording() async {
    if (_state == VoiceServiceState.recording) {
      await _recorder.cancel();
      _setState(VoiceServiceState.idle);
    }
  }

  Future<void> stopPlaying() async {
    await _player.stop();
    _setState(VoiceServiceState.idle);
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  // ─── 百度ASR ──────────────────────────────────────────

  Future<String?> _baiduASR({
    required String audioPath,
    AppLanguage?   language,
  }) async {
    final token = await _validToken;
    if (token == null) throw Exception('百度Token无效');

    final audioBytes  = await File(audioPath).readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    // 百度ASR dev_pid: 1537中文, 1737英文, 1836法文, 1936西班牙文
    final langId = switch (language) {
      AppLanguage.english  => 1737,
      AppLanguage.french   => 1836,
      AppLanguage.spanish  => 1936,
      _                    => 1537,
    };

    try {
      final response = await http.post(
        Uri.parse(_baiduASRUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'format':  'm4a',
          'rate':    16000,
          'channel': 1,
          'cuid':    'wanderchina_app',
          'token':   token,
          'dev_pid': langId,
          'speech':  base64Audio,
          'len':     audioBytes.length,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['err_no'] == 0 && data['result'] != null) {
          final results = data['result'] as List;
          return results.isNotEmpty ? results.first as String : null;
        }
        print('百度ASR错误: ${data['err_msg']}');
      }
    } catch (e) {
      print('⚠️ 百度ASR请求失败: $e');
    }
    return null;
  }

  // ─── DeepSeek翻译 ─────────────────────────────────────

  Future<String> _deepSeekTranslate({
    required String text,
    required TranslationDirection direction,
    required AppLanguage foreignLanguage,
  }) async {
    final targetLangName = switch (foreignLanguage) {
      AppLanguage.english  => 'English',
      AppLanguage.french   => 'French',
      AppLanguage.spanish  => 'Spanish',
    };

    final String systemPrompt;
    final String userPrompt;

    if (direction == TranslationDirection.foreignToChinese) {
      systemPrompt =
          'You are a travel interpreter. Translate to natural spoken Chinese (Mandarin). '
          'Keep it concise for everyday situations. Return ONLY the Chinese translation.';
      userPrompt = 'Translate this $targetLangName to Chinese: "$text"';
    } else {
      systemPrompt =
          'You are a travel interpreter. Translate Chinese to natural $targetLangName. '
          'Add brief cultural context if helpful (e.g., "100块 (¥100 ≈ \$14)"). '
          'Return ONLY the $targetLangName translation.';
      userPrompt = 'Translate this Chinese to $targetLangName: "$text"';
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${EnvConfig.deepseekApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.2,
          'max_tokens':  300,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['choices'][0]['message']['content'] as String).trim();
      }
    } catch (e) {
      print('⚠️ DeepSeek翻译失败: $e');
    }
    return text; // 降级：返回原文
  }

  // ─── 百度TTS ──────────────────────────────────────────

  Future<void> _baiduTTS({
    required String text,
    required bool   isChinese,
  }) async {
    final token = await _validToken;
    if (token == null) return;

    // per: 4=中文情感女声, 5=英文女声
    final per = isChinese ? 4 : 5;

    try {
      final uri = Uri.parse(_baiduTTSUrl).replace(queryParameters: {
        'tex': text,
        'tok': token,
        'cuid': 'wanderchina_app',
        'ctp':  '1',
        'lan':  isChinese ? 'zh' : 'en',
        'spd':  '5',
        'pit':  '5',
        'vol':  '10',
        'per':  per.toString(),
        'aue':  '3', // mp3
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains('audio') == true) {
        final dir     = await getTemporaryDirectory();
        final ttsPath =
            '${dir.path}/wander_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        await File(ttsPath).writeAsBytes(response.bodyBytes);

        _setState(VoiceServiceState.playing);
        await _player.play(DeviceFileSource(ttsPath));

        _player.onPlayerComplete.first.then((_) {
          try { File(ttsPath).deleteSync(); } catch (_) {}
          _setState(VoiceServiceState.idle);
        });
      }
    } catch (e) {
      print('⚠️ 百度TTS失败: $e');
      _setState(VoiceServiceState.idle);
    }
  }

  void _setState(VoiceServiceState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
```

---

### 7.4 `lib/widgets/map/translation_overlay_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../../models/poi_translation.dart';
import '../../services/map/map_translation_service.dart';

enum LabelStyle { badge, minimal, floating }

class TranslationOverlayConfig {
  final AppLanguage language;
  final LabelStyle  labelStyle;
  final bool        showCategory;
  final double      minZoomToShow;
  final int         maxLabelsOnScreen;

  const TranslationOverlayConfig({
    this.language          = AppLanguage.english,
    this.labelStyle        = LabelStyle.badge,
    this.showCategory      = false,
    this.minZoomToShow     = 14.0,
    this.maxLabelsOnScreen = 12,
  });
}

class TranslationOverlay extends StatefulWidget {
  final AMapController              mapController;
  final List<Map<String, dynamic>>  visiblePOIs;
  final TranslationOverlayConfig    config;
  final double                      currentZoom;

  const TranslationOverlay({
    super.key,
    required this.mapController,
    required this.visiblePOIs,
    required this.config,
    required this.currentZoom,
  });

  @override
  State<TranslationOverlay> createState() => _TranslationOverlayState();
}

class _TranslationOverlayState extends State<TranslationOverlay>
    with AutomaticKeepAliveClientMixin {

  final MapTranslationService _svc = MapTranslationService();
  List<OverlayLabel> _labels   = [];
  bool               _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(TranslationOverlay old) {
    super.didUpdateWidget(old);
    if (old.visiblePOIs != widget.visiblePOIs ||
        old.config.language != widget.config.language) {
      _rebuildLabels();
    }
  }

  Future<void> _rebuildLabels() async {
    if (_isLoading) return;
    if (widget.currentZoom < widget.config.minZoomToShow) {
      setState(() => _labels = []);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final ids = widget.visiblePOIs
          .map((p) => p['id'] as String? ?? p['poiId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .take(widget.config.maxLabelsOnScreen * 2)
          .toList();

      if (ids.isEmpty) {
        setState(() { _labels = []; _isLoading = false; });
        return;
      }

      final translations = await _svc.getTranslations(
        gaodePoiIds: ids,
        language:    widget.config.language,
      );

      final labels = <OverlayLabel>[];
      for (final poi in widget.visiblePOIs) {
        final id    = poi['id'] as String? ?? poi['poiId'] as String? ?? '';
        final trans = translations[id];
        if (trans == null) continue;

        final pt = await widget.mapController.convertCoordinate(trans.coordinates);
        if (pt == null) continue;

        labels.add(OverlayLabel(
          translation:   trans,
          screenPosition: Offset(pt.x, pt.y),
          isHighPriority: _isHighPriority(trans.categoryEn),
        ));
      }

      labels.sort((a, b) => b.isHighPriority ? 1 : -1);
      final filtered = _deduplicate(labels);

      if (mounted) {
        setState(() {
          _labels    = filtered.take(widget.config.maxLabelsOnScreen).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('⚠️ 翻译蒙层重建失败: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OverlayLabel> _deduplicate(List<OverlayLabel> labels) {
    const minDist = 80.0;
    final result  = <OverlayLabel>[];
    for (final label in labels) {
      final tooClose = result.any((e) {
        final dx = e.screenPosition.dx - label.screenPosition.dx;
        final dy = e.screenPosition.dy - label.screenPosition.dy;
        return (dx * dx + dy * dy) < (minDist * minDist);
      });
      if (!tooClose) result.add(label);
    }
    return result;
  }

  bool _isHighPriority(String? cat) => const [
    'Attraction', 'Museum', 'Park', 'Metro Station', 'Transport Hub',
  ].contains(cat);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.currentZoom < widget.config.minZoomToShow) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Stack(
        children: [
          for (final label in _labels)
            Positioned(
              left: label.screenPosition.dx,
              top:  label.screenPosition.dy,
              child: _buildLabel(label),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(OverlayLabel label) {
    switch (widget.config.labelStyle) {
      case LabelStyle.badge:
        return _BadgeLabel(label: label, config: widget.config);
      case LabelStyle.minimal:
        return _MinimalLabel(label: label, config: widget.config);
      case LabelStyle.floating:
        return _FloatingLabel(label: label, config: widget.config);
    }
  }
}

// ─── Badge样式 ─────────────────────────────────────────────────

class _BadgeLabel extends StatelessWidget {
  final OverlayLabel             label;
  final TranslationOverlayConfig config;
  const _BadgeLabel({required this.label, required this.config});

  @override
  Widget build(BuildContext context) {
    final name = label.translation.localizedName(config.language);
    return Transform.translate(
      offset: Offset(-(name.length * 3.0 + 6), -36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: label.isHighPriority
                  ? const Color(0xE6FF6B35)
                  : const Color(0xE6FFFFFF),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: label.isHighPriority ? FontWeight.w700 : FontWeight.w500,
                    color:      label.isHighPriority ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: 0.2,
                  ),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
                if (config.showCategory && label.translation.categoryEn != null)
                  Text(
                    label.translation.categoryEn!,
                    style: TextStyle(
                      fontSize: 8,
                      color: label.isHighPriority ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(8, 5),
            painter: _PointerPainter(
              color: label.isHighPriority
                  ? const Color(0xE6FF6B35)
                  : const Color(0xE6FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalLabel extends StatelessWidget {
  final OverlayLabel             label;
  final TranslationOverlayConfig config;
  const _MinimalLabel({required this.label, required this.config});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-30, -28),
      child: Text(
        label.translation.localizedName(config.language),
        style: TextStyle(
          fontSize:   9,
          fontWeight: FontWeight.w600,
          color: label.isHighPriority
              ? const Color(0xFFE55A2B)
              : const Color(0xFF333333),
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 3),
            Shadow(color: Colors.white, blurRadius: 3),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _FloatingLabel extends StatelessWidget {
  final OverlayLabel             label;
  final TranslationOverlayConfig config;
  const _FloatingLabel({required this.label, required this.config});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-40, -50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xF0FF6B35), Color(0xF0FF8C42)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x44FF6B35), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.translation.localizedName(config.language),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              label.translation.nameZh,
              style: const TextStyle(fontSize: 8, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
```

---

### 7.5 `lib/widgets/map/voice_translation_overlay.dart`

```dart
import 'package:flutter/material.dart';
import '../../models/poi_translation.dart';
import '../../services/voice/voice_translation_service.dart';

class VoiceTranslationOverlay extends StatefulWidget {
  final AppLanguage language;

  const VoiceTranslationOverlay({super.key, required this.language});

  @override
  State<VoiceTranslationOverlay> createState() =>
      _VoiceTranslationOverlayState();
}

class _VoiceTranslationOverlayState extends State<VoiceTranslationOverlay>
    with SingleTickerProviderStateMixin {

  final VoiceTranslationService _svc = VoiceTranslationService();
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  TranslationDirection     _direction    = TranslationDirection.foreignToChinese;
  VoiceTranslationResult?  _latestResult;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _svc.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _onMicDown() async {
    try {
      await _svc.startRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission required'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _onMicUp() async {
    if (_svc.state != VoiceServiceState.recording) return;
    final result = await _svc.stopAndTranslate(
      direction:       _direction,
      foreignLanguage: widget.language,
    );
    if (result != null && mounted) {
      setState(() => _latestResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state      = _svc.state;
    final bottomPad  = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right:  16,
      bottom: bottomPad + 90,
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize:        MainAxisSize.min,
        children: [
          // 翻译结果气泡
          if (_latestResult != null) ...[
            _ResultBubble(result: _latestResult!),
            const SizedBox(height: 8),
          ],

          // 方向切换
          _DirectionChip(
            direction: _direction,
            language:  widget.language,
            onTap: () => setState(() {
              _direction = _direction == TranslationDirection.foreignToChinese
                  ? TranslationDirection.chineseToForeign
                  : TranslationDirection.foreignToChinese;
              _latestResult = null;
            }),
          ),
          const SizedBox(height: 10),

          // 录音按钮
          _MicButton(
            state:     state,
            pulse:     _pulseAnim,
            onDown:    _onMicDown,
            onUp:      _onMicUp,
            onCancel:  _svc.cancelRecording,
            onStop:    _svc.stopPlaying,
          ),

          // 提示文字
          const SizedBox(height: 4),
          _HintText(state: state, direction: _direction),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _svc.removeListener(_onStateChange);
    super.dispose();
  }
}

// ─── 子组件 ───────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final VoiceServiceState state;
  final Animation<double> pulse;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  const _MicButton({
    required this.state,
    required this.pulse,
    required this.onDown,
    required this.onUp,
    required this.onCancel,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    // 播放中 → 点击停止
    if (state == VoiceServiceState.playing) {
      return GestureDetector(
        onTap: onStop,
        child: _circle(const Color(0xFF4CAF50), Icons.volume_up),
      );
    }

    // 处理中 → 禁用，显示loading
    if (state == VoiceServiceState.processing) {
      return _circle(Colors.orange, null, loading: true);
    }

    // 录音中 → 脉冲动画
    if (state == VoiceServiceState.recording) {
      return GestureDetector(
        onTapUp:    (_) => onUp(),
        onTapCancel: onCancel,
        child: AnimatedBuilder(
          animation: pulse,
          builder:  (_, child) => Transform.scale(
            scale: pulse.value,
            child: child,
          ),
          child: _circle(Colors.red, Icons.mic),
        ),
      );
    }

    // 待机 → 长按触发
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp:   (_) => onUp(),
      onTapCancel: onCancel,
      child: _circle(const Color(0xFFFF6B35), Icons.mic),
    );
  }

  Widget _circle(Color color, IconData? icon, {bool loading = false}) {
    return Container(
      width:  64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius:   12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: loading
          ? const Center(
              child: SizedBox(
                width:  28,
                height: 28,
                child:  CircularProgressIndicator(
                  color:       Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _ResultBubble extends StatelessWidget {
  final VoiceTranslationResult result;
  const _ResultBubble({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:        MainAxisSize.min,
        children: [
          Text(
            result.originalText,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const Divider(height: 8),
          Text(
            result.translatedText,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.processingTime.inMilliseconds}ms',
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final TranslationDirection direction;
  final AppLanguage          language;
  final VoidCallback         onTap;

  const _DirectionChip({
    required this.direction,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = switch (language) {
      AppLanguage.english  => 'EN',
      AppLanguage.french   => 'FR',
      AppLanguage.spanish  => 'ES',
    };
    final label = direction == TranslationDirection.foreignToChinese
        ? '$langCode → 中'
        : '中 → $langCode';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz, size: 14, color: Color(0xFFFF6B35)),
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final VoiceServiceState    state;
  final TranslationDirection direction;
  const _HintText({required this.state, required this.direction});

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      VoiceServiceState.idle       => 'Tap & hold to speak',
      VoiceServiceState.recording  => 'Listening...',
      VoiceServiceState.processing => 'Translating...',
      VoiceServiceState.playing    => 'Tap to stop',
      VoiceServiceState.error      => 'Error, try again',
    };
    return Text(
      text,
      style: const TextStyle(
        fontSize:  10,
        color:     Colors.white,
        shadows:   [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }
}
```

---

### 7.6 `lib/widgets/map/wander_map.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../../models/poi_translation.dart';
import '../../services/map/map_translation_service.dart';
import 'translation_overlay_widget.dart';
import 'voice_translation_overlay.dart';

class WanderMap extends StatefulWidget {
  final LatLng   initialCenter;
  final double   initialZoom;
  final AppLanguage language;
  final LabelStyle  labelStyle;
  final bool     showTranslationOverlay;
  final bool     showVoiceButton;
  final void Function(LatLng)?           onMapTap;
  final void Function(POITranslation)?   onPOITap;

  const WanderMap({
    super.key,
    required this.initialCenter,
    this.initialZoom             = 15.0,
    this.language                = AppLanguage.english,
    this.labelStyle              = LabelStyle.badge,
    this.showTranslationOverlay  = true,
    this.showVoiceButton         = true,
    this.onMapTap,
    this.onPOITap,
  });

  @override
  State<WanderMap> createState() => WanderMapState();
}

class WanderMapState extends State<WanderMap> {
  AMapController?              _mapController;
  final MapTranslationService  _translationSvc = MapTranslationService();

  double                      _currentZoom    = 15.0;
  List<Map<String, dynamic>>  _visiblePOIs    = [];
  final Set<Marker>            _customMarkers  = {};
  Timer?                       _debounceTimer;

  // ─── 公开接口 ─────────────────────────────────────────

  Future<void> moveTo(LatLng target, {double? zoom}) async {
    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom ?? _currentZoom),
      ),
      animated: true,
    );
  }

  void addSearchMarker(POITranslation poi) {
    setState(() {
      _customMarkers.add(Marker(
        markerId: MarkerId(poi.gaodePoiId),
        position: poi.coordinates,
        infoWindow: InfoWindow(
          title:   poi.localizedName(widget.language),
          snippet: poi.nameZh,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    });
  }

  void clearSearchMarkers() => setState(() => _customMarkers.clear());

  // ─── 地图事件 ─────────────────────────────────────────

  void _onMapCreated(AMapController ctrl) {
    _mapController = ctrl;
    _scheduleOverlayUpdate();
  }

  void _onCameraMove(CameraPosition pos) {
    _currentZoom = pos.zoom;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _scheduleOverlayUpdate);
  }

  Future<void> _scheduleOverlayUpdate() async {
    if (!widget.showTranslationOverlay || _mapController == null) return;
    if (_currentZoom < 13.5) {
      if (_visiblePOIs.isNotEmpty) setState(() => _visiblePOIs = []);
      return;
    }
    await _fetchVisiblePOIs();
  }

  Future<void> _fetchVisiblePOIs() async {
    try {
      final bounds = await _mapController!.getVisibleRegion();
      final centerLat = (bounds.northeast.latitude  + bounds.southwest.latitude)  / 2;
      final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
      final latDiff   = (bounds.northeast.latitude  - bounds.southwest.latitude).abs();
      final radius    = (latDiff * 111320 / 2).clamp(500, 3000).toInt();

      final searchResult = await AMapSearchAPI.searchPOIAround(
        AMapPOIAroundSearchRequest(
          location: LatLng(centerLat, centerLng),
          radius:   radius,
          keywords: '',
          types:    '风景名胜|旅游景点|博物馆|地铁站|火车站|机场|餐饮|购物',
          pageSize: 20,
          cityLimit: true,
        ),
      );

      if (searchResult?.pois != null && mounted) {
        final pois = searchResult!.pois!.map((p) => {
          'id':          p.uid ?? p.poiId ?? '',
          'name_zh':     p.name ?? '',
          'category_zh': p.type ?? '',
          'city':        _extractCity(p.cityName ?? ''),
          'lat':         p.latLonPoint?.latitude  ?? 0.0,
          'lng':         p.latLonPoint?.longitude ?? 0.0,
        }).where((p) => (p['id'] as String).isNotEmpty).toList();

        await _translationSvc.translateRawPOIs(rawPOIs: pois);
        if (mounted) setState(() => _visiblePOIs = pois);
      }
    } catch (e) {
      print('⚠️ 获取视窗POI失败: $e');
    }
  }

  String _extractCity(String cn) {
    for (final city in ['北京','上海','广州','深圳','成都','西安']) {
      if (cn.contains(city)) return city;
    }
    return '未知';
  }

  // ─── build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 高德底图
        AMapWidget(
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter,
            zoom:   widget.initialZoom,
          ),
          onMapCreated:          _onMapCreated,
          onCameraMove:          _onCameraMove,
          onTap:                 (ll) => widget.onMapTap?.call(ll),
          markers:               _customMarkers,
          rotateGesturesEnabled: false,
          compassEnabled:        true,
          myLocationStyleOptions: MyLocationStyleOptions(true),
        ),

        // 2. 翻译蒙层
        if (widget.showTranslationOverlay && _mapController != null)
          Positioned.fill(
            child: TranslationOverlay(
              mapController: _mapController!,
              visiblePOIs:   _visiblePOIs,
              currentZoom:   _currentZoom,
              config:        TranslationOverlayConfig(
                language:          widget.language,
                labelStyle:        widget.labelStyle,
                showCategory:      _currentZoom >= 15.5,
                minZoomToShow:     14.0,
                maxLabelsOnScreen: 12,
              ),
            ),
          ),

        // 3. 语音翻译按钮
        if (widget.showVoiceButton)
          VoiceTranslationOverlay(language: widget.language),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
```

---

## 8. main.dart 初始化

在现有的 `Future.wait` 中添加 `VoiceTranslationService`：

```dart
await Future.wait([
  LanguageManager().initialize(),
  AMapService().initialize(),
  POITranslationService().initialize(),
  MapTranslationService().initialize(),   // 新增
  VoiceTranslationService().initialize(), // 新增
  AITravelAssistantService().initialize(EnvConfig.deepseekApiKey),
], eagerError: false).catchError((e) {
  print('⚠️ 部分服务初始化失败: $e');
});
```

---

## 9. 使用示例

```dart
// 在任意页面中使用
WanderMap(
  initialCenter:           CityCoordinates.centers['北京']!,
  initialZoom:             15.0,
  language:                AppLanguage.english,
  labelStyle:              LabelStyle.badge,
  showTranslationOverlay:  true,
  showVoiceButton:         true,
  onMapTap: (latLng) => print('tapped: $latLng'),
)
```

---

## 10. 注意事项

**AMapSearchAPI 版本差异：** `searchPOIAround` 的参数名在不同版本的 `amap_flutter_map` 包里可能略有差异，以本地安装版本的文档为准。

**百度ASR语言代码：** `dev_pid` 1536=普通话（离线）, 1537=普通话（在线），外语暂只支持部分语种，以百度官网最新文档为准。

**TTS返回格式：** 百度TTS有时会把错误信息也返回200，需检查 `content-type` 是否为 `audio/*` 再写入文件。

**坐标系：** 高德使用 GCJ-02，数据库存储的所有坐标也应为 GCJ-02。
