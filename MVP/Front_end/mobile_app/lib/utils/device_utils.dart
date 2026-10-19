import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 读取或生成 device_id（32 位十六进制随机串，持久化到 SharedPreferences）。
/// key 固定为 'device_id'，三处调用方均使用此函数。
Future<String> getOrCreateDeviceId(SharedPreferences prefs) async {
  String? deviceId = prefs.getString('device_id');
  if (deviceId == null) {
    final random = Random.secure();
    deviceId = List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
    await prefs.setString('device_id', deviceId);
  }
  return deviceId;
}
