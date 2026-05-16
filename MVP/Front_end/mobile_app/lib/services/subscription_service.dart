import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_event_bus.dart';

/// 订阅状态管理 — source of truth + SharedPreferences 持久化
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  // 内存状态
  bool _isPremium = false;
  DateTime? _premiumExpiresAt;
  String? _productId;
  String? _platform;

  /// 是否为付费用户（双重检查 + null 防御）
  bool get isPremium {
    if (!_isPremium) return false;
    // [PB1] 严格: 必须有 expires_at 才认为 premium 有效
    // 防御 _isPremium=true 但 _premiumExpiresAt=null 的数据不一致
    if (_premiumExpiresAt == null) {
      debugPrint('[SUB] isPremium=true but expires_at=null, treating as free');
      return false;
    }
    // 本地即时过期检查，不等服务端 cron
    if (_premiumExpiresAt!.isBefore(DateTime.now())) {
      _isPremium = false;
      _persist();
      AppEventBus.instance.fire(SubscriptionExpiredEvent());
      return false;
    }
    return true;
  }

  DateTime? get premiumExpiresAt => _premiumExpiresAt;
  String? get productId => _productId;
  String? get platform => _platform;

  /// App 启动时调用（在 restoreSession 之前，读本地缓存）
  Future<void> loadCachedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('sub_is_premium') ?? false;
      final expiresStr = prefs.getString('sub_expires_at');
      _premiumExpiresAt = expiresStr != null ? DateTime.tryParse(expiresStr) : null;
      _productId = prefs.getString('sub_product_id');
      _platform = prefs.getString('sub_platform');
      debugPrint('[SUB] Loaded cached: premium=$_isPremium, expires=$_premiumExpiresAt');
    } catch (e) {
      debugPrint('[SUB] loadCachedState failed: $e');
    }
  }

  /// restoreSession / login 返回后调用（服务端数据覆盖本地）
  void updateFromServer(Map<String, dynamic> data) {
    _isPremium = data['is_premium'] ?? false;
    _premiumExpiresAt = data['premium_expires_at'] != null
        ? DateTime.tryParse(data['premium_expires_at'].toString())
        : null;
    _productId = data['subscription_product_id'] as String?;
    _platform = data['subscription_platform'] as String?;
    _persist();
    debugPrint('[SUB] Updated from server: premium=$_isPremium, expires=$_premiumExpiresAt');
  }

  /// 购买成功后调用（更新 + 持久化 + 发事件）
  void updateFromPurchase(String productId, DateTime expiresAt) {
    _isPremium = true;
    _premiumExpiresAt = expiresAt;
    _productId = productId;
    _platform = 'apple';
    _persist();
    AppEventBus.instance.fire(PurchaseSuccessEvent(
      productId: productId,
      expiresAt: expiresAt,
    ));
    debugPrint('[SUB] Purchase applied: $productId, expires=$expiresAt');
  }

  /// 清除状态（删除账号 / 登出时调用）
  Future<void> clear() async {
    _isPremium = false;
    _premiumExpiresAt = null;
    _productId = null;
    _platform = null;
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

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sub_is_premium', _isPremium);
      if (_premiumExpiresAt != null) {
        await prefs.setString('sub_expires_at', _premiumExpiresAt!.toIso8601String());
      } else {
        await prefs.remove('sub_expires_at');
      }
      if (_productId != null) {
        await prefs.setString('sub_product_id', _productId!);
      }
      if (_platform != null) {
        await prefs.setString('sub_platform', _platform!);
      }
    } catch (e) {
      debugPrint('[SUB] persist failed: $e');
    }
  }

  /// 单元测试用
  @visibleForTesting
  void reset() {
    _isPremium = false;
    _premiumExpiresAt = null;
    _productId = null;
    _platform = null;
  }
}
