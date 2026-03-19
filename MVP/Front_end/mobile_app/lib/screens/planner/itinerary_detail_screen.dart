import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/itinerary.dart';

/// Itinerary Detail Screen - View complete trip itinerary
/// 行程详情页面
class ItineraryDetailScreen extends StatelessWidget {
  final Itinerary itinerary;

  const ItineraryDetailScreen({
    super.key,
    required this.itinerary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          itinerary.title,
          style: AppTextStyles.h4(color: AppColors.gray900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.gray700),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.gray700),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.info500.withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.landscape,
                  size: 80,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),

            AppSpacing.gapHeightL,

            // Trip info
            Text(
              itinerary.title,
              style: AppTextStyles.h2(color: AppColors.gray900),
            ),

            AppSpacing.gapHeightS,

            if (itinerary.description != null)
              Text(
                itinerary.description!,
                style: AppTextStyles.body(color: AppColors.gray600),
              ),

            AppSpacing.gapHeightL,

            // Quick stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    label: 'Duration',
                    value: '${itinerary.totalDays} Days',
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.location_city,
                    label: 'Cities',
                    value: '${itinerary.cities?.length ?? 1}',
                  ),
                ),
              ],
            ),

            AppSpacing.gapHeightXL,

            // Day-by-day itinerary section
            Text(
              'Day-by-Day Itinerary',
              style: AppTextStyles.h3(color: AppColors.gray900),
            ),

            AppSpacing.gapHeightM,

            // Placeholder for day-by-day view
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.info100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                border: Border.all(color: AppColors.info300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.event_note, size: 48, color: AppColors.info500),
                  AppSpacing.gapHeightM,
                  Text(
                    'Day-by-Day Planning',
                    style: AppTextStyles.h4(color: AppColors.gray900),
                  ),
                  AppSpacing.gapHeightS,
                  Text(
                    'Start adding activities to each day of your trip',
                    style: AppTextStyles.body(color: AppColors.gray600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          AppSpacing.gapHeightS,
          Text(
            label,
            style: AppTextStyles.caption(color: AppColors.gray600),
          ),
          Text(
            value,
            style: AppTextStyles.h4(color: AppColors.gray900),
          ),
        ],
      ),
    );
  }
}
