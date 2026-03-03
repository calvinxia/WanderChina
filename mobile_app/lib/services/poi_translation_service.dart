import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poi.dart';
import '../models/translated_poi.dart';
import '../core/constants/supported_cities.dart';

/// POI翻译服务
///
/// 提供POI中文到英文的翻译功能，支持：
/// - 本地词典翻译（快速）
/// - 缓存翻译结果
/// - 在线翻译API（百度/Google）
/// - 批量翻译
/// 仅支持6个主要城市：北京、上海、广州、深圳、成都、西安
class POITranslationService {
  static final POITranslationService _instance = POITranslationService._internal();
  factory POITranslationService() => _instance;
  POITranslationService._internal();

  final Dio _dio = Dio();
  SharedPreferences? _prefs;

  /// 启用城市过滤（默认启用）
  bool enableCityFilter = true;

  // 翻译缓存（内存）
  final Map<String, String> _translationCache = {};

  // 百度翻译API配置（可选）
  static const String _baiduTranslateUrl = 'https://fanyi-api.baidu.com/api/trans/vip/translate';
  String? _baiduAppId;
  String? _baiduSecretKey;

  /// 初始化服务
  Future<void> initialize({
    String? baiduAppId,
    String? baiduSecretKey,
  }) async {
    _baiduAppId = baiduAppId;
    _baiduSecretKey = baiduSecretKey;

    // 加载缓存
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheFromStorage();
  }

  /// 翻译POI
  ///
  /// 使用多层翻译策略：
  /// 1. 本地词典（最快）
  /// 2. 缓存（次快）
  /// 3. 在线API（最准确但慢）
  Future<TranslatedPOI> translatePOI(POI poi) async {
    try {
      // 检查POI是否在支持的城市内
      if (enableCityFilter) {
        final city = SupportedCities.getCityFromCoordinates(poi.latitude, poi.longitude);
        if (city == null) {
          print('⚠️ POI不在支持的城市内，跳过翻译: ${poi.name}');
          return TranslatedPOI.fromPOI(poi);
        }
      }

      // 1. 尝试从本地词典翻译
      final dictTranslation = _translateFromDictionary(poi);
      if (dictTranslation != null) {
        return dictTranslation;
      }

      // 2. 尝试从缓存获取
      final cachedTranslation = await _getFromCache(poi);
      if (cachedTranslation != null) {
        return cachedTranslation;
      }

      // 3. 使用在线API翻译
      if (_baiduAppId != null && _baiduSecretKey != null) {
        final apiTranslation = await _translateWithAPI(poi);
        if (apiTranslation != null) {
          await _saveToCache(poi.id, apiTranslation);
          return apiTranslation;
        }
      }

      // 4. 如果都失败，返回未翻译的POI
      return TranslatedPOI.fromPOI(poi);

    } catch (e) {
      print('❌ POI翻译失败: $e');
      return TranslatedPOI.fromPOI(poi);
    }
  }

  /// 批量翻译POI
  Future<List<TranslatedPOI>> translatePOIs(List<POI> pois) async {
    final results = <TranslatedPOI>[];

    for (var poi in pois) {
      final translated = await translatePOI(poi);
      results.add(translated);
    }

    return results;
  }

  /// 从本地词典翻译
  TranslatedPOI? _translateFromDictionary(POI poi) {
    // 尝试翻译名称
    final nameEn = CommonPlaceTranslations.tryTranslate(poi.name);

    // 尝试翻译地址
    String? addressEn;
    if (poi.address.isNotEmpty) {
      addressEn = _translateAddress(poi.address);
    }

    // 尝试翻译标签
    List<String>? tagsEn;
    if (poi.tags != null && poi.tags!.isNotEmpty) {
      tagsEn = poi.tags!.map((tag) =>
        CommonPlaceTranslations.tryTranslate(tag) ?? tag
      ).toList();
    }

    // 如果名称被翻译了，认为是成功的
    if (nameEn != null) {
      return TranslatedPOI.fromPOI(poi).copyWithTranslation(
        nameEn: nameEn,
        addressEn: addressEn,
        tagsEn: tagsEn,
        translationConfidence: 0.9, // 词典翻译置信度高
        translationSource: 'dictionary',
      );
    }

    return null;
  }

  /// 翻译地址
  String _translateAddress(String address) {
    var result = address;

    // 翻译常见地址组成部分
    CommonPlaceTranslations.translations.forEach((chinese, english) {
      result = result.replaceAll(chinese, english);
    });

    return result;
  }

  /// 从缓存获取翻译
  Future<TranslatedPOI?> _getFromCache(POI poi) async {
    // 检查内存缓存
    final cacheKey = 'trans_${poi.id}';

    if (_translationCache.containsKey(cacheKey)) {
      return _deserializeTranslatedPOI(_translationCache[cacheKey]!, poi);
    }

    // 检查持久化缓存
    if (_prefs != null) {
      final cached = _prefs!.getString(cacheKey);
      if (cached != null) {
        _translationCache[cacheKey] = cached; // 加载到内存
        return _deserializeTranslatedPOI(cached, poi);
      }
    }

    return null;
  }

  /// 保存到缓存
  Future<void> _saveToCache(String poiId, TranslatedPOI translation) async {
    final cacheKey = 'trans_$poiId';
    final serialized = _serializeTranslatedPOI(translation);

    // 保存到内存
    _translationCache[cacheKey] = serialized;

    // 保存到持久化存储
    if (_prefs != null) {
      await _prefs!.setString(cacheKey, serialized);
    }
  }

  /// 使用百度翻译API
  Future<TranslatedPOI?> _translateWithAPI(POI poi) async {
    if (_baiduAppId == null || _baiduSecretKey == null) {
      return null;
    }

    try {
      // 翻译名称
      final nameEn = await _translateText(poi.name);

      // 翻译地址（可选，为节省API调用可跳过）
      String? addressEn;
      if (poi.address.length < 100) { // 只翻译短地址
        addressEn = await _translateText(poi.address);
      }

      // 翻译描述
      String? descriptionEn;
      if (poi.description != null && poi.description!.length < 200) {
        descriptionEn = await _translateText(poi.description!);
      }

      return TranslatedPOI.fromPOI(poi).copyWithTranslation(
        nameEn: nameEn,
        addressEn: addressEn,
        descriptionEn: descriptionEn,
        translationConfidence: 0.85, // API翻译置信度
        translationSource: 'baidu_api',
      );

    } catch (e) {
      print('❌ 百度翻译API调用失败: $e');
      return null;
    }
  }

  /// 调用百度翻译API翻译单个文本
  Future<String?> _translateText(String text) async {
    if (text.isEmpty) return null;

    try {
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final sign = _generateBaiduSign(text, salt);

      final response = await _dio.get(
        _baiduTranslateUrl,
        queryParameters: {
          'q': text,
          'from': 'zh',
          'to': 'en',
          'appid': _baiduAppId,
          'salt': salt,
          'sign': sign,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['trans_result'] != null && data['trans_result'].isNotEmpty) {
          return data['trans_result'][0]['dst'];
        }
      }

      return null;

    } catch (e) {
      print('❌ 翻译文本失败: $e');
      return null;
    }
  }

  /// 生成百度翻译签名
  String _generateBaiduSign(String query, String salt) {
    // MD5(appid+q+salt+密钥)
    final str = '$_baiduAppId$query$salt$_baiduSecretKey';
    // 这里需要实际的MD5实现，简化示例
    return str.hashCode.toRadixString(16);
  }

  /// 序列化TranslatedPOI
  String _serializeTranslatedPOI(TranslatedPOI poi) {
    return jsonEncode({
      'nameEn': poi.nameEn,
      'addressEn': poi.addressEn,
      'descriptionEn': poi.descriptionEn,
      'tagsEn': poi.tagsEn,
      'confidence': poi.translationConfidence,
      'source': poi.translationSource,
    });
  }

  /// 反序列化TranslatedPOI
  TranslatedPOI _deserializeTranslatedPOI(String cached, POI poi) {
    final data = jsonDecode(cached);
    return TranslatedPOI.fromPOI(poi).copyWithTranslation(
      nameEn: data['nameEn'],
      addressEn: data['addressEn'],
      descriptionEn: data['descriptionEn'],
      tagsEn: data['tagsEn'] != null ? List<String>.from(data['tagsEn']) : null,
      translationConfidence: data['confidence']?.toDouble(),
      translationSource: data['source'],
    );
  }

  /// 从存储加载缓存
  Future<void> _loadCacheFromStorage() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    for (var key in keys) {
      if (key.startsWith('trans_')) {
        final value = _prefs!.getString(key);
        if (value != null) {
          _translationCache[key] = value;
        }
      }
    }

    print('✅ 加载了 ${_translationCache.length} 条翻译缓存');
  }

  /// 清空缓存
  Future<void> clearCache() async {
    _translationCache.clear();

    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (var key in keys) {
        if (key.startsWith('trans_')) {
          await _prefs!.remove(key);
        }
      }
    }

    print('✅ 翻译缓存已清空');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCached': _translationCache.length,
      'memorySize': _translationCache.length * 100, // 粗略估计（字节）
    };
  }

  /// 预翻译常用POI
  Future<void> preTranslateCommonPOIs() async {
    // 可以预先翻译一些常用地点
    final commonPlaces = [
      '故宫博物院',
      '天安门广场',
      '长城',
      '颐和园',
      '天坛',
      // ... 更多常用地点
    ];

    for (var place in commonPlaces) {
      // 创建虚拟POI并翻译
      final dummyPOI = POI(
        id: place,
        name: place,
        address: '',
        latitude: 0,
        longitude: 0,
        category: POICategory.attraction,
      );

      await translatePOI(dummyPOI);
    }

    print('✅ 预翻译完成: ${commonPlaces.length} 个常用地点');
  }
}
