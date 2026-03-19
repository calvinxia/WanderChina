import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
import '../../models/poi_translation.dart';
import '../../services/api_client.dart';
import '../../core/config/backend_config.dart';
import 'voice_translation_overlay.dart';
import 'translation_overlay_widget.dart'; // 保留以导入 LabelStyle

class WanderMap extends StatefulWidget {
  final LatLng    initialCenter;
  final double    initialZoom;
  final AppLanguage language;
  final LabelStyle labelStyle; // 保留参数以兼容现有代码
  final bool      showTranslationOverlay;
  final bool      showVoiceButton;
  final void Function(LatLng)?         onMapTap;
  final void Function(POITranslation)? onPOITap;

  const WanderMap({
    super.key,
    required this.initialCenter,
    this.initialZoom            = 15.0,
    this.language               = AppLanguage.english,
    this.labelStyle             = LabelStyle.badge, // 保留但不使用
    this.showTranslationOverlay = true,
    this.showVoiceButton        = true,
    this.onMapTap,
    this.onPOITap,
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
  // 缓存已获取的翻译 POI（避免重复请求）
  final Map<String, POITranslation> _poiCache = {};

  // 自定义地图样式数据
  Uint8List? _styleData;
  Uint8List? _styleExtraData;

  @override
  void initState() {
    super.initState();
    _loadCustomMapStyle();
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

      // 3. 优先级排序 + 取前 12 个
      translations.sort((a, b) {
        final aPri = _isHighPriority(a.categoryEn) ? 1 : 0;
        final bPri = _isHighPriority(b.categoryEn) ? 1 : 0;
        return bPri.compareTo(aPri);
      });
      final topPOIs = translations.take(12).toList();

      // 4. 生成 Marker
      final markers = <Marker>{};
      for (final poi in topPOIs) {
        markers.add(_buildTranslationMarker(poi));
      }

      if (mounted) {
        setState(() => _translationMarkers = markers);
      }
    } catch (e) {
      debugPrint('⚠️ 获取翻译 POI 失败: $e');
    }
  }

  /// 为单个 POI 生成 Marker
  Marker _buildTranslationMarker(POITranslation poi) {
    final isHigh = _isHighPriority(poi.categoryEn);
    return Marker(
      position: poi.coordinates,
      infoWindow: InfoWindow(
        title:   poi.localizedName(widget.language),
        snippet: poi.nameZh,
      ),
      icon: isHigh
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      // Note: AMap SDK 3.0.0 的 Marker onTap 签名与我们的需求不匹配
      // 如需要点击事件，可以通过 AMapWidget 的全局 marker tap 事件处理
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
          rotateGesturesEnabled: false,
          compassEnabled:        true,
          myLocationStyleOptions: MyLocationStyleOptions(true),
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
