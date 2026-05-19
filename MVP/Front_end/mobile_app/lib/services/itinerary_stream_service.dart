import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'api_client.dart';
import '../core/config/backend_config.dart';

/// 流式行程生成服务
/// - SSE 流式接收 DeepSeek 输出
/// - fallback 到非流式 generate_itinerary
class ItineraryStreamService {

  /// 流式生成行程，yield partial/complete/error 事件
  static Stream<Map<String, dynamic>> generateStream({
    required List<String> cities,
    required int days,
    required List<String> interests,
    String budgetLevel = 'medium',
    String language = 'english',
  }) async* {
    try {
      yield* _streamFromCloud(
        cities: cities,
        days: days,
        interests: interests,
        budgetLevel: budgetLevel,
        language: language,
      );
    } catch (e, stackTrace) {
      debugPrint('⚠️ Stream failed, falling back to non-stream: $e');
      Sentry.captureException(e, stackTrace: stackTrace,
        hint: Hint.withMap({'fallback': 'non_stream'}),
      );

      // Fallback 到非流式
      try {
        final result = await ApiClient.post(
          ApiClient.generateItineraryUrl,
          {
            'action': 'generate',
            'cities': cities,
            'days': days,
            'interests': interests,
            'budget_level': budgetLevel,
            'language': language,
          },
          timeout: const Duration(seconds: 75),
        );
        yield {
          'event': 'complete',
          'data': {
            'title': result['title'] ?? 'My Trip',
            'itinerary': result['itinerary'],
          },
        };
      } catch (fallbackError) {
        yield {
          'event': 'error',
          'message': fallbackError.toString(),
        };
      }
    }
  }

  /// SSE 流式请求
  static Stream<Map<String, dynamic>> _streamFromCloud({
    required List<String> cities,
    required int days,
    required List<String> interests,
    required String budgetLevel,
    required String language,
  }) async* {
    final url = BackendConfig.generateItineraryStreamUrl;
    if (url.isEmpty) {
      throw Exception('GENERATE_ITINERARY_STREAM_URL not configured');
    }

    final request = http.Request('POST', Uri.parse(url))
      ..headers['Content-Type'] = 'application/json; charset=utf-8'
      ..body = json.encode({
        'cities': cities,
        'days': days,
        'interests': interests,
        'budget_level': budgetLevel,
        'language': language,
      });

    final response = await http.Client().send(request).timeout(
      const Duration(seconds: 85),
    );

    if (response.statusCode != 200) {
      throw Exception('Stream API returned ${response.statusCode}');
    }

    // 手动 buffer SSE 消息（用 \n\n 分割，不用 LineSplitter）
    String buffer = '';

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;

      // SSE 消息以 \n\n 分割
      while (buffer.contains('\n\n')) {
        final idx = buffer.indexOf('\n\n');
        final message = buffer.substring(0, idx).trim();
        buffer = buffer.substring(idx + 2);

        if (!message.startsWith('data: ')) continue;
        final payload = message.substring(6); // strip "data: "

        try {
          final event = json.decode(payload) as Map<String, dynamic>;
          yield event;

          // error 事件直接抛异常，触发 fallback
          if (event['event'] == 'error') {
            throw Exception(event['message'] ?? 'Stream error');
          }
        } catch (e) {
          if (e is Exception && e.toString().contains('Stream error')) rethrow;
          debugPrint('⚠️ SSE parse error: $e');
        }
      }
    }
  }
}
