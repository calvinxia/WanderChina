import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/poi_translation.dart';

/// POI Bottom Sheet - Draggable sheet for POI details
///
/// 可拖拽的 POI 详情底部面板
/// 三种状态：Collapsed (64px) → Half (240px) → Full (80%)
class POIBottomSheet extends StatelessWidget {
  final POITranslation poi;
  final VoidCallback? onDirections;
  final VoidCallback? onDetails;
  final VoidCallback? onClose;
  final DraggableScrollableController? controller;

  const POIBottomSheet({
    super.key,
    required this.poi,
    this.onDirections,
    this.onDetails,
    this.onClose,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.1, // Collapsed state
      minChildSize: 0.1,
      maxChildSize: 0.8, // Full state
      snap: true,
      snapSizes: const [0.1, 0.3, 0.8], // Collapsed, Half, Full
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Collapsed content - Name + Distance
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poi.nameEn,
                            style: AppTextStyles.h4(color: AppColors.gray900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.place,
                                size: 14,
                                color: AppColors.gray600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                poi.city,
                                style: AppTextStyles.caption(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.gray600),
                        onPressed: onClose,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Half content - Photo + Details + Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo placeholder
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bilingual name
                    Text(
                      poi.nameEn,
                      style: AppTextStyles.h3(color: AppColors.gray900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      poi.nameZh,
                      style: AppTextStyles.body(color: AppColors.gray600),
                    ),

                    const SizedBox(height: 20),

                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onDirections,
                            icon: const Icon(Icons.directions, size: 20),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.jade500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDetails,
                            icon: const Icon(Icons.info_outline, size: 20),
                            label: const Text('Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.jade500,
                              side: const BorderSide(color: AppColors.jade500),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Full content - Additional details
                    if (poi.categoryEn != null) ...[
                      const Divider(),
                      AppSpacing.gapHeightM,
                      Text(
                        'About',
                        style: AppTextStyles.h4(color: AppColors.gray900),
                      ),
                      AppSpacing.gapHeightS,
                      _buildDetailRow('Category', poi.categoryEn ?? 'N/A'),
                      _buildDetailRow('POI ID', poi.gaodePoiId),
                      _buildDetailRow('City', poi.city),
                      _buildDetailRow('Source', poi.source.name),
                      AppSpacing.gapHeightXL,
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption(color: AppColors.gray600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body(color: AppColors.gray900),
            ),
          ),
        ],
      ),
    );
  }
}
