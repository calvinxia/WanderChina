# 地图翻译层集成指南

## 概述

本指南说明如何将地图翻译层集成到WanderChina应用的地图功能中，实现完整的双语地图体验。

**创建日期:** 2026-01-28
**版本:** 1.0.0

---

## 集成组件

### 已创建的组件

1. **RoutePlanningService（扩展）** - `lib/services/route_planning_service.dart`
   - `planRouteWithTranslation()` - 规划并翻译路线
   - `translateRoute()` - 翻译现有路线
   - 自动集成MapTranslationService

2. **RouteStepCard** - `lib/widgets/map/route_step_card.dart`
   - 路线步骤卡片（双语显示）
   - 路线概览卡片
   - 路线步骤列表

3. **MapScreenWithTranslation** - `lib/screens/map/map_screen_with_translation.dart`
   - 完整的功能性地图界面
   - POI搜索和翻译
   - 路线规划和翻译
   - 双语切换

---

## 快速开始

### 1. 初始化服务

在应用启动时初始化所有翻译服务：

```dart
import 'package:wanderchina/services/map_translation_service.dart';
import 'package:wanderchina/services/poi_translation_service.dart';
import 'package:wanderchina/core/services/language_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化语言管理器
  await LanguageManager().initialize();

  // 初始化POI翻译服务
  await POITranslationService().initialize();

  // 初始化地图翻译服务
  await MapTranslationService().initialize();

  runApp(MyApp());
}
```

### 2. 使用翻译后的路线规划

最简单的方式 - 直接使用 `planRouteWithTranslation`：

```dart
import 'package:wanderchina/services/route_planning_service.dart';
import 'package:wanderchina/models/translated_route.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

// 规划路线并自动翻译
final routeService = RoutePlanningService();

final translatedRoutes = await routeService.planRouteWithTranslation(
  origin: LatLng(39.9042, 116.4074),      // 天安门
  destination: LatLng(39.9163, 116.3972),  // 故宫
  routeType: RouteType.walking,
  city: '北京',                            // 指定城市以提高翻译准确度
  enableTranslation: true,                 // 启用翻译（默认）
);

if (translatedRoutes.isNotEmpty) {
  final route = translatedRoutes.first;
  print('总距离: ${route.formattedDistance('zh')}');
  print('Total Distance: ${route.formattedDistance('en')}');
}
```

### 3. 显示路线步骤

使用提供的组件显示翻译后的路线：

```dart
import 'package:wanderchina/widgets/map/route_step_card.dart';

// 在UI中显示路线
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: RouteStepsList(
      route: translatedRoute,
      showSummary: true,
    ),
  );
}
```

### 4. 显示单个步骤

```dart
// 显示单个路线步骤
RouteStepCard(
  step: translatedRoute.steps[0],
  stepNumber: 1,
  showTranslationBadge: true,
)
```

---

## 完整集成示例

### 示例1：基础路线规划和显示

```dart
import 'package:flutter/material.dart';
import 'package:wanderchina/services/route_planning_service.dart';
import 'package:wanderchina/widgets/map/route_step_card.dart';
import 'package:wanderchina/core/services/language_manager.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

class SimpleRoutePage extends StatefulWidget {
  @override
  _SimpleRoutePageState createState() => _SimpleRoutePageState();
}

class _SimpleRoutePageState extends State<SimpleRoutePage> {
  final RoutePlanningService _routeService = RoutePlanningService();
  final LanguageManager _languageManager = LanguageManager();

  TranslatedRouteInfo? _route;
  bool _isLoading = false;

  Future<void> _planRoute() async {
    setState(() {
      _isLoading = true;
    });

    final routes = await _routeService.planRouteWithTranslation(
      origin: LatLng(39.9042, 116.4074),
      destination: LatLng(39.9163, 116.3972),
      routeType: RouteType.walking,
      city: '北京',
    );

    setState(() {
      _route = routes.isNotEmpty ? routes.first : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = _languageManager.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLang == 'en' ? 'Route Planning' : '路线规划'),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              _languageManager.toggleLanguage();
              setState(() {});
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _route == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _planRoute,
                    child: Text(
                      currentLang == 'en' ? 'Plan Route' : '规划路线',
                    ),
                  ),
                )
              : RouteStepsList(route: _route!),
    );
  }
}
```

### 示例2：与POI集成

```dart
import 'package:wanderchina/services/poi_service.dart';
import 'package:wanderchina/services/poi_translation_service.dart';
import 'package:wanderchina/services/route_planning_service.dart';

class POIWithRoutePage extends StatefulWidget {
  @override
  _POIWithRoutePageState createState() => _POIWithRoutePageState();
}

class _POIWithRoutePageState extends State<POIWithRoutePage> {
  final POIService _poiService = POIService();
  final POITranslationService _poiTranslationService = POITranslationService();
  final RoutePlanningService _routeService = RoutePlanningService();

  TranslatedPOI? _selectedPOI;
  TranslatedRouteInfo? _route;

  /// 搜索POI
  Future<void> _searchPOI() async {
    final pois = await _poiService.searchNearby(
      latitude: 39.9042,
      longitude: 116.4074,
      radius: 2000,
    );

    if (pois.isNotEmpty) {
      final translatedPOI = await _poiTranslationService.translatePOI(pois.first);
      setState(() {
        _selectedPOI = translatedPOI;
      });
    }
  }

  /// 规划到POI的路线
  Future<void> _planRouteToPOI() async {
    if (_selectedPOI == null) return;

    final routes = await _routeService.planRouteWithTranslation(
      origin: LatLng(39.9042, 116.4074),
      destination: LatLng(_selectedPOI!.latitude, _selectedPOI!.longitude),
      routeType: RouteType.walking,
      city: '北京',
    );

    setState(() {
      _route = routes.isNotEmpty ? routes.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = LanguageManager().currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text('POI + Route'),
      ),
      body: Column(
        children: [
          // POI信息
          if (_selectedPOI != null)
            Card(
              child: ListTile(
                title: Text(_selectedPOI!.getName(currentLang)),
                subtitle: Text(_selectedPOI!.getAddress(currentLang)),
                trailing: IconButton(
                  icon: Icon(Icons.directions),
                  onPressed: _planRouteToPOI,
                ),
              ),
            ),

          // 路线信息
          if (_route != null)
            Expanded(
              child: RouteStepsList(route: _route!),
            ),

          // 搜索按钮
          if (_selectedPOI == null)
            ElevatedButton(
              onPressed: _searchPOI,
              child: Text('Search POI'),
            ),
        ],
      ),
    );
  }
}
```

### 示例3：地图上显示路线

```dart
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:wanderchina/models/translated_route.dart';

class RouteMapPage extends StatefulWidget {
  final TranslatedRouteInfo route;

  const RouteMapPage({required this.route});

  @override
  _RouteMapPageState createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  AMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupRouteOnMap();
  }

  void _setupRouteOnMap() {
    // 创建路线折线
    _polylines.add(Polyline(
      points: widget.route.polyline,
      color: Colors.blue,
      width: 5,
    ));

    // 添加起点和终点标记
    if (widget.route.polyline.isNotEmpty) {
      _markers.add(Marker(
        position: widget.route.polyline.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(title: 'Start'),
      ));

      _markers.add(Marker(
        position: widget.route.polyline.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(title: 'Destination'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 地图
          AMapWidget(
            initialCameraPosition: CameraPosition(
              target: widget.route.polyline.first,
              zoom: 15,
            ),
            polylines: _polylines,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              // 自动缩放以显示整条路线
              _fitRouteBounds();
            },
          ),

          // 路线信息卡片
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RouteSummaryCard(route: widget.route),
          ),
        ],
      ),
    );
  }

  void _fitRouteBounds() {
    if (_mapController == null || widget.route.polyline.isEmpty) return;

    // 计算边界
    double minLat = widget.route.polyline.first.latitude;
    double maxLat = widget.route.polyline.first.latitude;
    double minLng = widget.route.polyline.first.longitude;
    double maxLng = widget.route.polyline.first.longitude;

    for (var point in widget.route.polyline) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.moveCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }
}
```

---

## API参考

### RoutePlanningService扩展方法

#### planRouteWithTranslation()

规划路线并自动翻译所有步骤。

```dart
Future<List<TranslatedRouteInfo>> planRouteWithTranslation({
  required LatLng origin,           // 起点坐标
  required LatLng destination,      // 终点坐标
  required RouteType routeType,     // 路线类型
  RoutePlanStrategy strategy = RoutePlanStrategy.fastest,  // 规划策略
  String? city,                     // 所在城市（可选）
  bool enableTranslation = true,    // 是否启用翻译
})
```

**返回值:** `List<TranslatedRouteInfo>` - 翻译后的路线列表

**示例:**
```dart
final routes = await routeService.planRouteWithTranslation(
  origin: LatLng(39.9042, 116.4074),
  destination: LatLng(39.9163, 116.3972),
  routeType: RouteType.walking,
  city: '北京',
);
```

#### translateRoute()

翻译现有路线。

```dart
Future<TranslatedRouteInfo> translateRoute(
  RouteInfo route,
  {String? city}
)
```

**示例:**
```dart
final route = await routeService.planRoute(...);
final translatedRoute = await routeService.translateRoute(
  route.first,
  city: '北京',
);
```

### TranslatedRouteInfo

翻译后的路线信息模型。

**属性:**
- `routeId: String` - 路线ID
- `routeType: RouteType` - 路线类型
- `totalDistance: double` - 总距离（米）
- `totalDuration: int` - 总时长（秒）
- `steps: List<TranslatedRouteStep>` - 翻译后的步骤列表
- `polyline: List<LatLng>` - 路线坐标点
- `isFullyTranslated: bool` - 是否完全翻译
- `translationProgress: double` - 翻译进度（0.0-1.0）

**方法:**
- `formattedDistance(String language)` - 格式化距离
- `formattedDuration(String language)` - 格式化时长
- `getRouteTypeLabel(String language)` - 获取路线类型标签
- `formattedFee(String language)` - 格式化费用

### TranslatedRouteStep

翻译后的路线步骤。

**属性:**
- `instruction: String` - 指令（中文）
- `instructionEn: String?` - 指令（英文）
- `road: String` - 道路名称（中文）
- `roadEn: String?` - 道路名称（英文）
- `distance: double` - 距离（米）
- `duration: int` - 时长（秒）
- `isTranslated: bool` - 是否已翻译

**方法:**
- `getInstruction(String language)` - 获取指令
- `getRoad(String language)` - 获取道路名称
- `formattedDistance(String language)` - 格式化距离
- `formattedDuration(String language)` - 格式化时长

---

## UI组件参考

### RouteStepCard

显示单个路线步骤的卡片。

```dart
RouteStepCard(
  step: translatedStep,              // TranslatedRouteStep
  stepNumber: 1,                     // 步骤编号
  showTranslationBadge: true,        // 显示翻译标记
)
```

### RouteSummaryCard

显示路线概览信息。

```dart
RouteSummaryCard(
  route: translatedRoute,            // TranslatedRouteInfo
)
```

### RouteStepsList

显示完整的路线步骤列表。

```dart
RouteStepsList(
  route: translatedRoute,            // TranslatedRouteInfo
  showSummary: true,                 // 显示概览卡片
)
```

---

## 最佳实践

### 1. 始终指定城市

```dart
// 好 ✅
await routeService.planRouteWithTranslation(
  origin: origin,
  destination: destination,
  routeType: RouteType.walking,
  city: '北京',  // 指定城市以提高翻译准确度
);

// 不推荐 ⚠️
await routeService.planRouteWithTranslation(
  origin: origin,
  destination: destination,
  routeType: RouteType.walking,
  // 未指定城市，翻译可能不准确
);
```

### 2. 检查翻译结果

```dart
final routes = await routeService.planRouteWithTranslation(...);

if (routes.isNotEmpty) {
  final route = routes.first;

  if (route.isFullyTranslated) {
    print('✅ 路线已完全翻译');
  } else {
    print('⚠️ 部分步骤未翻译 (${(route.translationProgress * 100).toInt()}%)');
  }
}
```

### 3. 处理加载状态

```dart
setState(() {
  _isLoading = true;
});

try {
  final routes = await routeService.planRouteWithTranslation(...);
  // 处理结果
} catch (e) {
  print('错误: $e');
  // 显示错误提示
} finally {
  setState(() {
    _isLoading = false;
  });
}
```

### 4. 缓存路线结果

```dart
// 缓存翻译后的路线，避免重复翻译
Map<String, TranslatedRouteInfo> _routeCache = {};

Future<TranslatedRouteInfo> _getOrPlanRoute(
  LatLng origin,
  LatLng destination,
) async {
  final cacheKey = '${origin.latitude},${origin.longitude}_${destination.latitude},${destination.longitude}';

  if (_routeCache.containsKey(cacheKey)) {
    return _routeCache[cacheKey]!;
  }

  final routes = await routeService.planRouteWithTranslation(
    origin: origin,
    destination: destination,
    routeType: RouteType.walking,
  );

  if (routes.isNotEmpty) {
    _routeCache[cacheKey] = routes.first;
    return routes.first;
  }

  throw Exception('路线规划失败');
}
```

---

## 故障排除

### 问题1：路线未翻译

**症状:** 路线规划成功，但 `isFullyTranslated` 为 false

**可能原因:**
1. 未指定城市或城市不在支持范围内
2. 数据库中缺少翻译数据
3. MapTranslationService未初始化

**解决方案:**
```dart
// 1. 检查城市是否支持
import '../../core/constants/supported_cities.dart';

if (SupportedCities.isCitySupported('北京')) {
  // 城市支持
}

// 2. 检查服务初始化
final mapTranslation = MapTranslationService();
print('已初始化: ${mapTranslation.isInitialized}');

// 3. 查看缓存统计
print(mapTranslation.getCacheStats());
```

### 问题2：UI不更新

**症状:** 切换语言后UI不更新

**解决方案:**
```dart
// 1. 确保监听语言变化
@override
void initState() {
  super.initState();
  _languageManager.addListener(_onLanguageChanged);
}

void _onLanguageChanged() {
  setState(() {
    // 强制重建UI
  });
}

@override
void dispose() {
  _languageManager.removeListener(_onLanguageChanged);
  super.dispose();
}
```

### 问题3：性能问题

**症状:** 路线规划和翻译很慢

**解决方案:**
```dart
// 1. 使用批量翻译
final translatedRoutes = await routeService.translateRoutes(
  routes,
  city: '北京',
);

// 2. 检查缓存是否工作
final stats = MapTranslationService().getCacheStats();
print('缓存命中率: ${stats['roadCache']}/${stats['totalRequests']}');

// 3. 预加载常用翻译
await MapTranslationService().initialize();
```

---

## 相关文档

- **地图翻译层指南:** `MAP_TRANSLATION_GUIDE.md`
- **POI翻译层指南:** `POI_TRANSLATION_GUIDE.md`
- **数据库架构:** `database/map_translation_schema.sql`

---

**版本:** 1.0.0
**最后更新:** 2026-01-28
**维护者:** WanderChina开发团队
