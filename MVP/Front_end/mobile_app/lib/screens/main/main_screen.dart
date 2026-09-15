import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/common/app_bottom_navigation.dart';
import '../home/home_screen.dart';
import '../map/map_with_translation_screen.dart';
import '../planner/planner_home_screen.dart';
import '../voice/voice_translation_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/theme/city_theme.dart';
import '../../widgets/common/city_background.dart';
import '../../services/analytics_service.dart';
import '../../services/app_event_bus.dart';
import '../../services/backend/auth_service.dart';
import '../auth/login_screen.dart';

/// OrienScope v2.0 主导航页面
///
/// 规范来自 SCREEN_SPECIFICATIONS_v2.md
/// - 5个标签: Home · Map · Planner · Voice · Me
/// - Voice标签打开全屏模态框
/// - 使用IndexedStack保持页面状态
class MainScreen extends StatefulWidget {
  static final GlobalKey<MainScreenState> globalKey = GlobalKey<MainScreenState>();

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final _analytics = AnalyticsService.instance;
  int _currentIndex = 0;
  final GlobalKey<MapWithTranslationScreenState> _mapKey = GlobalKey();
  String? pendingSearchCity;
  CityTheme _cityTheme = CityTheme.defaultTheme;
  StreamSubscription? _sessionExpiredSub;

  // v2.0 屏幕列表（不包括Voice，因为它是模态框）
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadCityTheme();
    _sessionExpiredSub = AppEventBus.instance
        .on<SessionExpiredEvent>()
        .listen(_onSessionExpired);
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      MapWithTranslationScreen(key: _mapKey),
      const PlannerHomeScreen(),
      const Placeholder(), // Voice占位符（实际上打开模态框）
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCityTheme() async {
    try {
      // 1. 优先尝试 GPS 定位 — 人在六城范围内时实时切换
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).timeout(const Duration(seconds: 5));

        final gpsTheme = CityTheme.fromCoordinates(
          position.latitude,
          position.longitude,
        );

        // fromCoordinates 匹配不到六城时返回 defaultTheme
        // 只有真正匹配到六城才用 GPS 结果
        if (gpsTheme != CityTheme.defaultTheme ||
            _isInDefaultCity(position.latitude, position.longitude)) {
          if (mounted) {
            setState(() {
              _cityTheme = gpsTheme;
            });
          }
          return;
        }
      } catch (_) {
        // GPS 超时或权限拒绝，继续往下走
      }

      // 2. GPS 匹配不到六城（海外、城际路上）→ 读 Onboarding 选择
      final prefs = await SharedPreferences.getInstance();
      final savedCity = prefs.getString('destination_city');

      if (savedCity != null && savedCity.isNotEmpty) {
        if (mounted) {
          setState(() {
            _cityTheme = CityTheme.fromCityKey(savedCity);
          });
        }
        return;
      }

      // 3. 都没有 → 保持 defaultTheme
    } catch (e) {
      debugPrint('📍 City theme detection failed: $e');
    }
  }

  /// 检查坐标是否在默认城市（广州）范围内
  /// 因为 fromCoordinates 匹配到广州也返回 defaultTheme，需要区分
  /// "真的在广州" vs "匹配不到任何城市"
  bool _isInDefaultCity(double lat, double lng) {
    return lat > 22.5 && lat < 23.6 && lng > 112.9 && lng < 114.0;
  }

  /// 会话失效处理：由 ApiClient 在 401 时通过 AppEventBus 触发。
  ///
  /// 已注册用户：清空凭据 → 提示 → 路由至 LoginScreen。
  /// 匿名用户：清空凭据 → 静默重认证（fire-and-forget，失败不提示不重试）。
  void _onSessionExpired(SessionExpiredEvent _) {
    final wasAnonymous = AuthService.isAnonymous;
    AuthService.logout(); // 内存字段在首个 await 前同步清空，prefs 清除为 fire-and-forget
    if (!wasAnonymous) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    // 匿名用户：后台静默重认证，不路由，不提示
    _reAuthAnonymous();
  }

  /// 匿名会话过期后的静默重认证。
  /// device_id 优先读 prefs，丢失时原地重新生成（与 SplashScreen._getOrCreateDeviceId 逻辑一致）。
  /// 只尝试一次；网络不通则静默失败，用户以 userId=null 状态继续。
  /// 成功后 resetSessionExpiry() 已由 AuthService.anonymousAuth() 内部调用（auth_service.dart:46）。
  Future<void> _reAuthAnonymous() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        deviceId = List.generate(
          32,
          (_) => Random.secure().nextInt(16).toRadixString(16),
        ).join();
        await prefs.setString('device_id', deviceId);
      }
      await AuthService.anonymousAuth(deviceId);
    } catch (_) {
      // 网络不通时静默失败，不重试
    }
  }

  /// Expose city theme for child pages
  CityTheme get cityTheme => _cityTheme;

  /// 临时切换城市主题（Planner 选城市时调用）
  void updateCityTheme(CityTheme theme) {
    setState(() {
      _cityTheme = theme;
    });
  }

  /// 公开方法：重新加载 GPS 定位城市主题
  void loadCityTheme() => _loadCityTheme();

  void _onTabTapped(int index) {
    // Analytics tracking
    _analytics.tabChanged(['Home', 'Map', 'Planner', 'Voice', 'Profile'][index]);

    // 离开 Planner tab 时恢复 GPS 主题
    if (_currentIndex == 2 && index != 2) {
      _loadCityTheme();  // 重新用 GPS 定位城市
    }

    // Voice标签（index == 3）打开全屏模态框
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VoiceTranslationScreen(),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  /// 切换到指定 tab
  void switchToTab(int index) {
    if (index == 3) {
      // Voice标签打开全屏模态框
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VoiceTranslationScreen(),
          fullscreenDialog: true,
        ),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  /// 切换到 Map tab 并执行搜索
  void switchToMapAndSearch(String query, {String? displayName, String? city, String? fallbackQuery}) {
    setState(() {
      _currentIndex = 1;  // Map tab index
    });
    pendingSearchCity = city;
    // 直接调 Map 页面的搜索方法
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapKey.currentState?.searchFromExternal(query, displayName: displayName, fallbackQuery: fallbackQuery);
    });
  }

  /// 只切到 Map tab + 触发搜索，不 pop 任何 route。
  /// 保留其他 tab（如 Planner）的导航栈完整。
  /// ⚠️ 当前未使用：itinerary_detail 压在 MainScreen 上，不 pop 看不到 Map tab。
  /// 预留给未来嵌套 Navigator 改造（各 tab 独立导航栈）后启用。
  void switchToMapTabAndSearch(String query, {String? displayName, String? city, String? fallbackQuery}) {
    setState(() => _currentIndex = 1);
    pendingSearchCity = city;
    // addPostFrameCallback 确保 tab 切换完成后再搜索
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.searchFromExternal(query, displayName: displayName, city: city, fallbackQuery: fallbackQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMapPage = _currentIndex == 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CityBackground(
        theme: _cityTheme,
        enabled: !isMapPage,
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        isTransparent: !isMapPage,
        themeColor: _cityTheme.pillActiveColor,
      ),
      ),
    );
  }
}
