import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Route Overview - Route plan options display
///
/// 路线方案概览卡片
/// 显示 Transit / Walking / Driving 三种方案
enum RouteMode {
  transit,
  walking,
  driving,
}

class RouteOption {
  final RouteMode mode;
  final String duration;
  final String? cost;
  final String? distance;

  RouteOption({
    required this.mode,
    required this.duration,
    this.cost,
    this.distance,
  });
}

class RouteOverview extends StatelessWidget {
  final List<RouteOption> options;
  final RouteMode? selectedMode;
  final Function(RouteMode)? onModeSelected;

  const RouteOverview({
    super.key,
    required this.options,
    this.selectedMode,
    this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Route',
                style: AppTextStyles.h4(color: AppColors.gray900),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.gray600,
                onPressed: () {
                  // Close route overview
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((option) => _buildRouteCard(option)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteOption option) {
    final isSelected = selectedMode == option.mode;

    return GestureDetector(
      onTap: () => onModeSelected?.call(option.mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.jade50 : AppColors.gray100,
          border: Border.all(
            color: isSelected ? AppColors.jade500 : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Mode icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.jade500 : AppColors.gray300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getModeIcon(option.mode),
                color: isSelected ? Colors.white : AppColors.gray700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Mode details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getModeName(option.mode),
                    style: AppTextStyles.h4(
                      color: isSelected ? AppColors.jade700 : AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        option.duration,
                        style: AppTextStyles.caption(
                          color: AppColors.gray600,
                        ),
                      ),
                      if (option.cost != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: AppTextStyles.caption(
                            color: AppColors.gray400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option.cost!,
                          style: AppTextStyles.caption(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                      if (option.distance != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: AppTextStyles.caption(
                            color: AppColors.gray400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option.distance!,
                          style: AppTextStyles.caption(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.jade500,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(RouteMode mode) {
    switch (mode) {
      case RouteMode.transit:
        return Icons.directions_transit;
      case RouteMode.walking:
        return Icons.directions_walk;
      case RouteMode.driving:
        return Icons.directions_car;
    }
  }

  String _getModeName(RouteMode mode) {
    switch (mode) {
      case RouteMode.transit:
        return 'Transit';
      case RouteMode.walking:
        return 'Walking';
      case RouteMode.driving:
        return 'Driving';
    }
  }
}
