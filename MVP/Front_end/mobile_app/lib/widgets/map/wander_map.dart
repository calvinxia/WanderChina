import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
import '../../models/poi_translation.dart';
import '../../services/api_client.dart';
import '../../core/config/backend_config.dart';
import 'voice_translation_overlay.dart';
import 'translation_overlay_widget.dart'; // 保留以导入 LabelStyle
import 'marker_badge_painter.dart';
import '../../core/theme/city_theme.dart';

class WanderMap extends StatefulWidget {
  final LatLng    initialCenter;
  final double    initialZoom;
  final AppLanguage language;
  final LabelStyle labelStyle; // 保留参数以兼容现有代码
  final bool      showTranslationOverlay;
  final bool      showVoiceButton;
  final CityTheme? cityTheme;
  final void Function(LatLng)?           onMapTap;
  final void Function(POITranslation)?   onPOITap;
  final void Function(CameraPosition)?   onCameraMove;

  const WanderMap({
    super.key,
    required this.initialCenter,
    this.initialZoom            = 15.0,
    this.language               = AppLanguage.english,
    this.labelStyle             = LabelStyle.badge, // 保留但不使用
    this.showTranslationOverlay = true,
    this.showVoiceButton        = true,
    this.cityTheme,
    this.onMapTap,
    this.onPOITap,
    this.onCameraMove,
  });

  @override
  State<WanderMap> createState() => WanderMapState();
}

class WanderMapState extends State<WanderMap> {
  AMapController?  _mapController;
  double           _currentZoom   = 15.0;
  LatLng           _currentCenter = const LatLng(39.9042, 116.4074);
  Timer?           _debounceTimer;

  // 搜索标记（用户搜索结果）
  final Set<Marker> _searchMarkers = {};
  // 翻译标记（蒙层 POI）
  Set<Marker>       _translationMarkers = {};
  // 路线 polylines（Step 1.1）
  Set<Polyline>     _routePolylines = {};
  // 缓存已获取的翻译 POI（避免重复请求）
  final Map<String, POITranslation> _poiCache = {};
  // badge 图片缓存: key = poi_id, value = PNG bytes
  final Map<String, Uint8List> _badgeCache = {};

  // 自定义地图样式数据
  Uint8List? _styleData;
  Uint8List? _styleExtraData;

  @override
  void initState() {
    super.initState();
    _loadCustomMapStyle();
  }

  @override
  void didUpdateWidget(WanderMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      _badgeCache.clear(); // 清缓存，下次 _fetchAndBuildMarkers 会重新渲染
      _scheduleOverlayUpdate();
    }
  }

  /// 加载自定义地图样式文件
  Future<void> _loadCustomMapStyle() async {
    try {
      final styleData = await rootBundle.load('assets/map/style.data');
      final styleExtraData = await rootBundle.load('assets/map/style_extra.data');
      if (mounted) {
        setState(() {
          _styleData = styleData.buffer.asUint8List();
          _styleExtraData = styleExtraData.buffer.asUint8List();
        });
      }
    } catch (e) {
      debugPrint('⚠️ 加载自定义地图样式失败: $e');
    }
  }

  // ─── 公开接口 ─────────────────────────────────────────

  Future<void> moveTo(LatLng target, {double? zoom}) async {
    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom ?? _currentZoom),
      ),
      animated: true,
    );
  }

  void addSearchMarker(POITranslation poi) {
    setState(() {
      _searchMarkers.add(Marker(
        position: poi.coordinates,
        infoWindow: InfoWindow(
          title:   poi.localizedName(widget.language),
          snippet: poi.nameZh,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    });
  }

  void clearSearchMarkers() => setState(() => _searchMarkers.clear());

  // Step 1.2: 路线绘制方法
  /// 在地图上绘制路线
  void showRoute(List<LatLng> points, {Color color = const Color(0xFF1FB368), double width = 6.0}) {
    if (points.isEmpty) return;  // 空 polyline 不画线
    setState(() {
      _routePolylines = {
        Polyline(
          points: points,
          color: color,
          width: width,
          capType: CapType.round,
          joinType: JoinType.round,
        ),
      };
    });
  }

  /// 清除路线
  void clearRoute() {
    setState(() {
      _routePolylines.clear();
    });
  }

  /// 显示路线 + 起终点 Marker
  void showRouteWithMarkers(List<LatLng> points, LatLng origin, LatLng destination) {
    // 画线
    showRoute(points);

    // 起点绿色 marker
    _searchMarkers.add(Marker(
      position: origin,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    // 终点红色 marker
    _searchMarkers.add(Marker(
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    setState(() {});

    // 移动地图让路线可见（移动到中点）
    final midLat = (origin.latitude + destination.latitude) / 2;
    final midLng = (origin.longitude + destination.longitude) / 2;
    moveTo(LatLng(midLat, midLng), zoom: 13);
  }

  // ─── 地图事件 ─────────────────────────────────────────

  void _onMapCreated(AMapController ctrl) {
    _mapController = ctrl;
    _scheduleOverlayUpdate();
  }

  void _onCameraMove(CameraPosition pos) {
    _currentZoom   = pos.zoom;
    _currentCenter = pos.target;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _scheduleOverlayUpdate);
    widget.onCameraMove?.call(pos);
  }

  Future<void> _scheduleOverlayUpdate() async {
    if (!widget.showTranslationOverlay) return;
    if (_currentZoom < 13.5) {
      if (_translationMarkers.isNotEmpty) {
        setState(() => _translationMarkers = {});
      }
      return;
    }
    await _fetchAndBuildMarkers();
  }

  // ─── 核心：获取 POI + 生成 Marker ────────────────────

  Future<void> _fetchAndBuildMarkers() async {
    try {
      final radius = _estimateRadius(_currentZoom);
      final langStr = widget.language == AppLanguage.french ? 'fr'
          : widget.language == AppLanguage.spanish ? 'es' : 'en';

      // 1. 调用 get_nearby_pois 云函数
      final result = await ApiClient.post(BackendConfig.nearbyUrl, {
        'latitude':  _currentCenter.latitude,
        'longitude': _currentCenter.longitude,
        'radius':    radius,
        'lang':      langStr,
        'limit':     30,
      });

      final pois = (result['pois'] as List?) ?? [];

      // 2. 解析 + 缓存
      final translations = <POITranslation>[];
      for (final p in pois) {
        final poiId = p['poi_id'] as String? ?? '';
        if (poiId.isEmpty) continue;

        final trans = POITranslation(
          gaodePoiId:  poiId,
          nameZh:      p['name_zh'] as String? ?? '',
          nameEn:      p['name_translated'] as String? ?? '',
          categoryEn:  p['category'] as String?,
          city:        '',
          coordinates: LatLng(
            (p['lat'] as num).toDouble(),
            (p['lng'] as num).toDouble(),
          ),
          source:   TranslationSource.database,
          cachedAt: DateTime.now(),
        );

        // 只保留有翻译的
        if (trans.nameEn.isNotEmpty) {
          translations.add(trans);
          _poiCache[poiId] = trans;
        }
      }

      // 3. 优先级排序 + 根据缩放级别取前 N 个
      translations.sort((a, b) {
        final aPri = _isHighPriority(a.categoryEn) ? 1 : 0;
        final bPri = _isHighPriority(b.categoryEn) ? 1 : 0;
        return bPri.compareTo(aPri);
      });
      final limit = _getMarkerLimit(_currentZoom);
      final topPOIs = translations.take(limit * 2).toList(); // 取2倍，过滤后大约剩limit个

      // 3.5. 应用最小间距过滤
      final filteredPOIs = _filterByMinDistance(topPOIs).take(limit).toList();

      // 4. 异步生成 Badge Marker（并行渲染所有 badge）
      final markers = <Marker>{};

      // 并行渲染所有 badge（比逐个等快）
      final futures = filteredPOIs.map((poi) => _buildTranslationMarker(poi));
      final markerList = await Future.wait(futures);
      markers.addAll(markerList);

      if (mounted) {
        setState(() => _translationMarkers = markers);
      }
    } catch (e) {
      debugPrint('⚠️ 获取翻译 POI 失败: $e');
    }
  }

  /// 为 POI 生成自定义 badge marker
  Future<Marker> _buildTranslationMarker(POITranslation poi) async {
    final isHigh = _isHighPriority(poi.categoryEn);

    // 检查缓存
    Uint8List? badgeBytes = _badgeCache[poi.gaodePoiId];

    if (badgeBytes == null) {
      // 获取设备像素密度
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final theme = widget.cityTheme ?? CityTheme.defaultTheme;

      badgeBytes = await MarkerBadgePainter.renderBadge(
        textEn: poi.localizedName(widget.language),
        textZh: poi.nameZh,
        isHighPriority: isHigh,
        devicePixelRatio: dpr,
        theme: theme,
      );

      _badgeCache[poi.gaodePoiId] = badgeBytes;
    }

    return Marker(
      position: poi.coordinates,
      icon: BitmapDescriptor.fromBytes(badgeBytes),
      infoWindow: InfoWindow.noText,
      onTap: (markerId) {
        final tappedPOI = _poiCache[poi.gaodePoiId];
        if (tappedPOI != null) {
          widget.onPOITap?.call(tappedPOI);
        }
      },
    );
  }

  bool _isHighPriority(String? cat) => const [
    'Attraction', 'Museum', 'Park', 'Metro Station', 'Transport Hub',
    '风景名胜', '旅游景点', '交通设施服务',
  ].contains(cat);

  /// 根据缩放级别估算搜索半径
  int _estimateRadius(double zoom) {
    if (zoom >= 16) return 500;
    if (zoom >= 15) return 1000;
    if (zoom >= 14) return 2000;
    return 3000;
  }

  /// 根据缩放级别决定显示的 marker 数量
  int _getMarkerLimit(double zoom) {
    if (zoom >= 17) return 15;  // 街道级：多显示
    if (zoom >= 16) return 10;  // zoom 16: 8-10个
    if (zoom >= 15) return 8;   // zoom 15: 8-10个
    if (zoom >= 13) return 8;   // 城区级：只显示重要的
    return 5;                    // 城市级：只显示地标
  }

  /// 按最小间距过滤 POI (Haversine公式)
  /// 两个POI坐标距离 < 50m 只保留 priority_score 高的
  List<POITranslation> _filterByMinDistance(List<POITranslation> pois, {double minDistanceMeters = 50}) {
    final filtered = <POITranslation>[];

    for (final poi in pois) {
      bool tooClose = false;
      for (final existing in filtered) {
        final distance = _calculateDistance(
          poi.coordinates.latitude,
          poi.coordinates.longitude,
          existing.coordinates.latitude,
          existing.coordinates.longitude,
        );
        if (distance < minDistanceMeters) {
          // 如果当前POI是高优先级，移除已存在的低优先级POI
          if (_isHighPriority(poi.categoryEn) && !_isHighPriority(existing.categoryEn)) {
            filtered.remove(existing);
            break;
          }
          tooClose = true;
          break;
        }
      }
      if (!tooClose) {
        filtered.add(poi);
      }
    }

    return filtered;
  }

  /// Haversine公式计算两点间距离（米）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // 地球半径（米）
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  // ─── build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 高德底图 + 翻译 Marker + 搜索 Marker
        AMapWidget(
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter,
            zoom:   widget.initialZoom,
          ),
          onMapCreated: _onMapCreated,
          onCameraMove: _onCameraMove,
          onTap:        (ll) => widget.onMapTap?.call(ll),
          markers:      {..._translationMarkers, ..._searchMarkers},
          polylines:    _routePolylines, // Step 1.3: 传入 polylines
          rotateGesturesEnabled: false,
          compassEnabled:        true,
          myLocationStyleOptions: MyLocationStyleOptions(
            true,
            // 注：高德原生 SDK 的定位蓝点 InfoWindow 文字无法直接改为英文
            // MyLocationStyleOptions 只有 enabled 参数，无法禁用 InfoWindow
          ),
          // 自定义地图样式
          customStyleOptions: _styleData != null && _styleExtraData != null
              ? CustomStyleOptions(
                  true,
                  styleData: _styleData,
                  styleExtraData: _styleExtraData,
                )
              : null,
        ),

        // 2. 语音翻译按钮
        if (widget.showVoiceButton)
          VoiceTranslationOverlay(language: widget.language),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // 不调用 _mapController?.dispose()，SDK 3.0.0 没有这个方法
    super.dispose();
  }
}
