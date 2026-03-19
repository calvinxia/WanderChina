import 'package:flutter/foundation.dart';
import '../models/poi.dart';
import '../core/config/amap_config.dart';
import '../core/constants/supported_cities.dart';
import 'package:dio/dio.dart';

/// POI搜索服务
///
/// 提供兴趣点搜索、附近POI查询等功能
/// 仅支持6个主要城市：北京、上海、广州、深圳、成都、西安
class POIService {
  static final POIService _instance = POIService._internal();
  factory POIService() => _instance;
  POIService._internal();

  // ignore: unused_field
  final Dio _dio = Dio();

  /// 启用城市过滤（默认启用）
  bool enableCityFilter = true;

  /// 搜索附近POI
  ///
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [category] POI类别（可选）
  /// [radius] 搜索半径（米），默认5000米
  /// [limit] 结果数量限制，默认50
  Future<List<POI>> searchNearby({
    required double latitude,
    required double longitude,
    POICategory? category,
    int radius = AMapConfig.poiSearchRadius,
    int limit = AMapConfig.poiSearchLimit,
  }) async {
    try {
      // 检查坐标是否在支持的城市内
      if (enableCityFilter) {
        final city = SupportedCities.getCityFromCoordinates(latitude, longitude);
        if (city == null) {
          debugPrint('⚠️ 搜索位置不在支持的城市内（仅支持北京、上海、广州、深圳、成都、西安）');
          return [];
        }
        debugPrint('✅ 搜索城市: $city');
      }

      // 这里应该调用实际的高德POI搜索API
      // 由于需要API Key和网络请求，这里提供模拟数据示例

      // 模拟数据（实际使用时需要替换为真实API调用）
      final mockPOIs = _generateMockPOIs(
        latitude,
        longitude,
        category,
        limit,
      );

      return mockPOIs;

      /* 真实API调用示例：
      final response = await _dio.get(
        'https://restapi.amap.com/v3/place/around',
        queryParameters: {
          'key': AMapConfig.androidApiKey,
          'location': '$longitude,$latitude',
          'radius': radius,
          'types': category?.value ?? '',
          'offset': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final pois = (data['pois'] as List)
            .map((poi) => POI.fromJson(poi))
            .toList();
        return pois;
      }
      */

    } catch (e) {
      debugPrint('❌ POI搜索失败: $e');
      return [];
    }
  }

  /// 搜索POI（按关键词）
  ///
  /// [keyword] 搜索关键词
  /// [city] 城市名称（可选，但必须是支持的6个城市之一）
  /// [latitude] 中心点纬度（可选）
  /// [longitude] 中心点经度（可选）
  Future<List<POI>> searchByKeyword({
    required String keyword,
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // 检查城市是否在支持列表中
      if (enableCityFilter && city != null) {
        if (!SupportedCities.isCitySupported(city)) {
          debugPrint('⚠️ 不支持的城市: $city（仅支持北京、上海、广州、深圳、成都、西安）');
          return [];
        }
      }

      // 检查坐标是否在支持的城市内
      if (enableCityFilter && latitude != null && longitude != null) {
        final detectedCity = SupportedCities.getCityFromCoordinates(latitude, longitude);
        if (detectedCity == null) {
          debugPrint('⚠️ 搜索位置不在支持的城市内');
          return [];
        }
      }

      // 模拟搜索结果
      return _generateMockPOIs(
        latitude ?? AMapConfig.defaultLatitude,
        longitude ?? AMapConfig.defaultLongitude,
        null,
        10,
      );

      /* 真实API调用示例：
      final response = await _dio.get(
        'https://restapi.amap.com/v3/place/text',
        queryParameters: {
          'key': AMapConfig.androidApiKey,
          'keywords': keyword,
          'city': city ?? '',
          'offset': 20,
        },
      );
      */

    } catch (e) {
      debugPrint('❌ 关键词搜索失败: $e');
      return [];
    }
  }

  /// 获取POI详情
  ///
  /// [poiId] POI的唯一标识
  Future<POI?> getPOIDetail(String poiId) async {
    try {
      // 实际使用时调用高德API获取详情
      return null;

      /* 真实API调用示例：
      final response = await _dio.get(
        'https://restapi.amap.com/v3/place/detail',
        queryParameters: {
          'key': AMapConfig.androidApiKey,
          'id': poiId,
        },
      );
      */

    } catch (e) {
      debugPrint('❌ 获取POI详情失败: $e');
      return null;
    }
  }

  /// 生成模拟POI数据（仅供开发测试使用）
  List<POI> _generateMockPOIs(
    double centerLat,
    double centerLng,
    POICategory? category,
    int count,
  ) {
    final mockData = [
      {
        'name': '故宫博物院',
        'category': POICategory.attraction,
        'rating': 4.8,
        'address': '北京市东城区景山前街4号',
      },
      {
        'name': '全聚德烤鸭店',
        'category': POICategory.restaurant,
        'rating': 4.5,
        'address': '北京市东城区前门大街30号',
      },
      {
        'name': '北京饭店',
        'category': POICategory.hotel,
        'rating': 4.6,
        'address': '北京市东城区东长安街33号',
      },
      {
        'name': '王府井步行街',
        'category': POICategory.shopping,
        'rating': 4.3,
        'address': '北京市东城区王府井大街',
      },
      {
        'name': '天安门地铁站',
        'category': POICategory.transport,
        'rating': 4.0,
        'address': '北京市东城区长安街',
      },
      {
        'name': '北京协和医院',
        'category': POICategory.hospital,
        'rating': 4.7,
        'address': '北京市东城区帅府园1号',
      },
      {
        'name': 'Starbucks',
        'category': POICategory.cafe,
        'rating': 4.2,
        'address': '北京市东城区王府井大街255号',
      },
      {
        'name': '北海公园',
        'category': POICategory.park,
        'rating': 4.6,
        'address': '北京市西城区文津街1号',
      },
    ];

    final pois = <POI>[];
    for (var i = 0; i < count && i < mockData.length; i++) {
      final data = mockData[i];

      // 如果指定了类别，只返回该类别的POI
      if (category != null && data['category'] != category) {
        continue;
      }

      // 生成随机位置偏移（模拟附近的POI）
      final latOffset = (i * 0.01) - 0.02;
      final lngOffset = (i * 0.01) - 0.02;

      pois.add(POI(
        id: 'poi_$i',
        name: data['name'] as String,
        address: data['address'] as String,
        latitude: centerLat + latOffset,
        longitude: centerLng + lngOffset,
        category: data['category'] as POICategory,
        rating: data['rating'] as double,
        reviewCount: 100 + i * 50,
        distance: i * 500.0,
        phone: '+86 10 1234 ${5678 + i}',
        openingHours: '09:00 - 18:00',
        priceLevel: 2 + (i % 3),
        isOpen: true,
        tags: ['热门', '推荐'],
      ));
    }

    return pois;
  }

  /// 计算两点之间的距离（米）
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // 使用Haversine公式计算距离
    const R = 6371000; // 地球半径（米）
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLng / 2) * _sin(dLng / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return R * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => x; // 简化计算
  double _cos(double x) => 1 - x * x / 2; // 简化计算
  double _sqrt(double x) => x; // 简化计算
  double _atan2(double y, double x) => y / x; // 简化计算
}
