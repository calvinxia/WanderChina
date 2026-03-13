/// WanderChina 后端配置
/// 所有值通过 --dart-define-from-file=.env 编译时注入
/// Flutter 端不存储任何后端密钥
class BackendConfig {
  // ===== 云函数 URL =====
  static const String translateUrl = String.fromEnvironment('TRANSLATE_URL');
  static const String dbWriteUrl = String.fromEnvironment('DB_WRITE_URL');
  static const String nearbyUrl = String.fromEnvironment('NEARBY_URL');
  static const String authUrl = String.fromEnvironment('AUTH_URL');
  static const String tripUrl = String.fromEnvironment('TRIP_URL');
  static const String cosTokenUrl = String.fromEnvironment('COS_TOKEN_URL');
  static const String asrUrl = String.fromEnvironment('ASR_URL');
  static const String ttsUrl = String.fromEnvironment('TTS_URL');
  static const String searchUrl = String.fromEnvironment('SEARCH_URL');
  static const String routeUrl = String.fromEnvironment('ROUTE_URL');

  // ===== COS 公开信息 =====
  static const String cosStaticUrl = String.fromEnvironment('COS_STATIC_URL');
  static const String cosUserBucket = String.fromEnvironment('COS_USER_BUCKET');
  static const String cosRegion = String.fromEnvironment('COS_REGION');

  // ===== 高德地图（已有的 AMapConfig 保留，这里做备份引用）=====
  static const String amapKeyAndroid = String.fromEnvironment('AMAP_KEY_ANDROID');
  static const String amapKeyIos = String.fromEnvironment('AMAP_KEY_IOS');

  /// 检查必要配置是否已注入
  static bool get isConfigured =>
      translateUrl.isNotEmpty &&
      authUrl.isNotEmpty &&
      nearbyUrl.isNotEmpty &&
      searchUrl.isNotEmpty &&
      routeUrl.isNotEmpty;
}
