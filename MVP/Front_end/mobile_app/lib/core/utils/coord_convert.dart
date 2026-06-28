import 'dart:math';
import 'package:x_amap_base/x_amap_base.dart';

/// WGS-84(Geolocator/原始 GPS)→ GCJ-02(高德/火星坐标)
/// 中国境内使用;境外直接返回原坐标。
LatLng wgs84ToGcj02(double lat, double lng) {
  if (_outOfChina(lat, lng)) return LatLng(lat, lng);
  const double a = 6378245.0;
  const double ee = 0.00669342162296594323;
  double dLat = _transformLat(lng - 105.0, lat - 35.0);
  double dLng = _transformLng(lng - 105.0, lat - 35.0);
  final radLat = lat / 180.0 * pi;
  double magic = sin(radLat);
  magic = 1 - ee * magic * magic;
  final sqrtMagic = sqrt(magic);
  dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
  dLng = (dLng * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
  return LatLng(lat + dLat, lng + dLng);
}

bool _outOfChina(double lat, double lng) {
  return !(lng > 73.66 && lng < 135.05 && lat > 3.86 && lat < 53.55);
}

double _transformLat(double x, double y) {
  double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y +
      0.1 * x * y + 0.2 * sqrt(x.abs());
  ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
  ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
  ret += (160.0 * sin(y / 12.0 * pi) + 320.0 * sin(y * pi / 30.0)) * 2.0 / 3.0;
  return ret;
}

double _transformLng(double x, double y) {
  double ret = 300.0 + x + 2.0 * y + 0.1 * x * x +
      0.1 * x * y + 0.1 * sqrt(x.abs());
  ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
  ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
  ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
  return ret;
}
