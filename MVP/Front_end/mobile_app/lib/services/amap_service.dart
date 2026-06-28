import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../core/config/amap_config.dart';

// 仅在移动平台导入高德地图SDK
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';

/// 高德地图服务类
///
/// 提供地图初始化、定位、搜索等功能的统一接口
/// 注意：Web平台不支持高德地图SDK，相关功能将被禁用
class AMapService {
  static final AMapService _instance = AMapService._internal();
  factory AMapService() => _instance;
  AMapService._internal();

  // 定位插件实例
  dynamic _locationPlugin;

  // 是否已初始化
  bool _isInitialized = false;

  // 缓存的 broadcast stream，避免多次 listen 冲突
  Stream<Map<String, Object>>? _broadcastStream;

  /// 初始化高德地图SDK
  ///
  /// 必须在使用地图功能前调用
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Web平台跳过高德地图初始化
    if (kIsWeb) {
      _isInitialized = true;
      debugPrint('⚠️ Web平台不支持高德地图SDK，地图功能已禁用');
      return;
    }

    try {
      // 设置隐私合规
      AMapFlutterLocation.updatePrivacyShow(
        AMapConfig.privacyShow,
        AMapConfig.privacyContain,
      );

      AMapFlutterLocation.updatePrivacyAgree(true);

      // 设置API Key
      AMapFlutterLocation.setApiKey(
        AMapConfig.androidApiKey,
        AMapConfig.iosApiKey,
      );

      // 初始化定位插件
      _locationPlugin = AMapFlutterLocation();

      // 配置定位参数
      await _configureLocation();

      _isInitialized = true;
      debugPrint('✅ 高德地图SDK初始化成功');
    } catch (e) {
      debugPrint('❌ 高德地图SDK初始化失败: $e');
      // 不要抛出异常，允许应用继续运行
      _isInitialized = true;
    }
  }

  /// 配置定位参数
  Future<void> _configureLocation() async {
    if (kIsWeb || _locationPlugin == null) return;

    try {
      // Android 定位配置
      _locationPlugin.setLocationOption(
        AMapLocationOption(
          needAddress: AMapConfig.needAddress,
          onceLocation: AMapConfig.onceLocation,
          locationInterval: AMapConfig.locationInterval,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ 配置定位参数失败: $e');
    }
  }

  /// 开始定位
  ///
  /// 返回定位信息流
  Stream<Map<String, Object>>? startLocation() {
    if (kIsWeb) {
      debugPrint('⚠️ Web平台不支持定位功能');
      return null;
    }

    if (!_isInitialized || _locationPlugin == null) {
      debugPrint('⚠️ 高德地图SDK未初始化');
      return null;
    }

    try {
      // 用缓存的 broadcast stream，避免重复 listen
      _broadcastStream ??= _locationPlugin.onLocationChanged().asBroadcastStream();
      _locationPlugin.startLocation();
      return _broadcastStream;
    } catch (e) {
      debugPrint('❌ 开始定位失败: $e');
      return null;
    }
  }

  /// 停止定位
  void stopLocation() {
    if (kIsWeb) return;
    try {
      _locationPlugin?.stopLocation();
    } catch (e) {
      debugPrint('⚠️ 停止定位失败: $e');
    }
  }

  /// 获取单次定位
  Future<Map<String, Object>?> getLocation() async {
    if (kIsWeb) {
      debugPrint('⚠️ Web平台不支持定位功能');
      return null;
    }

    if (!_isInitialized || _locationPlugin == null) {
      debugPrint('⚠️ 高德地图SDK未初始化');
      return null;
    }

    try {
      _locationPlugin.setLocationOption(
        AMapLocationOption(onceLocation: true, needAddress: true),
      );

      final completer = Completer<Map<String, Object>?>();
      late StreamSubscription sub;
      sub = _locationPlugin.onLocationChanged().listen(
        (loc) {
          debugPrint('🔬 onLocationChanged 推送了: errorCode=${loc['errorCode']} '
                     'lat=${loc['latitude']} lng=${loc['longitude']}');
          if (!completer.isCompleted) completer.complete(loc);
        },
        onError: (e) {
          if (!completer.isCompleted) completer.complete(null);
        },
      );
      _locationPlugin.startLocation();

      final location = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      await sub.cancel();
      return location;
    } catch (e) {
      debugPrint('❌ 获取定位失败: $e');
      return null;
    }
  }

  /// 销毁定位资源
  void dispose() {
    if (kIsWeb) return;
    try {
      stopLocation();
      _locationPlugin?.destroy();
      _locationPlugin = null;
      _broadcastStream = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('⚠️ 销毁定位资源失败: $e');
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取定位插件实例
  dynamic get locationPlugin => _locationPlugin;
}
