import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanderchina/providers/subscription_state.dart';
import 'package:wanderchina/providers/subscription_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── SubscriptionState.isActive ─────────────────────────────────────────────

  group('SubscriptionState.isActive', () {
    test('未开通 → false', () {
      const state = SubscriptionState(isPremium: false);
      expect(state.isActive, false);
    });

    test('[PB1] 到期时间为空 → false', () {
      const state = SubscriptionState(isPremium: true, premiumExpiresAt: null);
      expect(state.isActive, false);
    });

    test('已过期 → false', () {
      final state = SubscriptionState(
        isPremium: true,
        premiumExpiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(state.isActive, false);
    });

    test('未过期 → true', () {
      final state = SubscriptionState(
        isPremium: true,
        premiumExpiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(state.isActive, true);
    });
  });

  // ── SubscriptionNotifier ────────────────────────────────────────────────────

  group('SubscriptionNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('updateFromServer — 字段解析正确且 isActive=true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(subscriptionProvider.notifier).updateFromServer({
        'is_premium': true,
        'premium_expires_at': '2099-12-31T00:00:00.000',
        'subscription_product_id': 'wanderchina.trip_pass.7d',
        'subscription_platform': 'apple',
      });

      final state = container.read(subscriptionProvider);
      expect(state.isPremium, true);
      expect(state.premiumExpiresAt, DateTime.tryParse('2099-12-31T00:00:00.000'));
      expect(state.productId, 'wanderchina.trip_pass.7d');
      expect(state.platform, 'apple');
      expect(state.isActive, true);
    });

    test('updateFromServer — premium_expires_at 为空 → isActive=false ([PB1])', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(subscriptionProvider.notifier).updateFromServer({
        'is_premium': true,
        'premium_expires_at': null,
      });

      final state = container.read(subscriptionProvider);
      expect(state.isPremium, true);
      expect(state.premiumExpiresAt, isNull);
      expect(state.isActive, false);
    });

    test('loadCachedState — 4 个 prefs key 名不变', () async {
      SharedPreferences.setMockInitialValues({
        'sub_is_premium': true,
        'sub_expires_at': '2099-12-31T00:00:00.000',
        'sub_product_id': 'wanderchina.trip_pass.14d',
        'sub_platform': 'apple',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subscriptionProvider.notifier).loadCachedState();

      final state = container.read(subscriptionProvider);
      expect(state.isPremium, true);
      expect(state.premiumExpiresAt, DateTime.tryParse('2099-12-31T00:00:00.000'));
      expect(state.productId, 'wanderchina.trip_pass.14d');
      expect(state.platform, 'apple');
    });
  });
}
