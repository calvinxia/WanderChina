import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 轻量级埋点服务 — MVP 阶段先用 debugPrint 记录事件
/// 后续可接入 Mixpanel / PostHog / Firebase Analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;
  AnalyticsService._();

  /// 用户属性
  String? _userId;
  String? _city;

  void setUser(String userId, {String? city}) {
    _userId = userId;
    _city = city;
  }

  void clearUser() {
    _userId = null;
    _city = null;
  }

  /// 核心事件追踪
  void track(String event, [Map<String, dynamic>? properties]) {
    final props = {
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _userId,
      'city': _city,
      ...?properties,
    };

    // MVP: 打印到控制台 + Sentry breadcrumb
    debugPrint('📊 [Analytics] $event: $props');

    // 添加为 Sentry breadcrumb（出错时可追溯用户行为路径）
    try {
      Sentry.addBreadcrumb(Breadcrumb(
        message: event,
        category: 'analytics',
        data: props,
        level: SentryLevel.info,
      ));
    } catch (_) {}
  }

  // ===== 预定义事件方法 =====

  void appOpen() => track('app_open');

  void searchPoi(String keyword, {String? city}) =>
      track('search_poi', {'keyword': keyword, 'city': city});

  void poiTranslated(String nameZh, String nameEn, {bool fromCache = false}) =>
      track('poi_translated', {'name_zh': nameZh, 'name_en': nameEn, 'from_cache': fromCache});

  void itineraryGenerated(String city, int days, List<String> interests) =>
      track('itinerary_generated', {'city': city, 'days': days, 'interests': interests.join(',')});

  void itineraryModified(String instruction) =>
      track('itinerary_modified', {'instruction': instruction});

  void itinerarySaved(String city, int days) =>
      track('itinerary_saved', {'city': city, 'days': days});

  void voiceTranslated(String direction, String sourceText) =>
      track('voice_translated', {'direction': direction, 'source_text_length': sourceText.length});

  void routePlanned(String mode, String destination) =>
      track('route_planned', {'mode': mode, 'destination': destination});

  void poiNavigate(String poiName) =>
      track('poi_navigate', {'poi': poiName});

  void poiDetailViewed(String poiName) =>
      track('poi_detail_viewed', {'poi': poiName});

  void tabChanged(String tabName) =>
      track('tab_changed', {'tab': tabName});
}
