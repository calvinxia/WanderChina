import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:x_amap_base/x_amap_base.dart';
import '../../widgets/map/wander_map.dart';
import '../../widgets/map/map_search_bar.dart';
import '../../widgets/map/language_switcher.dart';
import '../../widgets/map/voice_fab.dart';
import '../../widgets/map/poi_bottom_sheet.dart';
import '../../widgets/map/route_overview.dart';
import '../../models/poi_translation.dart';
import '../../models/poi.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/city_theme.dart';
import '../../services/poi_service.dart';
import '../../services/route_planning_service.dart';
import '../../services/amap_service.dart';
import '../../services/api_client.dart';
import '../../services/analytics_service.dart';
import '../../core/config/backend_config.dart';
import '../voice/voice_translation_screen.dart';
import '../main/main_screen.dart';

/// Map Screen with Translation - MVP v2.0
///
/// 地图页面，集成翻译蒙层、语音翻译、POI 详情、路线规划
class MapWithTranslationScreen extends StatefulWidget {
  final String? cityName;
  final LatLng? initialLocation;
  final AppLanguage language;

  const MapWithTranslationScreen({
    super.key,
    this.cityName,
    this.initialLocation,
    this.language = AppLanguage.english,
  });

  @override
  State<MapWithTranslationScreen> createState() =>
      MapWithTranslationScreenState();
}

class MapWithTranslationScreenState extends State<MapWithTranslationScreen> {
  final GlobalKey<WanderMapState> _mapKey = GlobalKey<WanderMapState>();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final _analytics = AnalyticsService.instance;

  late AppLanguage _currentLanguage;
  bool _showTranslationOverlay = true;
  POITranslation? _selectedPOI;
  VoiceFABState _voiceState = VoiceFABState.idle;

  // Fix-7.A: 搜索功能状态
  final POIService _poiService = POIService();
  List<POI> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  // Fix-7.B: 路线规划服务
  final RoutePlanningService _routeService = RoutePlanningService();

  // Fix-7.D: 缩放控制
  double _currentZoom = 15.0;
  LatLng? _currentCenter;

  // Fix-7.E: 翻译方向
  bool _directionIsChToEn = false;

  // Step 4.1: 路线规划状态
  bool _showPOISheet = false;
  bool _showRoutePanel = false;
  bool _isLoadingRoutes = false;
  LatLng? _currentLocation;  // 从定位获取
  bool _showRouteOnMap = false;  // Scenario 1: 路线已显示在地图上
  LatLng? _customOrigin;  // 自定义起点
  String _originName = 'My Location';  // 起点名称

  List<RouteInfo>? _transitRoutes;
  List<RouteInfo>? _walkingRoutes;
  List<RouteInfo>? _drivingRoutes;

  // 预设城市坐标
  static const Map<String, LatLng> _cityCoordinates = {
    '北京': LatLng(39.9042, 116.4074), // 天安门
    '上海': LatLng(31.2304, 121.4737), // 外滩
    '广州': LatLng(23.1291, 113.2644), // 广州塔
    '深圳': LatLng(22.5431, 114.0579), // 市民中心
    '成都': LatLng(30.6598, 104.0633), // 天府广场
    '西安': LatLng(34.2655, 108.9541), // 钟楼
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
    _fetchCurrentLocation();
  }

  /// 从外部调用的搜索方法（供 MainScreen 使用）
  void searchFromExternal(String query, {String? displayName, String? city, String? fallbackQuery}) {
    // 搜索框显示英文名（用户可读）
    _searchController.text = displayName ?? query;

    // 后台用中文名搜索（精确匹配）
    _handleSearch(query, city: city, displayName: displayName, fallbackQuery: fallbackQuery);
  }

  /// 映射英文城市名到中文
  String _mapCityToZh(String? city) {
    if (city == null) return '北京';
    const map = {
      'Beijing': '北京',
      'Shanghai': '上海',
      'Guangzhou': '广州',
      'Shenzhen': '深圳',
      'Chengdu': '成都',
      "Xi'an": '西安',
      'beijing': '北京',
      'shanghai': '上海',
      'guangzhou': '广州',
      'shenzhen': '深圳',
      'chengdu': '成都',
      "xi'an": '西安',
    };
    return map[city] ?? '北京';
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final amapService = AMapService();
      await amapService.initialize();
      final location = await amapService.getLocation();
      if (location != null && mounted) {
        final lat = double.tryParse(location['latitude'].toString());
        final lng = double.tryParse(location['longitude'].toString());
        if (lat != null && lng != null) {
          debugPrint('📍 Got location: $lat, $lng');
          setState(() {
            _currentLocation = LatLng(lat, lng);
          });
          _mapKey.currentState?.moveTo(_currentLocation!, zoom: 15);
        }
      }
    } catch (e) {
      debugPrint('📍 Location failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter {
    if (widget.initialLocation != null) {
      return widget.initialLocation!;
    }
    if (widget.cityName != null &&
        _cityCoordinates.containsKey(widget.cityName)) {
      return _cityCoordinates[widget.cityName]!;
    }
    return _cityCoordinates['北京']!; // 默认北京
  }

  void _handleSearchTap() {
    // 点击搜索框时，不做特殊处理，让用户直接输入
    debugPrint('Search bar tapped');
  }

  // Fix-7.A: 搜索POI功能
  Future<void> _handleSearch(String query, {String? city, String? displayName, String? fallbackQuery}) async {
    if (query.trim().isEmpty) return;

    FocusScope.of(context).unfocus(); // 收键盘
    setState(() => _isSearching = true);

    try {
      // 城市名中英映射
      final cityZh = city != null ? _mapCityToZh(city) : null;

      final keyword = query.trim();

      // Analytics tracking
      _analytics.searchPoi(keyword, city: cityZh);

      Sentry.addBreadcrumb(Breadcrumb(
        category: 'poi',
        message: 'search_poi called',
        data: {'keyword': keyword, 'city': cityZh ?? ''},
      ));

      final rawResults = await _poiService.searchByKeyword(
        keyword: keyword,
        city: cityZh,
      );
      final results = List.of(rawResults);

      // 结果太少且有备选关键词 → 再搜一次，合并去重
      if (results.length <= 1 && fallbackQuery != null && fallbackQuery != keyword) {
        debugPrint('🔍 Primary search got ${results.length} results, trying fallback: $fallbackQuery');
        final fallbackResults = await _poiService.searchByKeyword(
          keyword: fallbackQuery,
          city: cityZh,
        );
        final existingIds = results.map((r) => r.id).toSet();
        for (final r in fallbackResults) {
          if (!existingIds.contains(r.id)) results.add(r);
        }
        debugPrint('🔍 After fallback: ${results.length} results');
      }

      if (mounted) {
        // 诊断日志
        debugPrint('🔍 Search keyword: $keyword');
        debugPrint('🔍 Results count: ${results.length}');
        for (final r in results.take(3)) {
          debugPrint('🔍 Result: ${r.name} → lat=${r.latitude}, lng=${r.longitude}');
        }

        if (results.isNotEmpty) {
          // 正常流程：显示搜索结果
          setState(() {
            _searchResults = results;
            _showSearchResults = true;  // 显示下拉列表
            _isSearching = false;
          });
          // 移动到第一个结果
          _mapKey.currentState?.moveTo(
            LatLng(results.first.latitude, results.first.longitude),
            zoom: 16.0,
          );
        } else {
          // 搜不到 → 即时翻译链路
          debugPrint('🔄 POI not in DB, triggering on-the-fly translation...');
          await _onTheFlyTranslate(query, city: city, displayName: displayName);
          setState(() => _isSearching = false);
        }
      }
    } catch (e) {
      debugPrint('🔍 Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showSearchResults = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('POI search failed: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// 即时翻译链路：高德查坐标 → DeepSeek 翻译 → 写入 DB
  /// 使用乐观更新：先移动地图，后台翻译
  Future<void> _onTheFlyTranslate(String nameZh, {String? city, String? displayName}) async {
    try {
      // Step 1: 调 poi_photo 获取坐标 + poi_id
      debugPrint('🔄 Step 1: Fetching POI info from Gaode...');
      final poiInfo = await ApiClient.post(BackendConfig.poiPhotoUrl, {
        'action': 'single',
        'name_zh': nameZh,
        'city': city ?? '',
      });

      final poiId = poiInfo['poi_id'] as String?;
      final lat = poiInfo['lat'] as double?;
      final lng = poiInfo['lng'] as double?;

      if (poiId == null || lat == null || lng == null) {
        debugPrint('🔄 POI not found in Gaode');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${displayName ?? nameZh}" not found')),
          );
        }
        return;
      }
      debugPrint('🔄 Got POI: id=$poiId, lat=$lat, lng=$lng');

      // Step 2: 乐观更新 — 立刻移动地图，不等翻译
      if (mounted) {
        _mapKey.currentState?.moveTo(LatLng(lat, lng), zoom: 16.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translating "${displayName ?? nameZh}"...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Step 3: 后台继续翻译
      debugPrint('🔄 Step 2: Translating via DeepSeek...');
      final nameEn = displayName ?? nameZh;  // 如果已有英文名就直接用
      String translatedName = nameEn;

      if (displayName == null || displayName == nameZh) {
        // 需要翻译
        Sentry.addBreadcrumb(Breadcrumb(
          category: 'poi',
          message: 'translate called',
          data: {'name_zh': nameZh},
        ));
        final transResult = await ApiClient.post(BackendConfig.translateUrl, {
          'text': nameZh,
          'target_lang': 'en',
        });
        translatedName = transResult['translated_text'] ?? nameZh;
        debugPrint('🔄 Translated: $nameZh → $translatedName');
      }

      // Step 4: 调 translate_db_write 存入 DB + Redis（fire-and-forget，不阻塞 UI）
      debugPrint('🔄 Step 3: Saving to DB (fire-and-forget)...');
      Sentry.addBreadcrumb(Breadcrumb(
        category: 'poi',
        message: 'db_write called',
        data: {'poi_id': poiId, 'name_zh': nameZh, 'name_en': translatedName},
      ));
      unawaited(ApiClient.post(BackendConfig.dbWriteUrl, {
        'action': 'save',
        'poi_id': poiId,
        'name_zh': nameZh,
        'name_en': translatedName,
        'latitude': lat,
        'longitude': lng,
        'city': _mapCityToZh(city ?? ''),
        'category_zh': poiInfo['category'] ?? '',
      }).catchError((e) {
        debugPrint('⚠️ DB write failed (non-blocking): $e');
        return <String, dynamic>{};
      }));

      // Step 5: 翻译完成后更新提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found "$translatedName" — translated and saved'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔄 On-the-fly translate failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleLanguageChanged(AppLanguage language) {
    setState(() {
      _currentLanguage = language;
    });
  }

  void _handleOverlayToggle(bool enabled) {
    setState(() {
      _showTranslationOverlay = enabled;
    });
  }

  // Fix-7.C: 短按 → 打开全屏语音翻译页面
  void _handleVoiceTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const VoiceTranslationScreen(),
      ),
    );
  }

  void _handleVoiceLongPress() {
    // TODO: 就地录音翻译（未来功能）
    setState(() {
      _voiceState = VoiceFABState.recording;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _voiceState = VoiceFABState.idle;
        });
      }
    });
  }

  // Fix-7.E: 交换翻译方向
  void _handleDirectionSwap() {
    setState(() {
      _directionIsChToEn = !_directionIsChToEn;
    });
  }

  // Step 4.2: POI 点击 → 显示 Bottom Sheet
  void _handlePOITap(POITranslation poi) {
    debugPrint('🗺️ POI tapped: ${poi.nameEn} / ${poi.nameZh}');

    // Scenario 2: 清除上一条路线
    if (_showRouteOnMap) {
      _mapKey.currentState?.clearRoute();
      _mapKey.currentState?.clearSearchMarkers();
      _showRouteOnMap = false;
    }

    setState(() {
      _selectedPOI = poi;
      _showPOISheet = true;
      _showRoutePanel = false;
    });
  }

  // Step 4.3: 点击 Directions → 请求 3 种路线
  Future<void> _requestRoutes(POITranslation poi) async {
    debugPrint('🗺️ _currentLocation: $_currentLocation');
    debugPrint('🗺️ destination: ${poi.coordinates.latitude}, ${poi.coordinates.longitude}');

    final destination = LatLng(poi.coordinates.latitude, poi.coordinates.longitude);
    final origin = _customOrigin ?? _currentLocation ?? const LatLng(39.9042, 116.4074);

    setState(() {
      _showPOISheet = false;
      _showRoutePanel = true;
      _isLoadingRoutes = true;
      _transitRoutes = null;
      _walkingRoutes = null;
      _drivingRoutes = null;
    });

    // 并行请求三种出行方式
    final results = await Future.wait([
      _routeService.planRoute(
        origin: origin, destination: destination,
        routeType: RouteType.transit,
      ),
      _routeService.planRoute(
        origin: origin, destination: destination,
        routeType: RouteType.walking,
      ),
      _routeService.planRoute(
        origin: origin, destination: destination,
        routeType: RouteType.driving,
      ),
    ]);

    debugPrint('🛣️ Transit: ${results[0].length}, Walking: ${results[1].length}, Driving: ${results[2].length}');

    if (mounted) {
      setState(() {
        _transitRoutes = results[0];
        _walkingRoutes = results[1];
        _drivingRoutes = results[2];
        _isLoadingRoutes = false;
      });
    }
  }

  // Step 4.4: 选择方案 → 地图画线
  void _onRouteSelected(RouteType type) {
    debugPrint('🛣️ Route selected: $type');

    List<RouteInfo>? routes;
    String routeMode;
    switch (type) {
      case RouteType.transit:
        routes = _transitRoutes;
        routeMode = 'transit';
        break;
      case RouteType.walking:
        routes = _walkingRoutes;
        routeMode = 'walk';
        break;
      case RouteType.driving:
        routes = _drivingRoutes;
        routeMode = 'drive';
        break;
      default:
        routes = null;
        routeMode = 'unknown';
    }

    debugPrint('🛣️ Routes available: ${routes?.length ?? 0}');

    if (routes == null || routes.isEmpty) {
      debugPrint('🛣️ No routes to show!');
      return;
    }

    if (_selectedPOI == null) return;

    // Analytics tracking
    _analytics.routePlanned(routeMode, _selectedPOI!.localizedName(AppLanguage.english));

    final route = routes.first;
    debugPrint('🛣️ Polyline points: ${route.polyline.length}');
    debugPrint('🛣️ Duration: ${route.formattedDuration}, Distance: ${route.formattedDistance}');

    final origin = _customOrigin ?? _currentLocation ?? const LatLng(39.9042, 116.4074);
    final destination = LatLng(_selectedPOI!.coordinates.latitude, _selectedPOI!.coordinates.longitude);

    // 在地图上画路线 + 起终点 marker
    if (route.polyline.isNotEmpty) {
      _mapKey.currentState?.showRouteWithMarkers(
        route.polyline,
        origin,
        destination,
      );
    } else {
      // polyline 为空，只放起终点 marker，不画线
      _mapKey.currentState?.clearRoute();
      _mapKey.currentState?.moveTo(destination, zoom: 14);
    }

    // 收起面板 + 显示路线清除按钮（Scenario 1）
    setState(() {
      _showRoutePanel = false;
      _showRouteOnMap = true;
    });
  }

  // Step 4.6: 清除路线状态
  void _clearRouteState() {
    _mapKey.currentState?.clearRoute();
    _mapKey.currentState?.clearSearchMarkers();
    setState(() {
      _showRoutePanel = false;
      _showPOISheet = false;
      _showRouteOnMap = false;  // Scenario 1: 隐藏清除按钮
      _selectedPOI = null;
      _transitRoutes = null;
      _walkingRoutes = null;
      _drivingRoutes = null;
    });
  }

  // Step 4.7: 选择起点对话框
  Future<void> _showOriginPicker() async {
    final controller = TextEditingController();
    final cityTheme = context.findAncestorStateOfType<MainScreenState>()?.cityTheme ?? CityTheme.defaultTheme;
    final dialogBg = Color.lerp(Colors.white, cityTheme.pillActiveColor, 0.05)!;

    final result = await showDialog<LatLng>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Set Starting Point', style: TextStyle(color: cityTheme.primaryTextColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 使用当前位置按钮
            ListTile(
              leading: Icon(Icons.my_location, color: cityTheme.pillActiveColor),
              title: Text('Use Current Location', style: TextStyle(color: cityTheme.primaryTextColor)),
              onTap: () => Navigator.pop(ctx, _currentLocation),
            ),
            const Divider(),
            // 使用地图中心点
            ListTile(
              leading: Icon(Icons.center_focus_strong, color: cityTheme.pillActiveColor),
              title: Text('Use Map Center', style: TextStyle(color: cityTheme.primaryTextColor)),
              subtitle: Text(
                'Lat: ${_currentCenter?.latitude.toStringAsFixed(4)}, Lng: ${_currentCenter?.longitude.toStringAsFixed(4)}',
                style: TextStyle(fontSize: 11, color: cityTheme.secondaryTextColor.withOpacity(0.7)),
              ),
              onTap: () => Navigator.pop(ctx, _currentCenter),
            ),
            const Divider(),
            // 搜索地点
            TextField(
              controller: controller,
              cursorColor: cityTheme.pillActiveColor,
              style: TextStyle(color: cityTheme.primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Search a place...',
                hintStyle: TextStyle(color: cityTheme.secondaryTextColor.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cityTheme.pillActiveColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: cityTheme.pillActiveColor),
                  onPressed: () async {
                    final keyword = controller.text.trim();
                    if (keyword.isEmpty) return;
                    try {
                      final results = await _poiService.searchByKeyword(keyword: keyword);
                      if (results.isNotEmpty && ctx.mounted) {
                        Navigator.pop(ctx, LatLng(results.first.latitude, results.first.longitude));
                      }
                    } catch (_) {}
                  },
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) async {
                if (value.trim().isEmpty) return;
                try {
                  final results = await _poiService.searchByKeyword(keyword: value.trim());
                  if (results.isNotEmpty && ctx.mounted) {
                    Navigator.pop(ctx, LatLng(results.first.latitude, results.first.longitude));
                  }
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );

    if (result != null && _selectedPOI != null) {
      setState(() {
        _customOrigin = result;
        _originName = result == _currentLocation ? 'My Location' : 'Custom Location';
      });
      // 重新请求路线
      _requestRoutes(_selectedPOI!);
    }
  }

  void _handleRecenter() {
    _mapKey.currentState?.moveTo(_initialCenter, zoom: 15.0);
  }

  /// 根据 POI 类别返回对应的 Material Design 图标
  IconData _getCategoryIcon(dynamic category) {
    final cat = category?.toString().toLowerCase() ?? '';
    if (cat.contains('subway') || cat.contains('metro') || cat.contains('station')) return Icons.train;
    if (cat.contains('restaurant') || cat.contains('food')) return Icons.restaurant;
    if (cat.contains('hotel')) return Icons.hotel;
    if (cat.contains('museum') || cat.contains('attraction')) return Icons.museum;
    if (cat.contains('park')) return Icons.park;
    if (cat.contains('shop')) return Icons.shopping_bag;
    if (cat.contains('hospital')) return Icons.local_hospital;
    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    // Get city theme from MainScreen
    final cityTheme = context.findAncestorStateOfType<MainScreenState>()?.cityTheme ?? CityTheme.defaultTheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // 1. Base map layer with translation overlay
          RepaintBoundary(
            child: WanderMap(
            key: _mapKey,
            initialCenter: _initialCenter,
            initialZoom: 15.0,
            language: _currentLanguage,
            showTranslationOverlay: _showTranslationOverlay,
            showVoiceButton: false, // We use custom Voice FAB
            cityTheme: cityTheme,
            onPOITap: _handlePOITap,
            // Fix-2: 点击空白处收回 POI Bottom Sheet 和搜索结果
            onMapTap: (latLng) {
              if (_showPOISheet || _showRoutePanel || _showSearchResults) {
                setState(() {
                  _showPOISheet = false;
                  _showSearchResults = false;  // 关闭搜索结果列表
                  // Route Panel 不收（用户可能还需要）
                });
              }
            },
            // Fix-7.D: 监听地图移动以更新缩放级别和中心点
            onCameraMove: (pos) {
              _currentZoom = pos.zoom;
              _currentCenter = pos.target;
              Sentry.addBreadcrumb(Breadcrumb(
                category: 'poi',
                message: 'map_camera_move',
                data: {
                  'lat': pos.target.latitude,
                  'lng': pos.target.longitude,
                  'zoom': pos.zoom,
                },
              ));
            },
          ),
          ), // RepaintBoundary

          // 2. Top UI controls — 固定在顶部，不占满全屏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  MapSearchBar(
                    controller: _searchController,
                    onTap: _handleSearchTap,
                    onSearch: _handleSearch,
                    theme: cityTheme,
                    onClear: () {
                      // 清除搜索结果列表
                      setState(() {
                        _showSearchResults = false;
                        _searchResults = [];
                      });
                    },
                  ),

                  // Language switcher + overlay toggle
                  LanguageSwitcher(
                    selectedLanguage: _currentLanguage,
                    onLanguageChanged: _handleLanguageChanged,
                    overlayEnabled: _showTranslationOverlay,
                    onOverlayToggle: _handleOverlayToggle,
                    theme: cityTheme,
                  ),
                ],
              ),
            ),
          ),

          // 2.5. Search Results Dropdown
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: 100,  // 搜索框 + 语言切换条下方
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, cityTheme.pillActiveColor, 0.05)!.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final poi = _searchResults[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getCategoryIcon(poi.category.value),
                          color: cityTheme.pillActiveColor,
                          size: 20,
                        ),
                        title: Text(
                          poi.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: poi.address.isNotEmpty
                            ? Text(poi.address, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                            : null,
                        trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                        onTap: () {
                          // 选中后：移动地图 + 关闭列表
                          setState(() => _showSearchResults = false);
                          _mapKey.currentState?.moveTo(
                            LatLng(poi.latitude, poi.longitude),
                            zoom: 16.0,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          // 3. Map controls (right side)
          Positioned(
            right: 16,
            top: 140,
            child: SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  // GPS recenter button
                  FloatingActionButton.small(
                    heroTag: 'gps',
                    onPressed: () => _fetchCurrentLocation(),
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: cityTheme.pillActiveColor),
                  ),
                  const SizedBox(height: 12),

                  // Zoom in (Fix-7.D)
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      final newZoom = (_currentZoom + 1).clamp(3.0, 20.0);
                      _mapKey.currentState?.moveTo(
                        _currentCenter ?? _initialCenter,
                        zoom: newZoom,
                      );
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: AppColors.gray700),
                  ),
                  const SizedBox(height: 8),

                  // Zoom out (Fix-7.D)
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      final newZoom = (_currentZoom - 1).clamp(3.0, 20.0);
                      _mapKey.currentState?.moveTo(
                        _currentCenter ?? _initialCenter,
                        zoom: newZoom,
                      );
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: AppColors.gray700),
                  ),
                ],
              ),
            ),
          ),

          // 4. Voice Translation FAB
          VoiceFAB(
            onTap: _handleVoiceTap,
            onLongPress: _handleVoiceLongPress,
            onDirectionSwap: _handleDirectionSwap,
            fromLanguage: 'EN',
            toLanguage: '中',
            state: _voiceState,
            bottomOffset: 90.0,
          ),

          // Scenario 1: Clear Route Button
          if (_showRouteOnMap)
            Positioned(
              bottom: 100,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _clearRouteState,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Clear Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

          // Step 4.5: POI Bottom Sheet（点击 marker 后弹出）
          if (_showPOISheet && _selectedPOI != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: POIBottomSheet(
                poi: _selectedPOI!,
                language: _currentLanguage,
                onDirections: () => _requestRoutes(_selectedPOI!),
                onClose: () => setState(() => _showPOISheet = false),
                theme: cityTheme,
              ),
            ),

          // Step 4.5: Route Overview Panel（点击 Directions 后弹出）
          if (_showRoutePanel)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: RouteOverviewPanel(
                originName: _originName,
                destinationName: _selectedPOI != null ? _selectedPOI!.localizedName(_currentLanguage) : '',
                onEditOrigin: () => _showOriginPicker(),
                transitRoutes: _transitRoutes,
                walkingRoutes: _walkingRoutes,
                drivingRoutes: _drivingRoutes,
                isLoading: _isLoadingRoutes,
                onRouteSelected: _onRouteSelected,
                onClose: () => _clearRouteState(),
                theme: cityTheme,
              ),
            ),
        ],
      ),
    );
  }
}
