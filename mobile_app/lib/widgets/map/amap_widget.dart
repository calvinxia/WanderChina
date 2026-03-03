import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../../core/config/amap_config.dart';
import '../../core/theme/app_colors.dart';

/// 高德地图组件
///
/// 封装了高德地图的基础功能，包括：
/// - 地图显示
/// - 缩放控制
/// - 平移手势
/// - 地图类型切换
/// - 自定义标记
class AMapWidget extends StatefulWidget {
  /// 初始中心点纬度
  final double? initialLatitude;

  /// 初始中心点经度
  final double? initialLongitude;

  /// 初始缩放级别（3-20）
  final double? initialZoom;

  /// 地图类型
  final int? mapType;

  /// 是否显示指南针
  final bool showCompass;

  /// 是否显示比例尺
  final bool showScaleControl;

  /// 是否显示缩放按钮
  final bool showZoomControl;

  /// 是否显示定位按钮
  final bool showMyLocationButton;

  /// 是否启用手势
  final bool gesturesEnabled;

  /// 是否启用旋转手势
  final bool rotateGesturesEnabled;

  /// 是否启用倾斜手势
  final bool tiltGesturesEnabled;

  /// 是否显示交通路况
  final bool showTraffic;

  /// 是否显示建筑物
  final bool showBuildings;

  /// 标记列表
  final Set<Marker>? markers;

  /// 折线列表
  final Set<Polyline>? polylines;

  /// 多边形列表
  final Set<Polygon>? polygons;

  /// 地图创建回调
  final Function(AMapController)? onMapCreated;

  /// 相机移动回调
  final Function(CameraPosition)? onCameraMove;

  /// 相机移动结束回调
  final Function(CameraPosition)? onCameraIdle;

  /// 地图点击回调
  final Function(LatLng)? onMapTap;

  /// 标记点击回调
  final Function(String)? onMarkerTap;

  const AMapWidget({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZoom,
    this.mapType,
    this.showCompass = true,
    this.showScaleControl = true,
    this.showZoomControl = true,
    this.showMyLocationButton = true,
    this.gesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.showTraffic = false,
    this.showBuildings = true,
    this.markers,
    this.polylines,
    this.polygons,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onMapTap,
    this.onMarkerTap,
  }) : super(key: key);

  @override
  State<AMapWidget> createState() => _AMapWidgetState();
}

class _AMapWidgetState extends State<AMapWidget> {
  AMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    // 配置地图初始参数
    final CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(
        widget.initialLatitude ?? AMapConfig.defaultLatitude,
        widget.initialLongitude ?? AMapConfig.defaultLongitude,
      ),
      zoom: widget.initialZoom ?? AMapConfig.defaultZoom,
    );

    return AMapWidget(
      apiKey: AMapApiKey(
        androidKey: AMapConfig.androidApiKey,
        iosKey: AMapConfig.iosApiKey,
      ),
      initialCameraPosition: initialCameraPosition,
      mapType: _getMapType(),
      buildingsEnabled: widget.showBuildings,
      compassEnabled: widget.showCompass,
      scaleEnabled: widget.showScaleControl,
      zoomControlsEnabled: widget.showZoomControl,
      myLocationButtonEnabled: widget.showMyLocationButton,
      scrollGesturesEnabled: widget.gesturesEnabled,
      zoomGesturesEnabled: widget.gesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      trafficEnabled: widget.showTraffic,
      markers: widget.markers ?? {},
      polylines: widget.polylines ?? {},
      polygons: widget.polygons ?? {},
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      onTap: widget.onMapTap,
      onMarkerTap: (markerId) {
        widget.onMarkerTap?.call(markerId);
      },
    );
  }

  /// 获取地图类型
  MapType _getMapType() {
    switch (widget.mapType) {
      case AMapConfig.mapTypeSatellite:
        return MapType.satellite;
      case AMapConfig.mapTypeNight:
        return MapType.night;
      default:
        return MapType.normal;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

/// 地图控制器扩展
///
/// 提供便捷的地图操作方法
extension AMapControllerExtension on AMapController {
  /// 移动到指定位置
  Future<void> moveToLocation(
    double latitude,
    double longitude, {
    double? zoom,
    bool animated = true,
  }) async {
    final cameraPosition = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom ?? AMapConfig.defaultZoom,
    );

    if (animated) {
      await moveCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
        animated: true,
        duration: 500,
      );
    } else {
      await moveCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  /// 缩放到指定级别
  Future<void> zoomTo(double zoom, {bool animated = true}) async {
    await moveCamera(
      CameraUpdate.zoomTo(zoom),
      animated: animated,
      duration: 300,
    );
  }

  /// 放大一级
  Future<void> zoomIn() async {
    await moveCamera(
      CameraUpdate.zoomIn(),
      animated: true,
      duration: 200,
    );
  }

  /// 缩小一级
  Future<void> zoomOut() async {
    await moveCamera(
      CameraUpdate.zoomOut(),
      animated: true,
      duration: 200,
    );
  }

  /// 显示指定区域
  Future<void> showBounds(
    LatLngBounds bounds, {
    double padding = 50,
  }) async {
    await moveCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
      animated: true,
      duration: 500,
    );
  }
}
