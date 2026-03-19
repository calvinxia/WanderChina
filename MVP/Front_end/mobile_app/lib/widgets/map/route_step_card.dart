import 'package:flutter/material.dart';
import '../../models/translated_route.dart';
import '../../services/route_planning_service.dart';
import '../../core/services/language_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// 路线步骤卡片组件
///
/// 显示单个路线步骤的详细信息，支持中英文双语
class RouteStepCard extends StatelessWidget {
  final TranslatedRouteStep step;
  final int stepNumber;
  final bool showTranslationBadge;

  const RouteStepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    this.showTranslationBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final languageManager = LanguageManager();
    final currentLang = languageManager.languageCode;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 步骤编号和图标
            _buildStepIcon(),
            const SizedBox(width: AppSpacing.m),

            // 步骤详情
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 指令
                  Text(
                    step.getInstruction(currentLang),
                    style: AppTextStyles.h4(),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // 道路名称
                  if (step.road.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 16,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            step.getRoad(currentLang),
                            style: AppTextStyles.body(color: AppColors.gray600),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.s),

                  // 距离和时间
                  Row(
                    children: [
                      // 距离
                      _buildInfoChip(
                        icon: Icons.straighten,
                        label: step.formattedDistance(currentLang),
                      ),
                      const SizedBox(width: AppSpacing.s),

                      // 时间
                      _buildInfoChip(
                        icon: Icons.access_time,
                        label: step.formattedDuration(currentLang),
                      ),

                      // 翻译标记
                      if (showTranslationBadge && step.isTranslated)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s),
                          child: _buildTranslationBadge(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建步骤图标
  Widget _buildStepIcon() {
    IconData iconData;
    Color iconColor;

    // 根据指令类型选择图标
    if (step.instruction.contains('左转') || step.instruction.contains('Turn left')) {
      iconData = Icons.turn_left;
      iconColor = AppColors.info;
    } else if (step.instruction.contains('右转') || step.instruction.contains('Turn right')) {
      iconData = Icons.turn_right;
      iconColor = AppColors.info;
    } else if (step.instruction.contains('直行') || step.instruction.contains('straight')) {
      iconData = Icons.straight;
      iconColor = AppColors.success;
    } else if (step.instruction.contains('到达') || step.instruction.contains('Arrive')) {
      iconData = Icons.location_on;
      iconColor = AppColors.error;
    } else if (step.instruction.contains('出发') || step.instruction.contains('Start')) {
      iconData = Icons.flag;
      iconColor = AppColors.primary;
    } else {
      iconData = Icons.navigation;
      iconColor = AppColors.gray500;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              iconData,
              color: iconColor,
              size: 24,
            ),
            // 步骤编号
            if (stepNumber > 0)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建信息标签
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.gray600,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption(color: AppColors.gray700),
          ),
        ],
      ),
    );
  }

  /// 构建翻译标记
  Widget _buildTranslationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusS),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.translate,
            size: 10,
            color: AppColors.success,
          ),
          SizedBox(width: 2),
          Text(
            'EN',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 路线概览卡片
///
/// 显示整条路线的总体信息
class RouteSummaryCard extends StatelessWidget {
  final TranslatedRouteInfo route;

  const RouteSummaryCard({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final languageManager = LanguageManager();
    final currentLang = languageManager.languageCode;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.m),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 路线类型
            Row(
              children: [
                Icon(
                  _getRouteTypeIcon(),
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  route.getRouteTypeLabel(currentLang),
                  style: AppTextStyles.h3(),
                ),
                const Spacer(),
                // 翻译进度标记
                if (route.isFullyTranslated)
                  _buildFullyTranslatedBadge()
                else if (route.translatedStepsCount > 0)
                  _buildPartiallyTranslatedBadge(),
              ],
            ),

            const Divider(height: AppSpacing.l),

            // 距离和时间
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.straighten,
                    label: currentLang == 'en' ? 'Distance' : '距离',
                    value: route.formattedDistance(currentLang),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.gray200,
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    label: currentLang == 'en' ? 'Duration' : '时长',
                    value: route.formattedDuration(currentLang),
                  ),
                ),
              ],
            ),

            // 费用（如果有）
            if (route.formattedFee(currentLang) != null) ...[
              const SizedBox(height: AppSpacing.m),
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      route.formattedFee(currentLang)!,
                      style: AppTextStyles.body(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取路线类型图标
  IconData _getRouteTypeIcon() {
    switch (route.routeType) {
      case RouteType.driving:
        return Icons.directions_car;
      case RouteType.walking:
        return Icons.directions_walk;
      case RouteType.transit:
        return Icons.directions_transit;
      case RouteType.riding:
        return Icons.directions_bike;
    }
  }

  /// 构建信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.gray500,
          size: 24,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.gray500),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.h4(),
        ),
      ],
    );
  }

  /// 完全翻译标记
  Widget _buildFullyTranslatedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: Border.all(
          color: AppColors.success,
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.success,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Translated',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 部分翻译标记
  Widget _buildPartiallyTranslatedBadge() {
    final progress = route.translationProgress;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: AppColors.info,
              backgroundColor: AppColors.gray300,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 路线步骤列表组件
///
/// 显示完整的路线步骤列表
class RouteStepsList extends StatelessWidget {
  final TranslatedRouteInfo route;
  final bool showSummary;

  const RouteStepsList({
    super.key,
    required this.route,
    this.showSummary = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 路线概览
        if (showSummary) RouteSummaryCard(route: route),

        // 步骤列表
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: route.steps.length,
          itemBuilder: (context, index) {
            return RouteStepCard(
              step: route.steps[index],
              stepNumber: index + 1,
            );
          },
        ),
      ],
    );
  }
}
