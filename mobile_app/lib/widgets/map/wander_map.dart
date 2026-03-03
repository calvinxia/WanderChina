import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../../models/poi_translation.dart';
import '../../services/map/poi_translation_service.dart';
import 'translation_overlay_widget.dart';
import 'voice_translation_overlay.dart';

class WanderMap extends StatefulWidget {
  final LatLng   initialCenter;
  final double   initialZoom;
  final AppLanguage language;
  final LabelStyle  labelStyle;
  final bool     showTranslationOverlay;
  final bool     showVoiceButton;
  final void Function(LatLng)?           onMapTap;
  final void Function(POITranslation)?   onPOITap;

  const WanderMap({
    super.key,
    required this.initialCenter,
    this.initialZoom             = 15.0,
    this.language                = AppLanguage.english,
    this.labelStyle              = LabelStyle.badge,
    this.showTranslationOverlay  = true,
    this.showVoiceButton         = true,
    this.onMapTap,
    this.onPOITap,
  });

  @override
  State<WanderMap> createState() => WanderMapState();
}

class WanderMapState extends State<WanderMap> {
  AMapController?              _mapController;
  final POITranslationService  _translationSvc = POITranslationService();

  double                      _currentZoom    = 15.0;
  List<Map<String, dynamic>>  _visiblePOIs    = [];
  final Set<Marker>            _customMarkers  = {};
  Timer?                       _debounceTimer;

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
      _customMarkers.add(Marker(
        position: poi.coordinates,
        infoWindow: InfoWindow(
          title:   poi.localizedName(widget.language),
          snippet: poi.nameZh,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    });
  }

  void clearSearchMarkers() => setState(() => _customMarkers.clear());

  // ─── 地图事件 ─────────────────────────────────────────

  void _onMapCreated(AMapController ctrl) {
    _mapController = ctrl;
    _scheduleOverlayUpdate();
  }

  void _onCameraMove(CameraPosition pos) {
    _currentZoom = pos.zoom;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _scheduleOverlayUpdate);
  }

  Future<void> _scheduleOverlayUpdate() async {
    if (!widget.showTranslationOverlay || _mapController == null) return;
    if (_currentZoom < 13.5) {
      if (_visiblePOIs.isNotEmpty) setState(() => _visiblePOIs = []);
      return;
    }
    await _fetchVisiblePOIs();
  }

  Future<void> _fetchVisiblePOIs() async {
    try {
      final bounds = await _mapController!.getVisibleRegion();
      final centerLat = (bounds.northeast.latitude  + bounds.southwest.latitude)  / 2;
      final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
      final latDiff   = (bounds.northeast.latitude  - bounds.southwest.latitude).abs();
      final radius    = (latDiff * 111320 / 2).clamp(500, 3000).toInt();

      // Note: AMap POI search API may vary by SDK version
      // This is a placeholder - actual implementation depends on amap_flutter_map version
      // You may need to use AMapPOISearch or similar API

      // For now, create empty POI list as placeholder
      // TODO: Integrate with actual AMap POI search API
      final pois = <Map<String, dynamic>>[];

      await _translationSvc.translateRawPOIs(rawPOIs: pois);
      if (mounted) setState(() => _visiblePOIs = pois);
    } catch (e) {
      print('⚠️ 获取视窗POI失败: $e');
    }
  }

  String _extractCity(String cn) {
    for (final city in ['北京','上海','广州','深圳','成都','西安']) {
      if (cn.contains(city)) return city;
    }
    return '未知';
  }

  // ─── build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 高德底图
        AMapWidget(
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter,
            zoom:   widget.initialZoom,
          ),
          onMapCreated:          _onMapCreated,
          onCameraMove:          _onCameraMove,
          onTap:                 (ll) => widget.onMapTap?.call(ll),
          markers:               _customMarkers,
          rotateGesturesEnabled: false,
          compassEnabled:        true,
          myLocationStyleOptions: MyLocationStyleOptions(true),
        ),

        // 2. 翻译蒙层
        if (widget.showTranslationOverlay && _mapController != null)
          Positioned.fill(
            child: TranslationOverlay(
              mapController: _mapController!,
              visiblePOIs:   _visiblePOIs,
              currentZoom:   _currentZoom,
              config:        TranslationOverlayConfig(
                language:          widget.language,
                labelStyle:        widget.labelStyle,
                showCategory:      _currentZoom >= 15.5,
                minZoomToShow:     14.0,
                maxLabelsOnScreen: 12,
              ),
            ),
          ),

        // 3. 语音翻译按钮
        if (widget.showVoiceButton)
          VoiceTranslationOverlay(language: widget.language),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
