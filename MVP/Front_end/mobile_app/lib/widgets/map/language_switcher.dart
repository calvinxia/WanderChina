import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/poi_translation.dart';
import '../../core/theme/city_theme.dart';

/// Language Switcher with Overlay Toggle
///
/// 语言切换条 + 翻译蒙层开关
/// EN · FR · ES + Toggle
class LanguageSwitcher extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final Function(AppLanguage) onLanguageChanged;
  final bool overlayEnabled;
  final Function(bool) onOverlayToggle;
  final CityTheme? theme;

  const LanguageSwitcher({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.overlayEnabled,
    required this.onOverlayToggle,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = theme ?? CityTheme.defaultTheme;

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
                _buildLanguagePill(context, AppLanguage.english, 'EN', currentTheme),
                const SizedBox(width: 8),
                _buildLanguagePill(context, AppLanguage.french, 'FR', currentTheme),
                const SizedBox(width: 8),
                _buildLanguagePill(context, AppLanguage.spanish, 'ES', currentTheme),
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
                activeColor: currentTheme.pillActiveColor,
                activeTrackColor: currentTheme.pillActiveColor.withOpacity(0.4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(BuildContext context, AppLanguage language, String label, CityTheme theme) {
    final isSelected = selectedLanguage == language;
    final isDisabled = language == AppLanguage.french || language == AppLanguage.spanish;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: () {
          if (isDisabled) {
            // FR/ES 暂不支持，显示提示
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('French/Spanish translation coming soon — English available now'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          // EN 正常切换
          onLanguageChanged(language);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.pillActiveColor : Colors.transparent,
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
      ),
    );
  }
}
