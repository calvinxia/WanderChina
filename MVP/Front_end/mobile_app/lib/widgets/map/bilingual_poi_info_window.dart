import 'package:flutter/material.dart';
import '../../models/translated_poi.dart';
import '../../core/services/language_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// 双语POI信息窗组件
///
/// 根据当前语言显示POI信息（中文或英文）
class BilingualPOIInfoWindow extends StatelessWidget {
  final TranslatedPOI poi;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const BilingualPOIInfoWindow({
    super.key,
    required this.poi,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final languageManager = LanguageManager();
    final currentLang = languageManager.languageCode; // 'en', 'fr', or 'es'

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 300,
          minHeight: 100,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部 - 名称和关闭按钮
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusM),
                ),
              ),
              child: Row(
                children: [
                  // POI类别图标
                  Text(
                    poi.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  // POI名称
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 主要名称（根据语言）
                        Text(
                          poi.getName(currentLang),
                          style: AppTextStyles.h4(color: AppColors.gray900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 如果显示英文，在下方显示中文原名
                        if (currentLang == 'en' && poi.nameEn != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              poi.name,
                              style: AppTextStyles.caption(
                                color: AppColors.gray600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 关闭按钮
                  if (onClose != null)
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.gray600,
                      ),
                    ),
                ],
              ),
            ),

            // 内容区域
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 类别
                  _buildInfoRow(
                    Icons.category_outlined,
                    POICategoryTranslation.getCategoryName(
                      poi.category,
                      currentLang,
                    ),
                  ),

                  // 距离
                  if (poi.distance != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      poi.formattedDistance,
                    ),
                  ],

                  // 评分
                  if (poi.rating != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(
                      Icons.star_outline,
                      '${poi.rating} ${poi.ratingStars} (${poi.reviewCount ?? 0} ${AppTexts.reviews})',
                    ),
                  ],

                  // 地址
                  if (poi.address.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(
                      Icons.place_outlined,
                      poi.getAddress(currentLang),
                      maxLines: 2,
                    ),
                  ],

                  // 营业时间
                  if (poi.openingHours != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(
                      Icons.access_time,
                      poi.openingHours!,
                    ),
                  ],

                  // 价格等级
                  if (poi.priceLevel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(
                      Icons.attach_money,
                      poi.priceLevelSymbol,
                    ),
                  ],

                  // 翻译来源标记（仅当显示英文且有翻译时）
                  if (currentLang == 'en' && poi.isTranslated) ...[
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: [
                        const Icon(
                          Icons.translate,
                          size: 12,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTranslationSourceText(poi.translationSource),
                          style: AppTextStyles.caption(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 底部按钮栏
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.gray200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      Icons.directions,
                      AppTexts.routePlanning,
                      () {
                        // TODO: 实现路线规划
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.gray200,
                  ),
                  Expanded(
                    child: _buildActionButton(
                      Icons.info_outline,
                      AppTexts.details,
                      onTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(
    IconData icon,
    String text, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.gray600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body(color: AppColors.gray700),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取翻译来源文本
  String _getTranslationSourceText(String? source) {
    switch (source) {
      case 'dictionary':
        return 'Local Dictionary';
      case 'cache':
        return 'Cached';
      case 'baidu_api':
        return 'Baidu Translate';
      case 'google_api':
        return 'Google Translate';
      default:
        return 'Translated';
    }
  }
}
