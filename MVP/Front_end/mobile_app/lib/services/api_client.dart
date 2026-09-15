// lib/services/api_client.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../core/config/backend_config.dart';
import 'app_event_bus.dart';

class ApiClient {
  // 并发 401 去重：首次收到 401 后置 true，后续相同错误不重复 fire 事件。
  // 重置时机：任何成功认证后调用 resetSessionExpiry()。
  static bool _sessionExpired = false;

  static void resetSessionExpiry() => _sessionExpired = false;

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
  static String get generateItineraryStreamUrl => BackendConfig.generateItineraryStreamUrl;
  static String get poiPhotoUrl => BackendConfig.poiPhotoUrl;
  static String get getFeatureFlagsUrl => BackendConfig.getFeatureFlagsUrl;
  static String get checkUserQuotaUrl => BackendConfig.checkUserQuotaUrl;
  static String get purchaseVerifyUrl => BackendConfig.purchaseVerifyUrl;
  static String get incrementVoiceUsageUrl => BackendConfig.incrementVoiceUsageUrl;

  /// 通用 POST 请求
  ///
  /// [handle401]：默认 true。restore_session 自身传 false，避免在启动阶段误触发会话失效流程。
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 25),
    bool handle401 = true,
  }) async {
    try {
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

      // 401 统一处理：fire 一次事件，UI 层负责清凭据 + 路由
      if (response.statusCode == 401 && handle401 && !_sessionExpired) {
        _sessionExpired = true;
        AppEventBus.instance.fire(SessionExpiredEvent());
      }

      throw ApiException(response.statusCode, response.body);
    } catch (e, stackTrace) {
      debugPrint('❌ API error: $e');
      Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({'url': url, 'body': body}),
      );
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
