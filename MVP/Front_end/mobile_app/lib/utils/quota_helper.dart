import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/subscription_service.dart';
import '../widgets/paywall_dialog.dart';
import '../core/theme/city_theme.dart';

/// 配额检查 + 付费墙触发
/// 返回 true = 允许继续，false = 被拦截（已弹付费墙或报错）
Future<bool> requireQuotaCheck(
  BuildContext context,
  String quotaType,
  CityTheme theme, {
  String? userId,
  String? deviceId,
}) async {
  // [PB7] 本地快速判断: 付费用户直接放行, 跳过 check_user_quota 调用.
  // 假设: paywall 只 gate 免费用户, premium 用户无配额限制.
  // 如未来加 "premium 也有配额" 规则, 删除此行让 SCF 处理.
  if (SubscriptionService.instance.isPremium) return true;

  try {
    final body = <String, dynamic>{'quota_type': quotaType};
    if (userId != null) body['user_id'] = userId;
    if (deviceId != null) body['device_id'] = deviceId;

    final result = await ApiClient.post(
      ApiClient.checkUserQuotaUrl,
      body,
      timeout: const Duration(seconds: 5),
    );

    if (result['allowed'] == true) return true;

    // 不通过 → 弹付费墙
    if (context.mounted) {
      await showPaywallDialog(context, theme, quotaType);
    }
    return false;
  } catch (e) {
    debugPrint('⚠️ Quota check failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service temporarily unavailable, please try again')),
      );
    }
    return false;
  }
}
