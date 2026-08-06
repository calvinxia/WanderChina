import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'backend/auth_service.dart';
import 'subscription_service.dart';
import 'app_event_bus.dart';

class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const Set<String> _productIds = {
    'wanderchina.trip_pass.7d',
    'wanderchina.trip_pass.14d',
    'wanderchina.trip_pass.30d',
  };

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// 初始化 — 在 main.dart 中 await 调用
  Future<void> initialize() async {
    if (_initialized) return;

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[PURCHASE] In-App Purchase not available on this device');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('[PURCHASE] Stream error: $e'),
    );

    await _loadProducts();

    _initialized = true;
    debugPrint('[PURCHASE] Initialized, ${_products.length} products loaded');
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[PURCHASE] Products NOT found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;

      for (final p in _products) {
        debugPrint('[PURCHASE] Loaded: ${p.id} - ${p.price} (${p.currencyCode})');
      }
    } catch (e) {
      debugPrint('[PURCHASE] Failed to load products: $e');
    }
  }

  ProductDetails? findProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// 触发购买:
  /// - Android: buyConsumable (限时通行证过期后可重买)
  /// - iOS: buyNonConsumable (Non-Renewing Subscription)
  Future<bool> buy(String productId) async {
    final product = findProduct(productId);
    if (product == null) {
      debugPrint('[PURCHASE] Product not found: $productId');
      return false;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final bool result;
      if (Platform.isAndroid) {
        // autoConsume: false — 后端验证成功后再手动 consume
        result = await _iap.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: false,
        );
      } else {
        result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      debugPrint('[PURCHASE] Purchase initiated for $productId, result: $result');
      return result;
    } catch (e) {
      debugPrint('[PURCHASE] Buy failed: $e');
      return false;
    }
  }

  /// 恢复购买 (换设备 / 重装 app)
  Future<void> restorePurchases() async {
    debugPrint('[PURCHASE] Restoring purchases...');
    await _iap.restorePurchases();
  }

  /// 处理购买/恢复回调
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint('[PURCHASE] Update: ${purchase.productID} status=${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyOnBackend(purchase);

          if (verified) {
            if (Platform.isAndroid) {
              // consumePurchase = acknowledge + consume (允许重复购买)
              final androidAddition =
                  _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
              await androidAddition.consumePurchase(purchase);
            } else {
              await _iap.completePurchase(purchase);
            }
            debugPrint('[PURCHASE] Verified + completed: ${purchase.productID}');
          } else {
            debugPrint('[PURCHASE] Backend verification FAILED for ${purchase.productID}');
          }
          break;

        case PurchaseStatus.error:
          debugPrint('[PURCHASE] Error: ${purchase.error?.message}');
          AppEventBus.instance.fire(PurchaseFailedEvent(
            productId: purchase.productID,
            reason: purchase.error?.message ?? 'Unknown error',
          ));
          await _iap.completePurchase(purchase);
          break;

        case PurchaseStatus.canceled:
          debugPrint('[PURCHASE] User canceled: ${purchase.productID}');
          await _iap.completePurchase(purchase);
          break;
      }
    }
  }

  /// 后端验证,按平台分发
  Future<bool> _verifyOnBackend(PurchaseDetails purchase) async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      debugPrint('[PURCHASE] No current user, cannot verify');
      return false;
    }

    if (Platform.isAndroid) {
      return _verifyAndroidOnBackend(purchase, userId);
    }
    return _verifyiOSOnBackend(purchase, userId);
  }

  /// Android: 发送 Google Play Purchase Token 到后端
  Future<bool> _verifyAndroidOnBackend(
    PurchaseDetails purchase,
    String userId,
  ) async {
    try {
      final purchaseToken = purchase.verificationData.serverVerificationData;

      final result = await ApiClient.post(
        ApiClient.purchaseVerifyUrl,
        {
          'user_id': userId,
          'platform': 'google',
          'product_id': purchase.productID,
          'transaction_id': purchase.purchaseID ?? '',
          'purchase_token': purchaseToken,
        },
        timeout: const Duration(seconds: 15),
      );

      final success = result['success'] == true;

      if (success) {
        final expiresStr = result['premium_expires_at']?.toString() ?? '';
        final expiresAt = DateTime.tryParse(expiresStr) ??
            DateTime.now().add(const Duration(days: 7));
        SubscriptionService.instance
            .updateFromPurchase(purchase.productID, expiresAt);
        debugPrint('[PURCHASE] Android backend verified: expires=$expiresAt');
      } else {
        AppEventBus.instance.fire(PurchaseFailedEvent(
          productId: purchase.productID,
          reason: result['error']?.toString() ?? 'unknown',
        ));
        debugPrint('[PURCHASE] Android backend rejected: ${result['error'] ?? 'unknown'}');
      }

      return success;
    } catch (e) {
      debugPrint('[PURCHASE] Android verification exception: $e');
      return false;
    }
  }

  /// iOS: 发送 App Receipt (PKCS7) 到后端
  Future<bool> _verifyiOSOnBackend(
    PurchaseDetails purchase,
    String userId,
  ) async {
    try {
      // 获取 App Receipt（base64 PKCS7）— 需要 enableStoreKit1 已调用
      final platformAddition =
          _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      final receiptData =
          await platformAddition.refreshPurchaseVerificationData();
      final appReceipt = receiptData?.localVerificationData ?? '';

      if (appReceipt.isEmpty) {
        debugPrint('[PURCHASE] No app receipt available');
        return false;
      }

      final result = await ApiClient.post(
        ApiClient.purchaseVerifyUrl,
        {
          'user_id': userId,
          'platform': 'apple',
          'product_id': purchase.productID,
          'transaction_id': purchase.purchaseID ?? '',
          'receipt_data': appReceipt,
        },
        timeout: const Duration(seconds: 15),
      );

      final success = result['success'] == true;

      if (success) {
        final expiresStr = result['premium_expires_at']?.toString() ?? '';
        final expiresAt = DateTime.tryParse(expiresStr) ??
            DateTime.now().add(const Duration(days: 7));
        SubscriptionService.instance
            .updateFromPurchase(purchase.productID, expiresAt);
        debugPrint('[PURCHASE] iOS backend verified: expires=$expiresAt');
      } else {
        AppEventBus.instance.fire(PurchaseFailedEvent(
          productId: purchase.productID,
          reason: result['error']?.toString() ?? 'unknown',
        ));
        debugPrint('[PURCHASE] iOS backend rejected: ${result['error'] ?? 'unknown'}');
      }

      return success;
    } catch (e) {
      debugPrint('[PURCHASE] iOS verification exception: $e');
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _initialized = false;
  }
}
