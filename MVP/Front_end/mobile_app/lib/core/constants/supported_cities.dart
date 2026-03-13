/// 支持的城市列表
///
/// WanderChina仅支持以下6个主要城市的POI搜索和翻译
class SupportedCities {
  /// 支持的城市列表（中文名称）
  static const List<String> citiesZh = [
    '北京',
    '上海',
    '广州',
    '深圳',
    '成都',
    '西安',
  ];

  /// 支持的城市列表（英文名称）
  static const List<String> citiesEn = [
    'Beijing',
    'Shanghai',
    'Guangzhou',
    'Shenzhen',
    'Chengdu',
    "Xi'an",
  ];

  /// 城市中英文映射
  static const Map<String, String> cityTranslations = {
    '北京': 'Beijing',
    '上海': 'Shanghai',
    '广州': 'Guangzhou',
    '深圳': 'Shenzhen',
    '成都': 'Chengdu',
    '西安': "Xi'an",
  };

  /// 城市边界（用于快速判断POI是否在支持的城市内）
  static const Map<String, CityBounds> cityBounds = {
    '北京': CityBounds(
      minLat: 39.4,
      maxLat: 41.1,
      minLng: 115.4,
      maxLng: 117.5,
    ),
    '上海': CityBounds(
      minLat: 30.7,
      maxLat: 31.9,
      minLng: 120.9,
      maxLng: 122.0,
    ),
    '广州': CityBounds(
      minLat: 22.5,
      maxLat: 23.9,
      minLng: 112.9,
      maxLng: 114.0,
    ),
    '深圳': CityBounds(
      minLat: 22.4,
      maxLat: 22.9,
      minLng: 113.7,
      maxLng: 114.6,
    ),
    '成都': CityBounds(
      minLat: 30.1,
      maxLat: 31.4,
      minLng: 103.0,
      maxLng: 104.9,
    ),
    '西安': CityBounds(
      minLat: 33.7,
      maxLat: 34.8,
      minLng: 108.0,
      maxLng: 109.8,
    ),
  };

  /// 高德地图城市代码
  static const Map<String, String> cityAdCodes = {
    '北京': '110000',
    '上海': '310000',
    '广州': '440100',
    '深圳': '440300',
    '成都': '510100',
    '西安': '610100',
  };

  /// 检查坐标是否在支持的城市内
  static String? getCityFromCoordinates(double latitude, double longitude) {
    for (var entry in cityBounds.entries) {
      final bounds = entry.value;
      if (latitude >= bounds.minLat &&
          latitude <= bounds.maxLat &&
          longitude >= bounds.minLng &&
          longitude <= bounds.maxLng) {
        return entry.key;
      }
    }
    return null;
  }

  /// 检查城市名称是否在支持列表中
  static bool isCitySupported(String cityName) {
    return citiesZh.contains(cityName) ||
        citiesEn.any((en) => en.toLowerCase() == cityName.toLowerCase());
  }

  /// 获取城市的英文名称
  static String getCityNameEn(String cityZh) {
    return cityTranslations[cityZh] ?? cityZh;
  }

  /// 获取城市的中文名称
  static String? getCityNameZh(String cityEn) {
    for (var entry in cityTranslations.entries) {
      if (entry.value.toLowerCase() == cityEn.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  /// 获取城市的高德地图代码
  static String? getCityAdCode(String cityName) {
    return cityAdCodes[cityName];
  }

  /// 获取所有支持的城市（根据语言）
  static List<String> getCities(String language) {
    return language == 'en' ? citiesEn : citiesZh;
  }
}

/// 城市边界
class CityBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const CityBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  /// 检查坐标是否在边界内
  bool contains(double latitude, double longitude) {
    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }
}
