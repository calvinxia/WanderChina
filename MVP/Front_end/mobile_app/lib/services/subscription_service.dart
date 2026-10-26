import '../providers/app_container.dart';
import '../providers/subscription_notifier.dart';

/// 薄门面层 —— 签名与调用约定不变,内部转发到 SubscriptionNotifier。
/// 8 个写入方与 2 个读取方的调用代码无需修改。
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  bool get isPremium => appContainer.read(subscriptionProvider).isActive;
  DateTime? get premiumExpiresAt => appContainer.read(subscriptionProvider).premiumExpiresAt;
  String? get productId => appContainer.read(subscriptionProvider).productId;
  String? get platform => appContainer.read(subscriptionProvider).platform;

  Future<void> loadCachedState() =>
      appContainer.read(subscriptionProvider.notifier).loadCachedState();

  void updateFromServer(Map<String, dynamic> data) =>
      appContainer.read(subscriptionProvider.notifier).updateFromServer(data);

  void updateFromPurchase(String productId, DateTime expiresAt) =>
      appContainer.read(subscriptionProvider.notifier).updateFromPurchase(productId, expiresAt);

  Future<void> clear() =>
      appContainer.read(subscriptionProvider.notifier).clear();
}
