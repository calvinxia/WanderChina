import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/config/amap_config.dart';

/// 离线地图城市信息
class OfflineCity {
  final String cityCode;
  final String cityName;
  final String provinceName;
  final int size; // 文件大小（字节）
  final bool isDownloaded;
  final double downloadProgress; // 0.0 - 1.0
  final DateTime? lastUpdated;

  OfflineCity({
    required this.cityCode,
    required this.cityName,
    required this.provinceName,
    required this.size,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
    this.lastUpdated,
  });

  /// 获取格式化的文件大小
  String get formattedSize {
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 复制对象并更新部分字段
  OfflineCity copyWith({
    bool? isDownloaded,
    double? downloadProgress,
    DateTime? lastUpdated,
  }) {
    return OfflineCity(
      cityCode: cityCode,
      cityName: cityName,
      provinceName: provinceName,
      size: size,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 离线地图管理服务
///
/// 提供离线地图的下载、更新、删除等功能
class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  // 下载中的城市列表
  final Map<String, OfflineCity> _downloadingCities = {};

  // 已下载的城市列表
  final Map<String, OfflineCity> _downloadedCities = {};

  /// 获取所有可用城市列表
  Future<List<OfflineCity>> getAvailableCities() async {
    // 实际使用时需要调用高德API获取城市列表
    // 这里返回模拟数据
    return [
      OfflineCity(
        cityCode: '110100',
        cityName: '北京',
        provinceName: '北京市',
        size: 250 * 1024 * 1024,
        isDownloaded: _downloadedCities.containsKey('110100'),
      ),
      OfflineCity(
        cityCode: '310100',
        cityName: '上海',
        provinceName: '上海市',
        size: 200 * 1024 * 1024,
        isDownloaded: _downloadedCities.containsKey('310100'),
      ),
      OfflineCity(
        cityCode: '440100',
        cityName: '广州',
        provinceName: '广东省',
        size: 180 * 1024 * 1024,
        isDownloaded: _downloadedCities.containsKey('440100'),
      ),
      OfflineCity(
        cityCode: '440300',
        cityName: '深圳',
        provinceName: '广东省',
        size: 150 * 1024 * 1024,
        isDownloaded: _downloadedCities.containsKey('440300'),
      ),
      OfflineCity(
        cityCode: '510100',
        cityName: '成都',
        provinceName: '四川省',
        size: 170 * 1024 * 1024,
        isDownloaded: _downloadedCities.containsKey('510100'),
      ),
      OfflineCity(
        cityCode: '330100',
        cityName: '杭州',
        provinceName: '浙江省',
        size: 140 * 1024 * 1024,
        isDownloaded: _downloadedCities.containsKey('330100'),
      ),
      OfflineCity(
        cityCode: '610100',
        cityName: '西安',
        provinceName: '陕西省',
        size: 160 * 1024 * 1024,
        isDownloaded: _downloadedCities.containsKey('610100'),
      ),
    ];
  }

  /// 获取已下载的城市列表
  List<OfflineCity> getDownloadedCities() {
    return _downloadedCities.values.toList();
  }

  /// 开始下载城市地图
  ///
  /// [cityCode] 城市代码
  /// [onProgress] 下载进度回调
  Future<bool> downloadCity(
    String cityCode, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // 检查是否已在下载中
      if (_downloadingCities.containsKey(cityCode)) {
        debugPrint('⚠️ 城市 $cityCode 正在下载中');
        return false;
      }

      // 获取城市信息
      final cities = await getAvailableCities();
      final city = cities.firstWhere(
        (c) => c.cityCode == cityCode,
        orElse: () => throw Exception('城市不存在'),
      );

      // 检查存储空间
      final hasSpace = await _checkStorageSpace(city.size);
      if (!hasSpace) {
        throw Exception('存储空间不足');
      }

      // 标记为下载中
      _downloadingCities[cityCode] = city;

      // 模拟下载过程（实际使用时调用高德API）
      await _simulateDownload(cityCode, city, onProgress);

      // 下载完成
      _downloadingCities.remove(cityCode);
      _downloadedCities[cityCode] = city.copyWith(
        isDownloaded: true,
        downloadProgress: 1.0,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ 城市地图下载完成: ${city.cityName}');
      return true;

    } catch (e) {
      debugPrint('❌ 下载城市地图失败: $e');
      _downloadingCities.remove(cityCode);
      return false;
    }
  }

  /// 暂停下载
  Future<void> pauseDownload(String cityCode) async {
    // 实现下载暂停逻辑
    _downloadingCities.remove(cityCode);
  }

  /// 删除已下载的城市地图
  Future<bool> deleteCity(String cityCode) async {
    try {
      if (!_downloadedCities.containsKey(cityCode)) {
        return false;
      }

      // 实际使用时需要删除本地文件
      // final directory = await _getOfflineMapDirectory();
      // await File('${directory.path}/$cityCode.map').delete();

      _downloadedCities.remove(cityCode);
      debugPrint('✅ 删除城市地图成功: $cityCode');
      return true;

    } catch (e) {
      debugPrint('❌ 删除城市地图失败: $e');
      return false;
    }
  }

  /// 获取已下载地图总大小
  Future<int> getTotalDownloadedSize() async {
    int total = 0;
    for (var city in _downloadedCities.values) {
      total += city.size;
    }
    return total;
  }

  /// 检查是否有更新
  Future<List<OfflineCity>> checkForUpdates() async {
    // 实际使用时调用API检查更新
    return [];
  }

  /// 更新城市地图
  Future<bool> updateCity(String cityCode) async {
    // 先删除旧版本
    await deleteCity(cityCode);
    // 重新下载
    return await downloadCity(cityCode);
  }

  /// 检查存储空间是否足够
  Future<bool> _checkStorageSpace(int requiredSize) async {
    try {
      // ignore: unused_local_variable
      final directory = await getApplicationDocumentsDirectory();

      // 简化的检查逻辑（实际需要获取可用空间）
      final totalSize = await getTotalDownloadedSize();

      return (totalSize + requiredSize) <= AMapConfig.maxOfflineMapSize;
    } catch (e) {
      return false;
    }
  }

  /// 获取离线地图存储目录
  // ignore: unused_element
  Future<Directory> _getOfflineMapDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapDir = Directory('${appDir.path}/${AMapConfig.offlineMapPath}');

    if (!await mapDir.exists()) {
      await mapDir.create(recursive: true);
    }

    return mapDir;
  }

  /// 模拟下载过程（仅用于演示）
  Future<void> _simulateDownload(
    String cityCode,
    OfflineCity city,
    Function(double)? onProgress,
  ) async {
    for (var i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      final progress = i / 100.0;

      // 更新下载进度
      _downloadingCities[cityCode] = city.copyWith(
        downloadProgress: progress,
      );

      onProgress?.call(progress);
    }
  }

  /// 清空所有下载
  Future<void> clearAllDownloads() async {
    final cities = _downloadedCities.keys.toList();
    for (var cityCode in cities) {
      await deleteCity(cityCode);
    }
  }
}
