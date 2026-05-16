import 'dart:async';
import 'package:flutter/foundation.dart';

/// 事件基类 — sealed class，编译期穷举检查
sealed class AppEvent {}

class PurchaseSuccessEvent extends AppEvent {
  final String productId;
  final DateTime expiresAt;
  PurchaseSuccessEvent({required this.productId, required this.expiresAt});
}

class PurchaseFailedEvent extends AppEvent {
  final String productId;
  final String reason;
  PurchaseFailedEvent({required this.productId, required this.reason});
}

class SubscriptionExpiredEvent extends AppEvent {}

class QuotaUpdatedEvent extends AppEvent {
  final String feature;
  final int usedCount;
  QuotaUpdatedEvent({required this.feature, required this.usedCount});
}

/// 全局事件总线 — broadcast StreamController
class AppEventBus {
  static final AppEventBus instance = AppEventBus._();
  AppEventBus._();

  final _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  /// 只监听特定类型的事件
  Stream<T> on<T extends AppEvent>() =>
      _controller.stream.where((e) => e is T).cast<T>();

  void fire(AppEvent event) {
    _controller.add(event);
  }

  /// [PB3] 仅供测试使用。Production 永不调用，EventBus 与 app 生命周期相同。
  @visibleForTesting
  void dispose() {
    _controller.close();
  }
}
