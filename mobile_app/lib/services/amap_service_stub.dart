/// 高德地图服务存根（Web平台）
///
/// 在Web平台上，高德地图SDK不可用，所有方法返回null或空实现
class AMapService {
  static final AMapService _instance = AMapService._internal();
  factory AMapService() => _instance;
  AMapService._internal();

  bool _isInitialized = false;

  /// 初始化（Web平台空实现）
  Future<void> initialize() async {
    _isInitialized = true;
    print('⚠️ Web平台不支持高德地图SDK');
  }

  /// 开始定位（Web平台返回null）
  Stream<Map<String, Object>>? startLocation() {
    print('⚠️ Web平台不支持定位功能');
    return null;
  }

  /// 停止定位（Web平台空实现）
  void stopLocation() {}

  /// 获取单次定位（Web平台返回null）
  Future<Map<String, Object>?> getLocation() async {
    print('⚠️ Web平台不支持定位功能');
    return null;
  }

  /// 销毁资源（Web平台空实现）
  void dispose() {}

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取定位插件（Web平台返回null）
  dynamic get locationPlugin => null;
}
