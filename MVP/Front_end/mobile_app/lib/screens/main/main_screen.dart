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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // v2.0 屏幕列表（不包括Voice，因为它是模态框）
  final List<Widget> _screens = [
    const HomeScreen(),
    const MapWithTranslationScreen(),
    const PlannerHomeScreen(),
    const Placeholder(), // Voice占位符（实际上打开模态框）
    const ProfileScreen(),
  ];

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
