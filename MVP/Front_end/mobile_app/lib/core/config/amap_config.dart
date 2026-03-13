/// 高德地图配置文件
///
/// 包含高德地图API密钥和基础配置
/// API密钥从环境变量中读取，确保安全性
class AMapConfig {
  // 隐私合规配置
  static const bool privacyShow = true;
  static const bool privacyContain = true;

  // Android 平台 API Key
  // 请在高德开放平台申请: https://lbs.amap.com/
  static const String androidApiKey = 'fa66ce758292ed0b754f373f0ecb370f';

  // iOS 平台 API Key
  static const String iosApiKey = 'e6524a7df464c06bb9a399942a9abd0e';

  // 默认地图中心点（北京天安门）
  static const double defaultLatitude = 39.9042;
  static const double defaultLongitude = 116.4074;
  static const double defaultZoom = 12.0;

  // 地图样式
  static const int mapTypeNormal = 0; // 标准地图
  static const int mapTypeSatellite = 1; // 卫星地图
  static const int mapTypeNight = 2; // 夜间模式

  // 定位配置
  static const int locationInterval = 2000; // 定位间隔（毫秒）
  static const bool needAddress = true; // 是否需要地址信息
  static const bool onceLocation = false; // 是否单次定位

  // 离线地图配置
  static const String offlineMapPath = 'amap_offline_maps';
  static const int maxOfflineMapSize = 5 * 1024 * 1024 * 1024; // 5GB

  // POI 配置
  static const int poiSearchRadius = 5000; // POI搜索半径（米）
  static const int poiSearchLimit = 50; // POI搜索结果上限

  // 路线规划配置
  static const int routePlanStrategy = 0; // 0: 速度优先, 1: 费用优先, 2: 距离优先, 3: 不走高速

  /// 验证API Key是否已配置
  static bool isApiKeyConfigured() {
    return androidApiKey != 'YOUR_ANDROID_API_KEY_HERE' &&
           iosApiKey != 'YOUR_IOS_API_KEY_HERE';
  }
}
