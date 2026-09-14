import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/city_theme.dart';

class SavedTripCard extends StatelessWidget {
  final String title;
  final String date;
  final String cityDisplay;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SavedTripCard({
    super.key,
    required this.title,
    required this.date,
    required this.cityDisplay,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tripCity = cityDisplay.split(',').first.trim();
    final tripTheme = CityTheme.fromCityKey(_getCityKey(tripCity));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tripTheme.pillActiveColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: tripTheme.pillActiveColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : 'My Trip',
                    style: AppTextStyles.body(color: AppColors.gray900)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTextStyles.caption(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.gray400, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  String _getCityKey(String cityName) {
    if (cityName.contains('Beijing') || cityName.contains('北京')) return 'BJ';
    if (cityName.contains('Shanghai') || cityName.contains('上海')) return 'SH';
    if (cityName.contains('Guangzhou') || cityName.contains('广州')) return 'GZ';
    if (cityName.contains('Shenzhen') || cityName.contains('深圳')) return 'SZ';
    if (cityName.contains('Chengdu') || cityName.contains('成都')) return 'CD';
    if (cityName.contains("Xi'an") || cityName.contains('西安')) return 'XA';
    return 'GZ';
  }
}
