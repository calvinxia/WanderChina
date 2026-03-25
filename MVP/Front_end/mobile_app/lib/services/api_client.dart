// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/backend_config.dart';

class ApiClient {
  static String get translateUrl => BackendConfig.translateUrl;
  static String get dbWriteUrl => BackendConfig.dbWriteUrl;
  static String get nearbyUrl => BackendConfig.nearbyUrl;
  static String get authUrl => BackendConfig.authUrl;
  static String get tripUrl => BackendConfig.tripUrl;
  static String get cosTokenUrl => BackendConfig.cosTokenUrl;
  static String get asrUrl => BackendConfig.asrUrl;
  static String get ttsUrl => BackendConfig.ttsUrl;
  static String get searchUrl => BackendConfig.searchUrl;
  static String get routeUrl => BackendConfig.routeUrl;
  static String get generateItineraryUrl => BackendConfig.generateItineraryUrl;
  static String get poiPhotoUrl => BackendConfig.poiPhotoUrl;

  /// 通用 POST 请求
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: json.encode(body),
    ).timeout(timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 显式使用 UTF-8 解码，确保中文字符正确处理
      final responseBody = utf8.decode(response.bodyBytes);
      return json.decode(responseBody);
    }
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
