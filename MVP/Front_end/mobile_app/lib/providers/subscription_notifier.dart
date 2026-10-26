import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_event_bus.dart';
import 'subscription_state.dart';

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() => const SubscriptionState();

  /// App 启动时读本地缓存（在 restoreSession 之前调用）
  Future<void> loadCachedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SubscriptionState(
        isPremium: prefs.getBool('sub_is_premium') ?? false,
        premiumExpiresAt: _parseDate(prefs.getString('sub_expires_at')),
        productId: prefs.getString('sub_product_id'),
        platform: prefs.getString('sub_platform'),
      );
      debugPrint('[SUB] Loaded cached: premium=${state.isPremium}, expires=${state.premiumExpiresAt}');
    } catch (e) {
      debugPrint('[SUB] loadCachedState failed: $e');
    }
  }

  /// restoreSession / login 返回后调用（服务端数据覆盖本地）
  void updateFromServer(Map<String, dynamic> data) {
    state = SubscriptionState(
      isPremium: data['is_premium'] ?? false,
      premiumExpiresAt: data['premium_expires_at'] != null
          ? DateTime.tryParse(data['premium_expires_at'].toString())
          : null,
      productId: data['subscription_product_id'] as String?,
      platform: data['subscription_platform'] as String?,
    );
    _persist();
    debugPrint('[SUB] Updated from server: premium=${state.isPremium}, expires=${state.premiumExpiresAt}');
  }

  /// 购买成功后调用（更新 + 持久化 + 发事件）
  void updateFromPurchase(String productId, DateTime expiresAt) {
    state = SubscriptionState(
      isPremium: true,
      premiumExpiresAt: expiresAt,
      productId: productId,
      platform: 'apple',
    );
    _persist();
    AppEventBus.instance.fire(PurchaseSuccessEvent(
      productId: productId,
      expiresAt: expiresAt,
    ));
    debugPrint('[SUB] Purchase applied: $productId, expires=$expiresAt');
  }

  /// 清除状态（删除账号 / 登出时调用）
  Future<void> clear() async {
    state = const SubscriptionState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sub_is_premium');
      await prefs.remove('sub_expires_at');
      await prefs.remove('sub_product_id');
      await prefs.remove('sub_platform');
    } catch (e) {
      debugPrint('[SUB] clear failed: $e');
    }
  }

  static DateTime? _parseDate(String? s) => s != null ? DateTime.tryParse(s) : null;

  Future<void> _persist() async {
    // 快照 state，防止异步过程中 state 被再次更新导致写入错乱
    final s = state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sub_is_premium', s.isPremium);
      if (s.premiumExpiresAt != null) {
        await prefs.setString('sub_expires_at', s.premiumExpiresAt!.toIso8601String());
      } else {
        await prefs.remove('sub_expires_at');
      }
      if (s.productId != null) await prefs.setString('sub_product_id', s.productId!);
      if (s.platform != null) await prefs.setString('sub_platform', s.platform!);
    } catch (e) {
      debugPrint('[SUB] persist failed: $e');
    }
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(SubscriptionNotifier.new);
