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

  /// 通用 POST 请求
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
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
