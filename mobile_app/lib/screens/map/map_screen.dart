import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Map Screen - Interactive map with places
/// Based on Figma design - Screen 5 (Map)
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: AppColors.gray100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 100,
                    color: AppColors.gray300,
                  ),
                  AppSpacing.gapHeightM,
                  Text(
                    'Map View',
                    style: AppTextStyles.h3(color: AppColors.gray600),
                  ),
                  AppSpacing.gapHeightS,
                  Text(
                    'Google Maps integration will be added here',
                    style: AppTextStyles.body(color: AppColors.gray500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  // Search button
                  _buildControlButton(
                    icon: Icons.search,
                    onTap: () {},
                  ),
                  Spacer(),
                  // Layers button
                  _buildControlButton(
                    icon: Icons.layers,
                    onTap: () {},
                  ),
                  SizedBox(width: AppSpacing.s),
                  // Location button
                  _buildControlButton(
                    icon: Icons.my_location,
                    onTap: () {},
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet preview
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray900.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSpacing.gapHeightS,
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.m),
                    child: Text(
                      'Tap on markers to see place details',
                      style: AppTextStyles.body(color: AppColors.gray600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.gray700,
          size: 24,
        ),
      ),
    );
  }
}
