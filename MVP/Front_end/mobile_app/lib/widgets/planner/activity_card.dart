import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/city_theme.dart';
import '../../models/itinerary.dart';
import 'package:intl/intl.dart';

/// Activity Card Widget - displays a single activity in the itinerary
///
/// Specifications from FLUTTER_UI_REDESIGN_INSTRUCTIONS.md:
/// - Height: auto (min 80px)
/// - Padding: 12px 16px
/// - Background: 25% transparent white
/// - Border-left: 3px city theme color
/// - Border Radius: 8px
class ActivityCard extends StatefulWidget {
  final Activity activity;
  final VoidCallback? onNavigate;
  final VoidCallback? onDetails;
  final VoidCallback? onDelete;
  final CityTheme theme;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.theme,
    this.onNavigate,
    this.onDetails,
    this.onDelete,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final durationHours = widget.activity.duration.inMinutes / 60;
    final durationText = durationHours >= 1
        ? '${durationHours.toStringAsFixed(durationHours == durationHours.toInt() ? 0 : 1)} hrs'
        : '${widget.activity.duration.inMinutes} min';

    // Extract Chinese name from title if exists (format: "Name (中文名)")
    final titleMatch = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(widget.activity.title);
    final nameEn = titleMatch?.group(1)?.trim() ?? widget.activity.title;
    final nameZh = titleMatch?.group(2)?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 左侧主题色条
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: widget.theme.pillActiveColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // 卡片内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + Delete button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeFormat.format(widget.activity.startTime),
                          style: TextStyle(
                            color: widget.theme.pillActiveColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.onDelete != null)
                          GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove activity?'),
                                  content: Text('Remove "${widget.activity.title}" from this day?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) widget.onDelete!();
                            },
                            child: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Name (EN)
                    Text(
                      nameEn,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
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
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.activity.estimatedCost != null) ...[
                          const Text(
                            ' · ',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '¥${widget.activity.estimatedCost!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Action Buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: widget.onNavigate,
                          style: TextButton.styleFrom(
                            foregroundColor: widget.theme.pillActiveColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Navigate',
                            style: TextStyle(
                              color: widget.theme.pillActiveColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: widget.onDetails,
                          style: TextButton.styleFrom(
                            foregroundColor: widget.theme.secondaryTextColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Details',
                            style: TextStyle(
                              color: widget.theme.secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
