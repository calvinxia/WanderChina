import 'package:x_amap_base/x_amap_base.dart';
import '../services/route_planning_service.dart';

/// 翻译后的路线步骤
///
/// 扩展原有RouteStep，添加英文翻译字段
class TranslatedRouteStep {
  final String instruction;         // 指令描述（中文）
  final String? instructionEn;      // 指令描述（英文）
  final String road;                // 道路名称（中文）
  final String? roadEn;             // 道路名称（英文）
  final double distance;            // 距离（米）
  final int duration;               // 时长（秒）
  final LatLng startLocation;       // 起点坐标
  final LatLng endLocation;         // 终点坐标

  /// 翻译元数据
  final bool isTranslated;          // 是否已翻译
  final String? translationSource;  // 翻译来源

  TranslatedRouteStep({
    required this.instruction,
    this.instructionEn,
    required this.road,
    this.roadEn,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    this.isTranslated = false,
    this.translationSource,
  });

  /// 从RouteStep创建（待翻译）
  factory TranslatedRouteStep.fromRouteStep(RouteStep step) {
    return TranslatedRouteStep(
      instruction: step.instruction,
      road: step.road,
      distance: step.distance,
      duration: step.duration,
      startLocation: step.startLocation,
      endLocation: step.endLocation,
      isTranslated: false,
    );
  }

  /// 复制并添加翻译
  TranslatedRouteStep copyWithTranslation({
    String? instructionEn,
    String? roadEn,
    String? translationSource,
  }) {
    return TranslatedRouteStep(
      instruction: instruction,
      instructionEn: instructionEn ?? this.instructionEn,
      road: road,
      roadEn: roadEn ?? this.roadEn,
      distance: distance,
      duration: duration,
      startLocation: startLocation,
      endLocation: endLocation,
      isTranslated: true,
      translationSource: translationSource ?? this.translationSource,
    );
  }

  /// 根据语言获取指令
  String getInstruction(String language) {
    if (language == 'en' && instructionEn != null) {
      return instructionEn!;
    }
    return instruction;
  }

  /// 根据语言获取道路名称
  String getRoad(String language) {
    if (language == 'en' && roadEn != null) {
      return roadEn!;
    }
    return road;
  }

  /// 格式化距离
  String formattedDistance(String language) {
    if (distance < 1000) {
      return language == 'en'
          ? '${distance.toStringAsFixed(0)}m'
          : '${distance.toStringAsFixed(0)}米';
    } else {
      return language == 'en'
          ? '${(distance / 1000).toStringAsFixed(1)}km'
          : '${(distance / 1000).toStringAsFixed(1)}公里';
    }
  }

  /// 格式化时长
  String formattedDuration(String language) {
    if (duration < 60) {
      return language == 'en'
          ? '${duration}s'
          : '$duration秒';
    } else if (duration < 3600) {
      final minutes = (duration / 60).toStringAsFixed(0);
      return language == 'en'
          ? '${minutes}min'
          : '$minutes分钟';
    } else {
      final hours = (duration / 3600).floor();
      final minutes = ((duration % 3600) / 60).floor();
      return language == 'en'
          ? '${hours}h ${minutes}min'
          : '$hours小时$minutes分钟';
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'instructionEn': instructionEn,
      'road': road,
      'roadEn': roadEn,
      'distance': distance,
      'duration': duration,
      'startLocation': {
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'endLocation': {
        'latitude': endLocation.latitude,
        'longitude': endLocation.longitude,
      },
      'isTranslated': isTranslated,
      'translationSource': translationSource,
    };
  }

  /// 从JSON创建
  factory TranslatedRouteStep.fromJson(Map<String, dynamic> json) {
    return TranslatedRouteStep(
      instruction: json['instruction'],
      instructionEn: json['instructionEn'],
      road: json['road'],
      roadEn: json['roadEn'],
      distance: json['distance'].toDouble(),
      duration: json['duration'],
      startLocation: LatLng(
        json['startLocation']['latitude'],
        json['startLocation']['longitude'],
      ),
      endLocation: LatLng(
        json['endLocation']['latitude'],
        json['endLocation']['longitude'],
      ),
      isTranslated: json['isTranslated'] ?? false,
      translationSource: json['translationSource'],
    );
  }
}

/// 翻译后的路线信息
///
/// 扩展原有RouteInfo，添加英文翻译字段
class TranslatedRouteInfo {
  final String routeId;
  final RouteType routeType;
  final double totalDistance;             // 总距离（米）
  final int totalDuration;                // 总时长（秒）
  final List<TranslatedRouteStep> steps;  // 路线步骤（翻译后）
  final List<LatLng> polyline;            // 路线坐标点
  final double? taxiFee;                  // 打车费用
  final double? transitFee;               // 公交费用

  /// 翻译元数据
  final bool isFullyTranslated;           // 是否完全翻译
  final int translatedStepsCount;         // 已翻译步骤数
  final String? translationSource;        // 翻译来源

  TranslatedRouteInfo({
    required this.routeId,
    required this.routeType,
    required this.totalDistance,
    required this.totalDuration,
    required this.steps,
    required this.polyline,
    this.taxiFee,
    this.transitFee,
    this.isFullyTranslated = false,
    int? translatedStepsCount,
    this.translationSource,
  }) : translatedStepsCount = translatedStepsCount ??
         steps.where((s) => s.isTranslated).length;

  /// 从RouteInfo创建（待翻译）
  factory TranslatedRouteInfo.fromRouteInfo(RouteInfo route) {
    return TranslatedRouteInfo(
      routeId: route.routeId,
      routeType: route.routeType,
      totalDistance: route.totalDistance,
      totalDuration: route.totalDuration,
      steps: route.steps.map((s) => TranslatedRouteStep.fromRouteStep(s)).toList(),
      polyline: route.polyline,
      taxiFee: route.taxiFee,
      transitFee: route.transitFee,
      isFullyTranslated: false,
    );
  }

  /// 复制并更新翻译步骤
  TranslatedRouteInfo copyWithTranslatedSteps(
    List<TranslatedRouteStep> translatedSteps,
  ) {
    final allTranslated = translatedSteps.every((s) => s.isTranslated);

    return TranslatedRouteInfo(
      routeId: routeId,
      routeType: routeType,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      steps: translatedSteps,
      polyline: polyline,
      taxiFee: taxiFee,
      transitFee: transitFee,
      isFullyTranslated: allTranslated,
      translationSource: 'map_translation_service',
    );
  }

  /// 格式化总距离
  String formattedDistance(String language) {
    if (totalDistance < 1000) {
      return language == 'en'
          ? '${totalDistance.toStringAsFixed(0)}m'
          : '${totalDistance.toStringAsFixed(0)}米';
    } else {
      return language == 'en'
          ? '${(totalDistance / 1000).toStringAsFixed(1)}km'
          : '${(totalDistance / 1000).toStringAsFixed(1)}公里';
    }
  }

  /// 格式化总时长
  String formattedDuration(String language) {
    if (totalDuration < 60) {
      return language == 'en'
          ? '${totalDuration}s'
          : '$totalDuration秒';
    } else if (totalDuration < 3600) {
      final minutes = (totalDuration / 60).toStringAsFixed(0);
      return language == 'en'
          ? '${minutes}min'
          : '$minutes分钟';
    } else {
      final hours = (totalDuration / 3600).floor();
      final minutes = ((totalDuration % 3600) / 60).floor();
      return language == 'en'
          ? '${hours}h ${minutes}min'
          : '$hours小时$minutes分钟';
    }
  }

  /// 获取路线类型标签
  String getRouteTypeLabel(String language) {
    if (language == 'en') {
      switch (routeType) {
        case RouteType.driving:
          return 'Driving';
        case RouteType.walking:
          return 'Walking';
        case RouteType.transit:
          return 'Transit';
        case RouteType.riding:
          return 'Cycling';
      }
    }
    return routeType.label;
  }

  /// 格式化费用
  String? formattedFee(String language) {
    if (taxiFee != null) {
      return language == 'en'
          ? 'Taxi: ¥${taxiFee!.toStringAsFixed(1)}'
          : '打车费用：¥${taxiFee!.toStringAsFixed(1)}';
    }
    if (transitFee != null) {
      return language == 'en'
          ? 'Transit: ¥${transitFee!.toStringAsFixed(0)}'
          : '公交费用：¥${transitFee!.toStringAsFixed(0)}';
    }
    return null;
  }

  /// 获取翻译进度百分比
  double get translationProgress {
    if (steps.isEmpty) return 0.0;
    return translatedStepsCount / steps.length;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'routeType': routeType.value,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'steps': steps.map((s) => s.toJson()).toList(),
      'polyline': polyline.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
      'taxiFee': taxiFee,
      'transitFee': transitFee,
      'isFullyTranslated': isFullyTranslated,
      'translatedStepsCount': translatedStepsCount,
      'translationSource': translationSource,
    };
  }

  /// 从JSON创建
  factory TranslatedRouteInfo.fromJson(Map<String, dynamic> json) {
    return TranslatedRouteInfo(
      routeId: json['routeId'],
      routeType: RouteType.values.firstWhere(
        (e) => e.value == json['routeType'],
      ),
      totalDistance: json['totalDistance'].toDouble(),
      totalDuration: json['totalDuration'],
      steps: (json['steps'] as List)
          .map((s) => TranslatedRouteStep.fromJson(s))
          .toList(),
      polyline: (json['polyline'] as List)
          .map((p) => LatLng(p['latitude'], p['longitude']))
          .toList(),
      taxiFee: json['taxiFee']?.toDouble(),
      transitFee: json['transitFee']?.toDouble(),
      isFullyTranslated: json['isFullyTranslated'] ?? false,
      translatedStepsCount: json['translatedStepsCount'],
      translationSource: json['translationSource'],
    );
  }
}

/// 路线类型翻译扩展
extension RouteTypeTranslation on RouteType {
  String getLabel(String language) {
    if (language == 'en') {
      switch (this) {
        case RouteType.driving:
          return 'Driving';
        case RouteType.walking:
          return 'Walking';
        case RouteType.transit:
          return 'Transit';
        case RouteType.riding:
          return 'Cycling';
      }
    }
    return label;
  }
}

/// 路线规划策略翻译扩展
extension RoutePlanStrategyTranslation on RoutePlanStrategy {
  String getLabel(String language) {
    if (language == 'en') {
      switch (this) {
        case RoutePlanStrategy.fastest:
          return 'Fastest';
        case RoutePlanStrategy.cheapest:
          return 'Cheapest';
        case RoutePlanStrategy.shortest:
          return 'Shortest';
        case RoutePlanStrategy.noHighway:
          return 'No Highway';
        case RoutePlanStrategy.avoidCongestion:
          return 'Avoid Congestion';
      }
    }
    return label;
  }
}
