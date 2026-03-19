import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/itinerary.dart';

/// Itinerary Card - Displays trip summary
/// 行程卡片
class ItineraryCard extends StatefulWidget {
  final Itinerary itinerary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItineraryCard({
    super.key,
    required this.itinerary,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ItineraryCard> createState() => _ItineraryCardState();
}

class _ItineraryCardState extends State<ItineraryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image or placeholder
              _buildCoverSection(),

              // Content section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Days until
                    _buildStatusRow(),

                    AppSpacing.gapHeightS,

                    // Title
                    Text(
                      widget.itinerary.title,
                      style: AppTextStyles.h4(color: AppColors.gray900),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    AppSpacing.gapHeightXS,

                    // Destination
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.itinerary.cities?.join(', ') ??
                                widget.itinerary.destination,
                            style: AppTextStyles.bodySmall(color: AppColors.gray600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    AppSpacing.gapHeightM,

                    // Date range
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDateRange(),
                            style: AppTextStyles.bodySmall(color: AppColors.gray700),
                          ),
                        ),
                        Text(
                          '${widget.itinerary.totalDays} days',
                          style: AppTextStyles.button(color: AppColors.primary),
                        ),
                      ],
                    ),

                    AppSpacing.gapHeightM,

                    // Tags
                    if (widget.itinerary.tags != null &&
                        widget.itinerary.tags!.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.itinerary.tags!.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusS),
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.caption(color: AppColors.primary)
                                  .copyWith(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),

                    // Action buttons (Edit/Delete) for non-completed trips
                    if (widget.itinerary.status != 'completed') ...[
                      AppSpacing.gapHeightM,
                      Row(
                        children: [
                          if (widget.onEdit != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusM),
                                  ),
                                ),
                              ),
                            ),
                          if (widget.onEdit != null && widget.onDelete != null)
                            const SizedBox(width: AppSpacing.s),
                          if (widget.onDelete != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onDelete,
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error500,
                                  side: const BorderSide(color: AppColors.error500),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusM),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverSection() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXL),
        ),
        image: widget.itinerary.coverImageUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.itinerary.coverImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
        gradient: widget.itinerary.coverImageUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.info500.withOpacity(0.3),
                ],
              )
            : null,
      ),
      child: widget.itinerary.coverImageUrl == null
          ? Center(
              child: Icon(
                Icons.landscape,
                size: 64,
                color: Colors.white.withOpacity(0.7),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusRow() {
    Color statusColor;
    String statusText;

    switch (widget.itinerary.status) {
      case 'draft':
        statusColor = AppColors.gray500;
        statusText = 'Draft';
        break;
      case 'planned':
        statusColor = AppColors.success500;
        statusText = 'Planned';
        break;
      case 'ongoing':
        statusColor = AppColors.info500;
        statusText = 'Ongoing';
        break;
      case 'completed':
        statusColor = AppColors.primary;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = AppColors.error500;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = AppColors.gray500;
        statusText = widget.itinerary.status;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusS),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Text(
            statusText.toUpperCase(),
            style: AppTextStyles.caption(color: statusColor)
                .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        if (widget.itinerary.isUpcoming)
          Text(
            'in ${widget.itinerary.daysUntilStart} days',
            style: AppTextStyles.caption(color: AppColors.gray600),
          ),
      ],
    );
  }

  String _formatDateRange() {
    final start = widget.itinerary.startDate;
    final end = widget.itinerary.endDate;

    final startMonth = _getMonthName(start.month);
    final endMonth = _getMonthName(end.month);

    if (start.year == end.year) {
      if (start.month == end.month) {
        return '$startMonth ${start.day}-${end.day}, ${start.year}';
      } else {
        return '$startMonth ${start.day} - $endMonth ${end.day}, ${start.year}';
      }
    } else {
      return '$startMonth ${start.day}, ${start.year} - $endMonth ${end.day}, ${end.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
