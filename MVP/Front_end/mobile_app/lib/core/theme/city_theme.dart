import 'package:flutter/material.dart';

class CityTheme {
  final String cityKey;
  final String cityName;
  final String cityNameZh;
  final LinearGradient backgroundGradient;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color locationTextColor;
  final Color navTitleColor;
  final Color badgeBackground;
  final Color badgeTextColor;
  final Color iconBackground;
  final Color pillActiveColor;
  final String silhouetteSvg; // SVG path data for CustomPainter

  const CityTheme({
    required this.cityKey,
    required this.cityName,
    required this.cityNameZh,
    required this.backgroundGradient,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.locationTextColor,
    required this.navTitleColor,
    required this.badgeBackground,
    required this.badgeTextColor,
    required this.iconBackground,
    required this.pillActiveColor,
    required this.silhouetteSvg,
  });

  static const guangzhou = CityTheme(
    cityKey: 'GZ',
    cityName: 'Guangzhou, China',
    cityNameZh: '广州',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFDF3E0), Color(0xFFF5DEB3), Color(0xFFE8C87A)],
    ),
    primaryTextColor: Color(0xFF5A3E0A),
    secondaryTextColor: Color(0xFF8B6914),
    locationTextColor: Color(0xFFA07020),
    navTitleColor: Color(0xFF5A3E0A),
    badgeBackground: Color(0x33E8A838),
    badgeTextColor: Color(0xFF8B6914),
    iconBackground: Color(0x26E8A838),
    pillActiveColor: Color(0xFFE8A838),
    silhouetteSvg: 'guangzhou',
  );

  static const beijing = CityTheme(
    cityKey: 'BJ',
    cityName: 'Beijing, China',
    cityNameZh: '北京',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFDE8E8), Color(0xFFF5C4C4), Color(0xFFE8A0A0)],
    ),
    primaryTextColor: Color(0xFF5A0A15),
    secondaryTextColor: Color(0xFF991830),
    locationTextColor: Color(0xFFA02030),
    navTitleColor: Color(0xFF5A0A15),
    badgeBackground: Color(0x26C41E3A),
    badgeTextColor: Color(0xFF991830),
    iconBackground: Color(0x1AC41E3A),
    pillActiveColor: Color(0xFFC41E3A),
    silhouetteSvg: 'beijing',
  );

  static const shanghai = CityTheme(
    cityKey: 'SH',
    cityName: 'Shanghai, China',
    cityNameZh: '上海',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE8EDF5), Color(0xFFC8D4E8), Color(0xFFA0B4D4)],
    ),
    primaryTextColor: Color(0xFF1A2440),
    secondaryTextColor: Color(0xFF2C3E6B),
    locationTextColor: Color(0xFF3A507A),
    navTitleColor: Color(0xFF1A2440),
    badgeBackground: Color(0x262C3E6B),
    badgeTextColor: Color(0xFF2C3E6B),
    iconBackground: Color(0x1A2C3E6B),
    pillActiveColor: Color(0xFF2C3E6B),
    silhouetteSvg: 'shanghai',
  );

  static const shenzhen = CityTheme(
    cityKey: 'SZ',
    cityName: 'Shenzhen, China',
    cityNameZh: '深圳',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE0F0FA), Color(0xFFB0D4F0), Color(0xFF80B8E0)],
    ),
    primaryTextColor: Color(0xFF003366),
    secondaryTextColor: Color(0xFF0066AA),
    locationTextColor: Color(0xFF005599),
    navTitleColor: Color(0xFF003366),
    badgeBackground: Color(0x1F0077CC),
    badgeTextColor: Color(0xFF0066AA),
    iconBackground: Color(0x1A0077CC),
    pillActiveColor: Color(0xFF0077CC),
    silhouetteSvg: 'shenzhen',
  );

  static const chengdu = CityTheme(
    cityKey: 'CD',
    cityName: 'Chengdu, China',
    cityNameZh: '成都',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEEF5E6), Color(0xFFD0E4B0), Color(0xFFB0D080)],
    ),
    primaryTextColor: Color(0xFF1A3A10),
    secondaryTextColor: Color(0xFF3A6820),
    locationTextColor: Color(0xFF467030),
    navTitleColor: Color(0xFF1A3A10),
    badgeBackground: Color(0x265B8C3E),
    badgeTextColor: Color(0xFF3A6820),
    iconBackground: Color(0x1A5B8C3E),
    pillActiveColor: Color(0xFF5B8C3E),
    silhouetteSvg: 'chengdu',
  );

  static const xian = CityTheme(
    cityKey: 'XA',
    cityName: "Xi'an, China",
    cityNameZh: '西安',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF5EDDA), Color(0xFFE0D0A8), Color(0xFFC8B480)],
    ),
    primaryTextColor: Color(0xFF3A2A08),
    secondaryTextColor: Color(0xFF6B510F),
    locationTextColor: Color(0xFF7A6020),
    navTitleColor: Color(0xFF3A2A08),
    badgeBackground: Color(0x268B6914),
    badgeTextColor: Color(0xFF6B510F),
    iconBackground: Color(0x1A8B6914),
    pillActiveColor: Color(0xFF8B6914),
    silhouetteSvg: 'xian',
  );

  /// Default theme (used when not in any supported city)
  static const defaultTheme = guangzhou;

  /// Get theme by city key
  static CityTheme fromCityKey(String key) {
    switch (key.toUpperCase()) {
      case 'BJ': return beijing;
      case 'SH': return shanghai;
      case 'GZ': return guangzhou;
      case 'SZ': return shenzhen;
      case 'CD': return chengdu;
      case 'XA': return xian;
      default: return defaultTheme;
    }
  }

  /// Get city key from GPS coordinates. Returns null if not in any supported city.
  static String? keyFromCoordinates(double lat, double lng) {
    if (lat > 39.4 && lat < 40.4 && lng > 115.7 && lng < 117.0) return 'BJ';
    if (lat > 30.8 && lat < 31.8 && lng > 120.8 && lng < 122.0) return 'SH';
    if (lat > 22.5 && lat < 23.6 && lng > 112.9 && lng < 114.0) return 'GZ';
    if (lat > 22.3 && lat < 22.9 && lng > 113.7 && lng < 114.5) return 'SZ';
    if (lat > 30.0 && lat < 31.0 && lng > 103.5 && lng < 104.8) return 'CD';
    if (lat > 33.8 && lat < 34.6 && lng > 108.5 && lng < 109.5) return 'XA';
    return null;
  }

  /// Get theme from GPS coordinates
  static CityTheme fromCoordinates(double lat, double lng) {
    final key = keyFromCoordinates(lat, lng);
    return key != null ? fromCityKey(key) : defaultTheme;
  }
}
