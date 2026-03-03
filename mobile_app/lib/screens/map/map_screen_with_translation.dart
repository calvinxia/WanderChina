import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/services/language_manager.dart';
import '../../services/route_planning_service.dart';
import '../../services/poi_service.dart';
import '../../services/poi_translation_service.dart';
import '../../models/translated_route.dart';
import '../../models/translated_poi.dart';
import '../../widgets/map/route_step_card.dart';
import '../../widgets/map/bilingual_poi_info_window.dart';

/// 集成翻译功能的完整地图界面
///
/// 功能：
/// - 显示高德地图
/// - POI搜索和翻译显示
/// - 路线规划和翻译显示
/// - 双语切换
/// - 城市过滤
class MapScreenWithTranslation extends StatefulWidget {
  const MapScreenWithTranslation({Key? key}) : super(key: key);

  @override
  State<MapScreenWithTranslation> createState() => _MapScreenWithTranslationState();
}

class _MapScreenWithTranslationState extends State<MapScreenWithTranslation> {
  // 服务
  final LanguageManager _languageManager = LanguageManager();
  final RoutePlanningService _routeService = RoutePlanningService();
  final POIService _poiService = POIService();
  final POITranslationService _poiTranslationService = POITranslationService();

  // 地图控制器
  AMapController? _mapController;

  // 当前位置
  LatLng? _currentLocation;

  // POI数据
  List<TranslatedPOI> _nearbyPOIs = [];
  TranslatedPOI? _selectedPOI;

  // 路线数据
  TranslatedRouteInfo? _currentRoute;
  RouteType _selectedRouteType = RouteType.walking;

  // UI状态
  bool _isLoadingPOIs = false;
  bool _isLoadingRoute = false;
  bool _showRouteDetails = false;
  String? _currentCity;

  // 地图标记
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _languageManager.addListener(_onLanguageChanged);
    _initializeLocation();
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    super.dispose();
  }

  /// 语言切换回调
  void _onLanguageChanged() {
    setState(() {});
  }

  /// 初始化位置
  Future<void> _initializeLocation() async {
    // 默认位置：北京天安门
    setState(() {
      _currentLocation = LatLng(39.9042, 116.4074);
      _currentCity = '北京';
    });

    // 加载附近POI
    await _loadNearbyPOIs();
  }

  /// 加载附近POI
  Future<void> _loadNearbyPOIs() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoadingPOIs = true;
    });

    try {
      // 1. 搜索附近POI
      final pois = await _poiService.searchNearby(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radius: 2000,
      );

      // 2. 翻译POI
      final translatedPOIs = await _poiTranslationService.translatePOIs(pois);

      // 3. 更新标记
      _updatePOIMarkers(translatedPOIs);

      setState(() {
        _nearbyPOIs = translatedPOIs;
        _isLoadingPOIs = false;
      });

    } catch (e) {
      print('加载POI失败: $e');
      setState(() {
        _isLoadingPOIs = false;
      });
    }
  }

  /// 更新POI标记
  void _updatePOIMarkers(List<TranslatedPOI> pois) {
    _markers.clear();

    // 当前位置标记
    if (_currentLocation != null) {
      _markers.add(Marker(
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    // POI标记
    for (var poi in pois) {
      _markers.add(Marker(
        position: LatLng(poi.latitude, poi.longitude),
        infoWindow: InfoWindow(
          title: poi.getName(_languageManager.currentLanguage),
          snippet: poi.getAddress(_languageManager.currentLanguage),
        ),
        onTap: () => _onPOITap(poi),
      ));
    }
  }

  /// POI点击事件
  void _onPOITap(TranslatedPOI poi) {
    setState(() {
      _selectedPOI = poi;
      _showRouteDetails = false;
    });
  }

  /// 规划路线到POI
  Future<void> _planRouteToPOI(TranslatedPOI poi) async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
      _showRouteDetails = false;
    });

    try {
      // 规划路线并翻译
      final routes = await _routeService.planRouteWithTranslation(
        origin: _currentLocation!,
        destination: LatLng(poi.latitude, poi.longitude),
        routeType: _selectedRouteType,
        city: _currentCity,
      );

      if (routes.isNotEmpty) {
        final route = routes.first;

        // 更新路线显示
        _updateRoutePolyline(route);

        setState(() {
          _currentRoute = route;
          _isLoadingRoute = false;
          _showRouteDetails = true;
        });
      }

    } catch (e) {
      print('路线规划失败: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// 更新路线折线
  void _updateRoutePolyline(TranslatedRouteInfo route) {
    _polylines.clear();

    _polylines.add(Polyline(
      points: route.polyline,
      color: AppColors.primary,
      width: 5,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = _languageManager.currentLanguage;

    return Scaffold(
      body: Stack(
        children: [
          // 地图
          _buildMap(),

          // 顶部控制栏
          _buildTopControls(),

          // POI信息窗口
          if (_selectedPOI != null && !_showRouteDetails)
            _buildPOIInfoSheet(),

          // 路线详情
          if (_showRouteDetails && _currentRoute != null)
            _buildRouteDetailsSheet(),

          // 加载指示器
          if (_isLoadingPOIs || _isLoadingRoute)
            _buildLoadingIndicator(),
        ],
      ),
    );
  }

  /// 构建地图
  Widget _buildMap() {
    return AMapWidget(
      apiKey: AMapApiKey(
        androidKey: '您的高德地图Android Key',
        iosKey: '您的高德地图iOS Key',
      ),
      initialCameraPosition: CameraPosition(
        target: _currentLocation ?? LatLng(39.9042, 116.4074),
        zoom: 15,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: (latLng) {
        setState(() {
          _selectedPOI = null;
          _showRouteDetails = false;
        });
      },
    );
  }

  /// 构建顶部控制栏
  Widget _buildTopControls() {
    final currentLang = _languageManager.currentLanguage;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            // 搜索按钮
            _buildControlButton(
              icon: Icons.search,
              onTap: () {
                // TODO: 实现搜索功能
              },
            ),

            Spacer(),

            // 语言切换按钮
            _buildControlButton(
              icon: Icons.language,
              label: currentLang.toUpperCase(),
              onTap: () async {
                await _languageManager.toggleLanguage();
                // 重新加载POI以显示翻译
                _updatePOIMarkers(_nearbyPOIs);
              },
            ),

            SizedBox(width: AppSpacing.s),

            // 定位按钮
            _buildControlButton(
              icon: Icons.my_location,
              color: AppColors.primary,
              onTap: () async {
                if (_currentLocation != null && _mapController != null) {
                  await _mapController!.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentLocation!,
                        zoom: 15,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? AppColors.gray700,
              size: 24,
            ),
            if (label != null) ...[
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: color ?? AppColors.gray700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建POI信息窗口
  Widget _buildPOIInfoSheet() {
    final currentLang = _languageManager.currentLanguage;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXL),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSpacing.gapHeightS,

            // 拖动手柄
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // POI信息
            Padding(
              padding: EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称
                  Text(
                    _selectedPOI!.getName(currentLang),
                    style: AppTextStyles.h3(),
                  ),

                  // 中文原名（如果是英文显示）
                  if (currentLang == 'en' && _selectedPOI!.isTranslated)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _selectedPOI!.name,
                        style: AppTextStyles.caption(
                          color: AppColors.gray500,
                        ),
                      ),
                    ),

                  SizedBox(height: AppSpacing.m),

                  // 地址
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.gray500,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _selectedPOI!.getAddress(currentLang),
                          style: AppTextStyles.body(color: AppColors.gray600),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.l),

                  // 路线规划选项
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedRouteType = RouteType.walking;
                            });
                            _planRouteToPOI(_selectedPOI!);
                          },
                          icon: Icon(Icons.directions_walk),
                          label: Text(
                            currentLang == 'en' ? 'Walk' : '步行',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRouteType == RouteType.walking
                                ? AppColors.primary
                                : AppColors.gray200,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedRouteType = RouteType.transit;
                            });
                            _planRouteToPOI(_selectedPOI!);
                          },
                          icon: Icon(Icons.directions_transit),
                          label: Text(
                            currentLang == 'en' ? 'Transit' : '公交',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRouteType == RouteType.transit
                                ? AppColors.primary
                                : AppColors.gray200,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedRouteType = RouteType.driving;
                            });
                            _planRouteToPOI(_selectedPOI!);
                          },
                          icon: Icon(Icons.directions_car),
                          label: Text(
                            currentLang == 'en' ? 'Drive' : '驾车',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRouteType == RouteType.driving
                                ? AppColors.primary
                                : AppColors.gray200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建路线详情窗口
  Widget _buildRouteDetailsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXL),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              AppSpacing.gapHeightS,

              // 拖动手柄
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 路线详情
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // 路线概览
                    RouteSummaryCard(route: _currentRoute!),

                    // 步骤列表
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _currentRoute!.steps.length,
                      itemBuilder: (context, index) {
                        return RouteStepCard(
                          step: _currentRoute!.steps[index],
                          stepNumber: index + 1,
                        );
                      },
                    ),

                    SizedBox(height: 100), // 底部留白
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    final currentLang = _languageManager.currentLanguage;

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.m),
              Text(
                _isLoadingRoute
                    ? (currentLang == 'en' ? 'Planning route...' : '正在规划路线...')
                    : (currentLang == 'en' ? 'Loading POIs...' : '正在加载地点...'),
                style: AppTextStyles.body(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
