import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../models/translated_route.dart';
import 'api_client.dart';

/// 路线规划类型
enum RouteType {
  driving('驾车', 'driving'),
  walking('步行', 'walking'),
  transit('公交', 'transit'),
  riding('骑行', 'riding');

  final String label;
  final String value;

  const RouteType(this.label, this.value);
}

/// 路线规划策略
enum RoutePlanStrategy {
  fastest('速度优先', 0),
  cheapest('费用优先', 1),
  shortest('距离优先', 2),
  noHighway('不走高速', 3),
  avoidCongestion('躲避拥堵', 4);

  final String label;
  final int value;

  const RoutePlanStrategy(this.label, this.value);
}

/// 路线步骤
class RouteStep {
  final String instruction; // 指令描述
  final String road; // 道路名称
  final double distance; // 距离（米）
  final int duration; // 时长（秒）
  final LatLng startLocation;
  final LatLng endLocation;

  RouteStep({
    required this.instruction,
    required this.road,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });

  /// 格式化距离
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}米';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}公里';
    }
  }

  /// 格式化时长
  String get formattedDuration {
    if (duration < 60) {
      return '$duration秒';
    } else if (duration < 3600) {
      return '${(duration / 60).toStringAsFixed(0)}分钟';
    } else {
      final hours = (duration / 3600).floor();
      final minutes = ((duration % 3600) / 60).floor();
      return '$hours小时$minutes分钟';
    }
  }
}

/// 路线信息
class RouteInfo {
  final String routeId;
  final RouteType routeType;
  final double totalDistance; // 总距离（米）
  final int totalDuration; // 总时长（秒）
  final List<RouteStep> steps; // 路线步骤
  final List<LatLng> polyline; // 路线坐标点
  final double? taxiFee; // 打车费用（可选）
  final double? transitFee; // 公交费用（可选）

  RouteInfo({
    required this.routeId,
    required this.routeType,
    required this.totalDistance,
    required this.totalDuration,
    required this.steps,
    required this.polyline,
    this.taxiFee,
    this.transitFee,
  });

  /// 格式化总距离
  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)}米';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(1)}公里';
    }
  }

  /// 格式化总时长
  String get formattedDuration {
    if (totalDuration < 60) {
      return '$totalDuration秒';
    } else if (totalDuration < 3600) {
      return '${(totalDuration / 60).toStringAsFixed(0)}分钟';
    } else {
      final hours = (totalDuration / 3600).floor();
      final minutes = ((totalDuration % 3600) / 60).floor();
      return '$hours小时$minutes分钟';
    }
  }
}

/// 路线规划服务
///
/// 通过云函数调用高德地图路线规划 API，提供多种出行方式的路线规划功能
class RoutePlanningService {
  static final RoutePlanningService _instance = RoutePlanningService._internal();
  factory RoutePlanningService() => _instance;
  RoutePlanningService._internal();

  /// 规划路线（调用云函数）
  ///
  /// [origin] 起点坐标
  /// [destination] 终点坐标
  /// [routeType] 路线类型
  /// [strategy] 规划策略
  /// [multiRoute] 是否返回多条路线（默认true，最多3条）
  Future<List<RouteInfo>> planRoute({
    required LatLng origin,
    required LatLng destination,
    required RouteType routeType,
    RoutePlanStrategy strategy = RoutePlanStrategy.fastest,
    bool multiRoute = true,
  }) async {
    try {
      // 调用云函数进行路线规划
      final result = await ApiClient.post(ApiClient.routeUrl, {
        'origin': '${origin.longitude},${origin.latitude}',
        'destination': '${destination.longitude},${destination.latitude}',
        'route_type': routeType.value,
        'strategy': strategy.value,
        'multi_route': multiRoute,
      });

      final routes = <RouteInfo>[];
      final routesData = result['routes'] as List;

      for (final routeData in routesData) {
        final steps = <RouteStep>[];
        final stepsData = routeData['steps'] as List;

        for (final stepData in stepsData) {
          steps.add(RouteStep(
            instruction: stepData['instruction'] as String,
            road: stepData['road'] as String,
            distance: (stepData['distance'] as num).toDouble(),
            duration: stepData['duration'] as int,
            startLocation: LatLng(
              (stepData['start_location']['lat'] as num).toDouble(),
              (stepData['start_location']['lng'] as num).toDouble(),
            ),
            endLocation: LatLng(
              (stepData['end_location']['lat'] as num).toDouble(),
              (stepData['end_location']['lng'] as num).toDouble(),
            ),
          ));
        }

        // 解析路线坐标点
        final polyline = <LatLng>[];
        final polylineData = routeData['polyline'] as List;
        for (final point in polylineData) {
          polyline.add(LatLng(
            (point['lat'] as num).toDouble(),
            (point['lng'] as num).toDouble(),
          ));
        }

        routes.add(RouteInfo(
          routeId: routeData['route_id'] as String,
          routeType: routeType,
          totalDistance: (routeData['total_distance'] as num).toDouble(),
          totalDuration: routeData['total_duration'] as int,
          steps: steps,
          polyline: polyline,
          taxiFee: routeData['taxi_fee'] != null
              ? (routeData['taxi_fee'] as num).toDouble()
              : null,
          transitFee: routeData['transit_fee'] != null
              ? (routeData['transit_fee'] as num).toDouble()
              : null,
        ));
      }

      return routes;

    } catch (e) {
      print('❌ 路线规划失败: $e');
      return [];
    }
  }

  /// 计算两点之间的直线距离（米）
  double calculateStraightDistance(LatLng point1, LatLng point2) {
    const R = 6371000; // 地球半径（米）
    final lat1 = point1.latitude * 3.141592653589793 / 180;
    final lat2 = point2.latitude * 3.141592653589793 / 180;
    final dLat = lat2 - lat1;
    final dLng = (point2.longitude - point1.longitude) * 3.141592653589793 / 180;

    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        lat1.abs() * lat2.abs() *
        (dLng / 2).abs() * (dLng / 2).abs();

    final c = 2 * (a / (1 + a));

    return R * c;
  }


  /// 搜索沿途兴趣点（调用云函数）
  ///
  /// [route] 路线信息
  /// [poiType] POI类型（如：加油站、餐厅等）
  /// [searchRadius] 搜索半径（米）
  Future<List<dynamic>> searchPOIAlongRoute({
    required RouteInfo route,
    required String poiType,
    int searchRadius = 500,
  }) async {
    try {
      final result = await ApiClient.post(ApiClient.searchUrl, {
        'action': 'search_along_route',
        'polyline': route.polyline.map((p) => {
          'lat': p.latitude,
          'lng': p.longitude,
        }).toList(),
        'poi_type': poiType,
        'radius': searchRadius,
      });

      return result['pois'] as List;
    } catch (e) {
      print('❌ 沿途POI搜索失败: $e');
      return [];
    }
  }

  // ============================================================================
  // 翻译功能集成（通过云函数）
  // ============================================================================

  /// 规划路线并自动翻译
  ///
  /// [origin] 起点坐标
  /// [destination] 终点坐标
  /// [routeType] 路线类型
  /// [strategy] 规划策略
  /// [targetLang] 目标语言（en/fr/es）
  /// [multiRoute] 是否返回多条路线
  Future<List<TranslatedRouteInfo>> planRouteWithTranslation({
    required LatLng origin,
    required LatLng destination,
    required RouteType routeType,
    RoutePlanStrategy strategy = RoutePlanStrategy.fastest,
    String targetLang = 'en',
    bool multiRoute = true,
  }) async {
    try {
      // 调用云函数进行路线规划并翻译
      final result = await ApiClient.post(ApiClient.routeUrl, {
        'origin': '${origin.longitude},${origin.latitude}',
        'destination': '${destination.longitude},${destination.latitude}',
        'route_type': routeType.value,
        'strategy': strategy.value,
        'multi_route': multiRoute,
        'translate': true,
        'target_lang': targetLang,
      });

      final routes = <TranslatedRouteInfo>[];
      final routesData = result['routes'] as List;

      for (final routeData in routesData) {
        // 解析翻译后的路线数据（云函数已完成翻译）
        routes.add(TranslatedRouteInfo.fromJson(routeData));
      }

      return routes;

    } catch (e) {
      print('❌ 路线规划和翻译失败: $e');
      return [];
    }
  }

  /// 仅翻译现有路线（调用云函数）
  ///
  /// [route] 原始路线
  /// [targetLang] 目标语言
  Future<TranslatedRouteInfo> translateRoute(
    RouteInfo route, {
    String targetLang = 'en',
  }) async {
    try {
      final result = await ApiClient.post(ApiClient.translateUrl, {
        'route_data': {
          'route_id': route.routeId,
          'steps': route.steps.map((s) => {
            'instruction': s.instruction,
            'road': s.road,
          }).toList(),
        },
        'target_lang': targetLang,
        'context': 'route_navigation',
      });

      return TranslatedRouteInfo.fromJson(result['translated_route']);
    } catch (e) {
      print('❌ 路线翻译失败: $e');
      return TranslatedRouteInfo.fromRouteInfo(route);
    }
  }
}
