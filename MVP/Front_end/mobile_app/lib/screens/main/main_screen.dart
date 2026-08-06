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

/// WanderChina v2.0 主导航页面
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

  // v2.0 屏幕列表（不包括Voice，因为它是模态框）
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadCityTheme();
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      MapWithTranslationScreen(key: _mapKey),
      const PlannerHomeScreen(),
      const Placeholder(), // Voice占位符（实际上打开模态框）
      const ProfileScreen(),
    ];
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
