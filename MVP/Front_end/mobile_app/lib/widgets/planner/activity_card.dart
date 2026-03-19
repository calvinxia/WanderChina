import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/itinerary.dart';
import 'package:intl/intl.dart';

/// Activity Card Widget - displays a single activity in the itinerary
///
/// Specifications from FLUTTER_UI_REDESIGN_INSTRUCTIONS.md:
/// - Height: auto (min 80px)
/// - Padding: 12px 16px
/// - Background: White
/// - Border-left: 3px Jade 500
/// - Border Radius: 8px
/// - Shadow: 0px 1px 4px rgba(0,0,0,0.08)
class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onNavigate;
  final VoidCallback? onDetails;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onNavigate,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final durationHours = activity.duration.inMinutes / 60;
    final durationText = durationHours >= 1
        ? '${durationHours.toStringAsFixed(durationHours == durationHours.toInt() ? 0 : 1)} hrs'
        : '${activity.duration.inMinutes} min';

    // Extract Chinese name from title if exists (format: "Name (中文名)")
    final titleMatch = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(activity.title);
    final nameEn = titleMatch?.group(1)?.trim() ?? activity.title;
    final nameZh = titleMatch?.group(2)?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.jade500,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Text(
            timeFormat.format(activity.startTime),
            style: AppTextStyles.caption(color: AppColors.jade600).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Name (EN)
          Text(
            nameEn,
            style: AppTextStyles.body(color: AppColors.gray900).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          // Name (ZH) if exists
          if (nameZh != null) ...[
            const SizedBox(height: 2),
            Text(
              '($nameZh)',
              style: AppTextStyles.caption(color: AppColors.gray500),
            ),
          ],

          const SizedBox(height: 6),

          // Duration + Cost
          Row(
            children: [
              Text(
                durationText,
                style: AppTextStyles.caption(color: AppColors.gray600),
              ),
              if (activity.estimatedCost != null) ...[
                Text(
                  ' · ',
                  style: AppTextStyles.caption(color: AppColors.gray600),
                ),
                Text(
                  '¥${activity.estimatedCost!.toStringAsFixed(0)}',
                  style: AppTextStyles.caption(color: AppColors.gray600),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Action Buttons
          Row(
            children: [
              TextButton(
                onPressed: onNavigate,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.jade500,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Navigate',
                  style: AppTextStyles.caption(color: AppColors.jade500).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.jade500,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Details',
                  style: AppTextStyles.caption(color: AppColors.jade500).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
