import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// WanderChina v2.0 底部导航栏
///
/// 5个标签: Home · Map · Planner · Voice · Me
///
/// 规范:
/// - Height: 56px + safe area
/// - Background: White
/// - Border top: 1px Gray 200
/// - Active icon: 根据城市主题色
/// - Inactive icon: Gray 400
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isTransparent;
  final Color? themeColor;  // 主题色（默认 Jade 500）

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isTransparent = false,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: isTransparent
            ? ImageFilter.blur(sigmaX: 24, sigmaY: 24)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          decoration: BoxDecoration(
            color: isTransparent
                ? Colors.white.withOpacity(0.25)
                : Colors.white,
            border: Border(
              top: BorderSide(
                color: isTransparent
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.gray200,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: 'Map',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    label: 'Planner',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.mic_none,
                    activeIcon: Icons.mic,
                    label: 'Voice',
                    isVoice: true,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Me',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isVoice = false,
  }) {
    final isActive = currentIndex == index;
    final color = isActive ? (themeColor ?? AppColors.jade500) : AppColors.gray400;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
