import 'package:flutter/foundation.dart';

class SubscriptionState {
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String? productId;
  final String? platform;

  const SubscriptionState({
    this.isPremium = false,
    this.premiumExpiresAt,
    this.productId,
    this.platform,
  });

  /// [PB1] 到期时间为空视为免费 —— 与现有 isPremium getter 及后端 quota_check.py 一致
  /// 逐行对照 SubscriptionService.isPremium getter 实现。
  bool get isActive {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) {
      debugPrint('[SUB] isPremium=true but expires_at=null, treating as free');
      return false;
    }
    if (premiumExpiresAt!.isBefore(DateTime.now())) return false;
    return true;
  }
}
