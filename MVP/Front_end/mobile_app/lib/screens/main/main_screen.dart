import 'package:flutter/material.dart';
import '../../widgets/common/app_bottom_navigation.dart';
import '../home/home_screen.dart';
import '../map/map_with_translation_screen.dart';
import '../planner/planner_home_screen.dart';
import '../voice/voice_translation_screen.dart';
import '../profile/profile_screen.dart';

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
  int _currentIndex = 0;
  final GlobalKey<MapWithTranslationScreenState> _mapKey = GlobalKey();
  String? pendingSearchCity;

  // v2.0 屏幕列表（不包括Voice，因为它是模态框）
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      MapWithTranslationScreen(key: _mapKey),
      const PlannerHomeScreen(),
      const Placeholder(), // Voice占位符（实际上打开模态框）
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
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
  void switchToMapAndSearch(String query, {String? displayName, String? city}) {
    setState(() {
      _currentIndex = 1;  // Map tab index
    });
    pendingSearchCity = city;
    // 直接调 Map 页面的搜索方法
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapKey.currentState?.searchFromExternal(query, displayName: displayName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
