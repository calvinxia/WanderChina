import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';
import '../../widgets/map/wander_map.dart';
import '../../widgets/map/map_search_bar.dart';
import '../../widgets/map/language_switcher.dart';
import '../../widgets/map/voice_fab.dart';
import '../../widgets/map/poi_bottom_sheet.dart';
import '../../widgets/map/route_overview.dart';
import '../../models/poi_translation.dart';
import '../../core/theme/app_colors.dart';

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
      _MapWithTranslationScreenState();
}

class _MapWithTranslationScreenState extends State<MapWithTranslationScreen> {
  final GlobalKey<WanderMapState> _mapKey = GlobalKey<WanderMapState>();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  late AppLanguage _currentLanguage;
  bool _showTranslationOverlay = true;
  bool _showBottomSheet = false;
  bool _showRouteOverview = false;
  POITranslation? _selectedPOI;
  VoiceFABState _voiceState = VoiceFABState.idle;

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
  }

  @override
  void dispose() {
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
    // TODO: 打开搜索结果页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search functionality coming soon')),
    );
  }

  void _handleSearch(String query) {
    // TODO: 调用 search_poi 云函数
    debugPrint('Search: $query');
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

  void _handleVoiceTap() {
    // TODO: 打开全屏语音翻译页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening voice translation...')),
    );
  }

  void _handleVoiceLongPress() {
    // TODO: 就地录音翻译
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

  void _handleDirectionSwap() {
    // TODO: 交换翻译方向
    debugPrint('Swap direction');
  }

  void _handlePOITap(POITranslation poi) {
    setState(() {
      _selectedPOI = poi;
      _showBottomSheet = true;
    });
  }

  void _handleDirections() {
    setState(() {
      _showRouteOverview = true;
    });
  }

  void _handleDetails() {
    // Expand bottom sheet to full
    _sheetController.animateTo(
      0.8,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleCloseBottomSheet() {
    setState(() {
      _showBottomSheet = false;
      _selectedPOI = null;
    });
  }

  void _handleRouteSelected(RouteMode mode) {
    debugPrint('Selected route mode: $mode');
    // TODO: 在地图上显示路线
    setState(() {
      _showRouteOverview = false;
    });
  }

  void _handleRecenter() {
    _mapKey.currentState?.moveTo(_initialCenter, zoom: 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Base map layer with translation overlay
          WanderMap(
            key: _mapKey,
            initialCenter: _initialCenter,
            initialZoom: 15.0,
            language: _currentLanguage,
            showTranslationOverlay: _showTranslationOverlay,
            showVoiceButton: false, // We use custom Voice FAB
            onPOITap: _handlePOITap,
          ),

          // 2. Top UI controls
          SafeArea(
            child: Column(
              children: [
                // Search bar
                MapSearchBar(
                  onTap: _handleSearchTap,
                  onSearch: _handleSearch,
                ),

                // Language switcher + overlay toggle
                LanguageSwitcher(
                  selectedLanguage: _currentLanguage,
                  onLanguageChanged: _handleLanguageChanged,
                  overlayEnabled: _showTranslationOverlay,
                  onOverlayToggle: _handleOverlayToggle,
                ),
              ],
            ),
          ),

          // 3. Map controls (right side)
          SafeArea(
            child: Positioned(
              right: 16,
              top: 140,
              child: Column(
                children: [
                  // GPS recenter button
                  FloatingActionButton.small(
                    heroTag: 'gps',
                    onPressed: _handleRecenter,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: AppColors.jade500),
                  ),
                  const SizedBox(height: 12),

                  // Zoom in
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      // TODO: Implement zoom in
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: AppColors.gray700),
                  ),
                  const SizedBox(height: 8),

                  // Zoom out
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      // TODO: Implement zoom out
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

          // 5. Route Overview (if shown)
          if (_showRouteOverview)
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: RouteOverview(
                options: [
                  RouteOption(
                    mode: RouteMode.transit,
                    duration: '20 min',
                    cost: '¥3',
                  ),
                  RouteOption(
                    mode: RouteMode.walking,
                    duration: '35 min',
                  ),
                  RouteOption(
                    mode: RouteMode.driving,
                    duration: '12 min',
                    cost: '¥15',
                  ),
                ],
                selectedMode: null,
                onModeSelected: _handleRouteSelected,
              ),
            ),

          // 6. POI Bottom Sheet
          if (_showBottomSheet && _selectedPOI != null)
            POIBottomSheet(
              poi: _selectedPOI!,
              controller: _sheetController,
              onDirections: _handleDirections,
              onDetails: _handleDetails,
              onClose: _handleCloseBottomSheet,
            ),
        ],
      ),
    );
  }
}
