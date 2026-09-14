import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 后端 feature flags 客户端
///
/// fail-closed 设计：任何网络失败、超时、解析异常均保持 paywallEnabled=false，
/// 避免在无公司主体期间意外唤起真实支付界面。
///
/// 后端响应结构：{ "flags": { "paywall_enabled": bool, ... }, "cached": bool }
class FeatureFlagsService {
  static final FeatureFlagsService instance = FeatureFlagsService._();
  FeatureFlagsService._();

  // ── paywall ──────────────────────────────────────────────────────
  bool _paywallEnabled = false;
  List<String> _paywallGates = [];
  int _triggerItineraryCount = 3;
  int _triggerVoiceDaily = 5;
  bool _triggerAiEdit = true;
  dynamic _pricingOverride;

  // ── 其他 ─────────────────────────────────────────────────────────
  bool _surveyEnabled = false;

  bool get paywallEnabled => _paywallEnabled;
  List<String> get paywallGates => _paywallGates;
  int get triggerItineraryCount => _triggerItineraryCount;
  int get triggerVoiceDaily => _triggerVoiceDaily;
  bool get triggerAiEdit => _triggerAiEdit;
  dynamic get pricingOverride => _pricingOverride;
  bool get surveyEnabled => _surveyEnabled;

  Future<void> fetchAndCache() async {
    try {
      final result = await ApiClient.post(
        ApiClient.getFeatureFlagsUrl,
        {},
        timeout: const Duration(seconds: 5),
      );

      final flags = result['flags'];
      if (flags is! Map<String, dynamic>) {
        // 外层 flags key 缺失或类型异常 → 区分于网络失败的解析错误日志
        final preview = result.toString();
        debugPrint('[FLAGS] parse failed, fallback to false. raw=${preview.length > 200 ? preview.substring(0, 200) : preview}');
        return;
      }

      _paywallEnabled = flags['paywall_enabled'] == true;
      _paywallGates = _toStringList(flags['paywall_gates']);
      _triggerItineraryCount = (flags['paywall_trigger_itinerary_count'] as num?)?.toInt() ?? 3;
      _triggerVoiceDaily = (flags['paywall_trigger_voice_daily'] as num?)?.toInt() ?? 5;
      _triggerAiEdit = flags['paywall_trigger_ai_edit'] == true;
      _pricingOverride = flags['pricing_override'];
      _surveyEnabled = flags['survey_enabled'] == true;

      debugPrint('[FLAGS] fetched: paywallEnabled=$_paywallEnabled (from server)');
    } catch (e) {
      debugPrint('[FLAGS] fetch failed, fail-closed (paywallEnabled=false): $e');
    }
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return [];
  }
}
