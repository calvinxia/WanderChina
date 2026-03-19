import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/poi_translation.dart';

/// Language Switcher with Overlay Toggle
///
/// 语言切换条 + 翻译蒙层开关
/// EN · FR · ES + Toggle
class LanguageSwitcher extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final Function(AppLanguage) onLanguageChanged;
  final bool overlayEnabled;
  final Function(bool) onOverlayToggle;

  const LanguageSwitcher({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.overlayEnabled,
    required this.onOverlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Language Pills
          Expanded(
            child: Row(
              children: [
                _buildLanguagePill(AppLanguage.english, 'EN'),
                const SizedBox(width: 8),
                _buildLanguagePill(AppLanguage.french, 'FR'),
                const SizedBox(width: 8),
                _buildLanguagePill(AppLanguage.spanish, 'ES'),
              ],
            ),
          ),

          // Overlay Toggle
          Row(
            children: [
              Text(
                'Labels',
                style: AppTextStyles.caption(color: AppColors.gray600),
              ),
              const SizedBox(width: 8),
              Switch(
                value: overlayEnabled,
                onChanged: onOverlayToggle,
                activeColor: AppColors.jade500,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(AppLanguage language, String label) {
    final isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () => onLanguageChanged(language),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.jade500 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(
            color: isSelected ? Colors.white : AppColors.gray700,
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
