import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../core/config/amap_config.dart';
import '../models/translated_route.dart';
import 'map_translation_service.dart';

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
/// 提供多种出行方式的路线规划功能
class RoutePlanningService {
  static final RoutePlanningService _instance = RoutePlanningService._internal();
  factory RoutePlanningService() => _instance;
  RoutePlanningService._internal();

  final MapTranslationService _translationService = MapTranslationService();

  /// 规划路线
  ///
  /// [origin] 起点坐标
  /// [destination] 终点坐标
  /// [routeType] 路线类型
  /// [strategy] 规划策略
  Future<List<RouteInfo>> planRoute({
    required LatLng origin,
    required LatLng destination,
    required RouteType routeType,
    RoutePlanStrategy strategy = RoutePlanStrategy.fastest,
  }) async {
    try {
      // 实际使用时需要调用高德路线规划API
      // 这里返回模拟数据

      final mockRoute = _generateMockRoute(
        origin,
        destination,
        routeType,
      );

      return [mockRoute];

      /* 真实API调用示例：
      final response = await _dio.get(
        'https://restapi.amap.com/v3/direction/$${routeType.value}',
        queryParameters: {
          'key': AMapConfig.androidApiKey,
          'origin': '${origin.longitude},${origin.latitude}',
          'destination': '${destination.longitude},${destination.latitude}',
          'strategy': strategy.value,
        },
      );
      */

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

  /// 生成模拟路线数据（仅供开发测试）
  RouteInfo _generateMockRoute(
    LatLng origin,
    LatLng destination,
    RouteType routeType,
  ) {
    // 计算直线距离
    final straightDistance = calculateStraightDistance(origin, destination);

    // 模拟实际路线距离（通常是直线距离的1.2-1.5倍）
    final totalDistance = straightDistance * 1.3;

    // 根据路线类型估算时长
    int totalDuration;
    switch (routeType) {
      case RouteType.walking:
        totalDuration = (totalDistance / 1.4).round(); // 5km/h
        break;
      case RouteType.riding:
        totalDuration = (totalDistance / 4.2).round(); // 15km/h
        break;
      case RouteType.transit:
        totalDuration = (totalDistance / 8.3).round(); // 30km/h
        break;
      case RouteType.driving:
        totalDuration = (totalDistance / 13.9).round(); // 50km/h
        break;
    }

    // 生成简单的路线步骤
    final steps = <RouteStep>[
      RouteStep(
        instruction: '从起点出发',
        road: '起点',
        distance: 0,
        duration: 0,
        startLocation: origin,
        endLocation: origin,
      ),
      RouteStep(
        instruction: '直行${(totalDistance / 2).toStringAsFixed(0)}米',
        road: '主干道',
        distance: totalDistance / 2,
        duration: totalDuration ~/ 2,
        startLocation: origin,
        endLocation: LatLng(
          (origin.latitude + destination.latitude) / 2,
          (origin.longitude + destination.longitude) / 2,
        ),
      ),
      RouteStep(
        instruction: '到达终点',
        road: '终点',
        distance: totalDistance / 2,
        duration: totalDuration ~/ 2,
        startLocation: LatLng(
          (origin.latitude + destination.latitude) / 2,
          (origin.longitude + destination.longitude) / 2,
        ),
        endLocation: destination,
      ),
    ];

    // 生成简单的路线坐标点
    final polyline = <LatLng>[
      origin,
      LatLng(
        (origin.latitude + destination.latitude) / 2,
        (origin.longitude + destination.longitude) / 2,
      ),
      destination,
    ];

    // 估算费用
    double? taxiFee;
    double? transitFee;

    if (routeType == RouteType.driving) {
      taxiFee = 13 + (totalDistance / 1000) * 2.3; // 起步价13元 + 2.3元/km
    } else if (routeType == RouteType.transit) {
      transitFee = totalDistance < 5000 ? 2 : 4; // 5km内2元，否则4元
    }

    return RouteInfo(
      routeId: 'route_${DateTime.now().millisecondsSinceEpoch}',
      routeType: routeType,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      steps: steps,
      polyline: polyline,
      taxiFee: taxiFee,
      transitFee: transitFee,
    );
  }

  /// 搜索沿途兴趣点
  ///
  /// [route] 路线信息
  /// [poiType] POI类型（如：加油站、餐厅等）
  /// [searchRadius] 搜索半径（米）
  Future<List<dynamic>> searchPOIAlongRoute({
    required RouteInfo route,
    required String poiType,
    int searchRadius = 500,
  }) async {
    // 实际使用时调用高德沿途搜索API
    return [];
  }

  // ============================================================================
  // 翻译功能集成
  // ============================================================================

  /// 规划路线并自动翻译
  ///
  /// [origin] 起点坐标
  /// [destination] 终点坐标
  /// [routeType] 路线类型
  /// [strategy] 规划策略
  /// [city] 所在城市（可选，用于翻译）
  /// [enableTranslation] 是否启用翻译（默认true）
  Future<List<TranslatedRouteInfo>> planRouteWithTranslation({
    required LatLng origin,
    required LatLng destination,
    required RouteType routeType,
    RoutePlanStrategy strategy = RoutePlanStrategy.fastest,
    String? city,
    bool enableTranslation = true,
  }) async {
    try {
      // 1. 规划路线
      final routes = await planRoute(
        origin: origin,
        destination: destination,
        routeType: routeType,
        strategy: strategy,
      );

      if (routes.isEmpty) {
        return [];
      }

      // 2. 如果不启用翻译，直接返回
      if (!enableTranslation) {
        return routes.map((r) => TranslatedRouteInfo.fromRouteInfo(r)).toList();
      }

      // 3. 翻译路线
      final translatedRoutes = <TranslatedRouteInfo>[];

      for (var route in routes) {
        final translatedRoute = await _translationService.translateRoute(
          route,
          city: city,
        );
        translatedRoutes.add(translatedRoute);
      }

      return translatedRoutes;

    } catch (e) {
      print('❌ 路线规划和翻译失败: $e');
      return [];
    }
  }

  /// 仅翻译现有路线
  ///
  /// [route] 原始路线
  /// [city] 所在城市
  Future<TranslatedRouteInfo> translateRoute(
    RouteInfo route, {
    String? city,
  }) async {
    return await _translationService.translateRoute(route, city: city);
  }

  /// 批量翻译路线
  ///
  /// [routes] 原始路线列表
  /// [city] 所在城市
  Future<List<TranslatedRouteInfo>> translateRoutes(
    List<RouteInfo> routes, {
    String? city,
  }) async {
    final translatedRoutes = <TranslatedRouteInfo>[];

    for (var route in routes) {
      final translated = await _translationService.translateRoute(
        route,
        city: city,
      );
      translatedRoutes.add(translated);
    }

    return translatedRoutes;
  }
}
