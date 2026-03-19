import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translated_route.dart';
import '../services/route_planning_service.dart';
import '../core/constants/supported_cities.dart';

/// 地图翻译服务
///
/// 提供地图元素的中英文翻译功能，包括：
/// - 道路名称翻译
/// - 公交站点翻译
/// - 路线指令翻译
/// - 区域地名翻译
///
/// 仅支持6个主要城市：北京、上海、广州、深圳、成都、西安
class MapTranslationService {
  static final MapTranslationService _instance = MapTranslationService._internal();
  factory MapTranslationService() => _instance;
  MapTranslationService._internal();

  SharedPreferences? _prefs;

  /// 启用城市过滤（默认启用）
  bool enableCityFilter = true;

  /// 内存缓存
  final Map<String, String> _roadCache = {};
  final Map<String, String> _stationCache = {};
  final Map<String, String> _instructionCache = {};
  final Map<String, String> _areaCache = {};

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化服务（仅本地词典模式，MVP 不使用数据库）
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // 加载缓存
      await _loadCacheFromStorage();

      _isInitialized = true;
      debugPrint('✅ 地图翻译服务初始化成功（本地词典模式）');
    } catch (e) {
      debugPrint('❌ 地图翻译服务初始化失败: $e');
      _isInitialized = true; // 允许应用继续运行
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  // ============================================================================
  // 路线翻译
  // ============================================================================

  /// 翻译路线信息
  ///
  /// [route] 原始路线信息
  /// [city] 所在城市（可选，自动检测）
  Future<TranslatedRouteInfo> translateRoute(
    RouteInfo route, {
    String? city,
  }) async {
    try {
      // 检查城市
      if (enableCityFilter && city != null) {
        if (!SupportedCities.isCitySupported(city)) {
          debugPrint('⚠️ 城市不在支持范围内，跳过翻译: $city');
          return TranslatedRouteInfo.fromRouteInfo(route);
        }
      }

      // 翻译所有步骤
      final translatedSteps = <TranslatedRouteStep>[];

      for (var step in route.steps) {
        final translatedStep = await _translateRouteStep(step, city: city);
        translatedSteps.add(translatedStep);
      }

      // 创建翻译后的路线
      final translatedRoute = TranslatedRouteInfo.fromRouteInfo(route)
          .copyWithTranslatedSteps(translatedSteps);

      return translatedRoute;

    } catch (e) {
      debugPrint('❌ 路线翻译失败: $e');
      return TranslatedRouteInfo.fromRouteInfo(route);
    }
  }

  /// 翻译路线步骤
  Future<TranslatedRouteStep> _translateRouteStep(
    RouteStep step, {
    String? city,
  }) async {
    var translatedStep = TranslatedRouteStep.fromRouteStep(step);

    try {
      // 1. 翻译道路名称
      final roadEn = await translateRoad(step.road, city: city);

      // 2. 翻译指令
      final instructionEn = await translateInstruction(step.instruction);

      // 如果有翻译结果，更新步骤
      if (roadEn != null || instructionEn != null) {
        translatedStep = translatedStep.copyWithTranslation(
          roadEn: roadEn,
          instructionEn: instructionEn,
          translationSource: 'database',
        );
      }

    } catch (e) {
      debugPrint('⚠️ 路线步骤翻译失败: $e');
    }

    return translatedStep;
  }

  // ============================================================================
  // 道路翻译
  // ============================================================================

  /// 翻译道路名称
  ///
  /// [roadName] 道路名称（中文）
  /// [city] 所在城市（可选）
  Future<String?> translateRoad(String roadName, {String? city}) async {
    if (roadName.isEmpty) return null;

    try {
      // 1. 检查内存缓存
      final cacheKey = '${city ?? ''}:$roadName';
      if (_roadCache.containsKey(cacheKey)) {
        return _roadCache[cacheKey];
      }

      // 2. 从本地词典翻译
      final dictResult = _translateRoadFromDictionary(roadName);
      if (dictResult != null) {
        _roadCache[cacheKey] = dictResult;
        return dictResult;
      }

      // 3. 从数据库查询
      final dbResult = await _queryRoadFromDatabase(roadName, city);
      if (dbResult != null) {
        _roadCache[cacheKey] = dbResult;
        await _saveCacheToStorage('road', cacheKey, dbResult);
        return dbResult;
      }

      // 4. 如果都没有，返回null
      return null;

    } catch (e) {
      debugPrint('❌ 道路翻译失败: $e');
      return null;
    }
  }

  /// 从本地词典翻译道路
  String? _translateRoadFromDictionary(String roadName) {
    // 使用POI翻译层的通用词典
    for (var entry in _roadDictionary.entries) {
      if (roadName.contains(entry.key)) {
        return roadName.replaceAll(entry.key, entry.value);
      }
    }
    return null;
  }

  /// MVP: 数据库查询已禁用，仅使用本地词典
  Future<String?> _queryRoadFromDatabase(String roadName, String? city) async {
    return null; // MVP 不使用数据库
  }

  // ============================================================================
  // 公交站点翻译
  // ============================================================================

  /// 翻译公交站点名称
  ///
  /// [stationName] 站点名称（中文）
  /// [city] 所在城市（必需）
  /// [stationType] 站点类型（bus/metro/train）
  Future<String?> translateStation(
    String stationName, {
    required String city,
    String stationType = 'metro',
  }) async {
    if (stationName.isEmpty) return null;

    try {
      // 1. 检查内存缓存
      final cacheKey = '$city:$stationType:$stationName';
      if (_stationCache.containsKey(cacheKey)) {
        return _stationCache[cacheKey];
      }

      // 2. 从本地词典翻译
      final dictResult = _translateStationFromDictionary(stationName);
      if (dictResult != null) {
        _stationCache[cacheKey] = dictResult;
        return dictResult;
      }

      // 3. 从数据库查询
      final dbResult = await _queryStationFromDatabase(
        stationName,
        city,
        stationType,
      );

      if (dbResult != null) {
        _stationCache[cacheKey] = dbResult;
        await _saveCacheToStorage('station', cacheKey, dbResult);
        return dbResult;
      }

      return null;

    } catch (e) {
      debugPrint('❌ 站点翻译失败: $e');
      return null;
    }
  }

  /// 从本地词典翻译站点
  String? _translateStationFromDictionary(String stationName) {
    // 移除常见后缀
    var cleanName = stationName
        .replaceAll('地铁站', '')
        .replaceAll('站', '')
        .trim();

    // 查找词典
    for (var entry in _stationDictionary.entries) {
      if (cleanName == entry.key || stationName == entry.key) {
        return entry.value;
      }
    }

    return null;
  }

  /// MVP: 数据库查询已禁用，仅使用本地词典
  Future<String?> _queryStationFromDatabase(
    String stationName,
    String city,
    String stationType,
  ) async {
    return null; // MVP 不使用数据库
  }

  // ============================================================================
  // 指令翻译
  // ============================================================================

  /// 翻译路线指令
  ///
  /// [instruction] 指令文本（中文）
  Future<String?> translateInstruction(String instruction) async {
    if (instruction.isEmpty) return null;

    try {
      // 1. 检查内存缓存
      if (_instructionCache.containsKey(instruction)) {
        return _instructionCache[instruction];
      }

      // 2. 从本地词典翻译
      final dictResult = _translateInstructionFromDictionary(instruction);
      if (dictResult != null) {
        _instructionCache[instruction] = dictResult;
        return dictResult;
      }

      // 3. 从数据库查询
      final dbResult = await _queryInstructionFromDatabase(instruction);
      if (dbResult != null) {
        _instructionCache[instruction] = dbResult;
        await _saveCacheToStorage('instruction', instruction, dbResult);
        return dbResult;
      }

      return null;

    } catch (e) {
      debugPrint('❌ 指令翻译失败: $e');
      return null;
    }
  }

  /// 从本地词典翻译指令
  String? _translateInstructionFromDictionary(String instruction) {
    var result = instruction;
    var hasTranslation = false;

    // 替换所有匹配的短语
    for (var entry in _instructionDictionary.entries) {
      if (result.contains(entry.key)) {
        result = result.replaceAll(entry.key, entry.value);
        hasTranslation = true;
      }
    }

    return hasTranslation ? result : null;
  }

  /// MVP: 数据库查询已禁用，仅使用本地词典
  Future<String?> _queryInstructionFromDatabase(String instruction) async {
    return null; // MVP 不使用数据库
  }

  // ============================================================================
  // 区域翻译
  // ============================================================================

  /// 翻译区域名称（MVP: 仅缓存，不使用数据库）
  ///
  /// [areaName] 区域名称（中文）
  /// [city] 所在城市
  Future<String?> translateArea(String areaName, {required String city}) async {
    if (areaName.isEmpty) return null;

    try {
      // 检查内存缓存
      final cacheKey = '$city:$areaName';
      if (_areaCache.containsKey(cacheKey)) {
        return _areaCache[cacheKey];
      }

      return null; // MVP 不使用数据库

    } catch (e) {
      debugPrint('❌ 区域翻译失败: $e');
      return null;
    }
  }

  // ============================================================================
  // 缓存管理
  // ============================================================================

  /// 从存储加载缓存
  Future<void> _loadCacheFromStorage() async {
    if (_prefs == null) return;

    try {
      final keys = _prefs!.getKeys();

      for (var key in keys) {
        if (key.startsWith('map_trans_')) {
          final value = _prefs!.getString(key);
          if (value != null) {
            final parts = key.substring('map_trans_'.length).split(':');
            if (parts.length >= 2) {
              final type = parts[0];
              final cacheKey = parts.sublist(1).join(':');

              switch (type) {
                case 'road':
                  _roadCache[cacheKey] = value;
                  break;
                case 'station':
                  _stationCache[cacheKey] = value;
                  break;
                case 'instruction':
                  _instructionCache[cacheKey] = value;
                  break;
                case 'area':
                  _areaCache[cacheKey] = value;
                  break;
              }
            }
          }
        }
      }

      final totalCached = _roadCache.length + _stationCache.length +
          _instructionCache.length + _areaCache.length;
      debugPrint('✅ 加载了 $totalCached 条地图翻译缓存');

    } catch (e) {
      debugPrint('⚠️ 加载缓存失败: $e');
    }
  }

  /// 保存缓存到存储
  Future<void> _saveCacheToStorage(
    String type,
    String key,
    String value,
  ) async {
    if (_prefs == null) return;

    try {
      await _prefs!.setString('map_trans_$type:$key', value);
    } catch (e) {
      debugPrint('⚠️ 保存缓存失败: $e');
    }
  }

  /// 清空所有缓存
  Future<void> clearCache() async {
    _roadCache.clear();
    _stationCache.clear();
    _instructionCache.clear();
    _areaCache.clear();

    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (var key in keys) {
        if (key.startsWith('map_trans_')) {
          await _prefs!.remove(key);
        }
      }
    }

    debugPrint('✅ 地图翻译缓存已清空');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'roadCache': _roadCache.length,
      'stationCache': _stationCache.length,
      'instructionCache': _instructionCache.length,
      'areaCache': _areaCache.length,
      'totalCached': _roadCache.length + _stationCache.length +
          _instructionCache.length + _areaCache.length,
    };
  }

  // ============================================================================
  // 本地翻译词典
  // ============================================================================

  /// 道路翻译词典
  static const Map<String, String> _roadDictionary = {
    // 方位
    '东': 'East',
    '南': 'South',
    '西': 'West',
    '北': 'North',
    '中': 'Central',
    '内': 'Inner',
    '外': 'Outer',
    '新': 'New',
    '老': 'Old',

    // 道路类型
    '路': 'Road',
    '街': 'Street',
    '大道': 'Avenue',
    '大街': 'Avenue',
    '巷': 'Alley',
    '胡同': 'Hutong',
    '里': 'Lane',
    '弄': 'Lane',

    // 常见词汇
    '高速': 'Expressway',
    '环路': 'Ring Road',
    '立交桥': 'Overpass',
    '桥': 'Bridge',
    '隧道': 'Tunnel',
  };

  /// 站点翻译词典
  static const Map<String, String> _stationDictionary = {
    // 北京
    '天安门': 'Tiananmen',
    '王府井': 'Wangfujing',
    '三里屯': 'Sanlitun',
    '国贸': 'Guomao',
    '中关村': 'Zhongguancun',

    // 上海
    '人民广场': 'People\'s Square',
    '静安寺': 'Jing\'an Temple',
    '徐家汇': 'Xujiahui',
    '陆家嘴': 'Lujiazui',

    // 通用
    '火车站': 'Railway Station',
    '机场': 'Airport',
    '体育中心': 'Sports Center',
    '大学': 'University',
    '医院': 'Hospital',
  };

  /// 指令翻译词典
  static const Map<String, String> _instructionDictionary = {
    // 方向指令
    '直行': 'Go straight',
    '左转': 'Turn left',
    '右转': 'Turn right',
    '掉头': 'Make a U-turn',
    '继续前进': 'Continue',

    // 动作指令
    '从起点出发': 'Start from origin',
    '到达终点': 'Arrive at destination',
    '进入': 'Enter',
    '驶入': 'Enter',
    '驶出': 'Exit',
    '上': 'Get on',
    '下': 'Get off',

    // 距离
    '米': 'm',
    '公里': 'km',
    '千米': 'km',

    // 时间
    '分钟': 'min',
    '小时': 'h',
    '秒': 's',
  };
}
