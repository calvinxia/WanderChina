import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/challenge.dart';
import '../../widgets/buttons/primary_button.dart';

/// Challenge Detail Screen
/// 挑战详情页
class ChallengeDetailScreen extends StatelessWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            _buildCoverImage(),

            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.gapHeightM,

                  // Title and difficulty
                  Text(
                    challenge.title,
                    style: AppTextStyles.h2(color: AppColors.gray900),
                  ),

                  AppSpacing.gapHeightS,

                  Row(
                    children: [
                      _buildBadge(
                        challenge.difficulty.toUpperCase(),
                        AppColors.getDifficultyColor(challenge.difficulty),
                      ),
                      SizedBox(width: AppSpacing.s),
                      _buildBadge(
                        challenge.category.toUpperCase(),
                        AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.s),
                      _buildBadge(
                        '${challenge.totalPoints} PTS',
                        AppColors.warning500,
                      ),
                    ],
                  ),

                  AppSpacing.gapHeightM,

                  // Description
                  Text(
                    challenge.description,
                    style: AppTextStyles.body(color: AppColors.gray700),
                  ),

                  AppSpacing.gapHeightL,

                  // Stats
                  _buildStats(),

                  AppSpacing.gapHeightXL,

                  // Checkpoints
                  Text(
                    'Checkpoints (${challenge.checkpoints.length})',
                    style: AppTextStyles.h3(color: AppColors.gray900),
                  ),

                  AppSpacing.gapHeightM,

                  ...challenge.checkpoints.map((cp) => _buildCheckpoint(cp)),

                  AppSpacing.gapHeightXL,

                  // Action button
                  if (challenge.isActive)
                    PrimaryButton(
                      text: 'Continue Challenge',
                      onPressed: () => _continueChallenge(context),
                      isFullWidth: true,
                    )
                  else if (challenge.isCompleted)
                    PrimaryButton(
                      text: 'View Certificate',
                      onPressed: () {},
                      isFullWidth: true,
                    )
                  else
                    PrimaryButton(
                      text: 'Start Challenge',
                      onPressed: () => _startChallenge(context),
                      isFullWidth: true,
                    ),

                  AppSpacing.gapHeightXL,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        image: challenge.coverImageUrl != null
            ? DecorationImage(
                image: NetworkImage(challenge.coverImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
        gradient: challenge.coverImageUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.info500],
              )
            : null,
      ),
      child: challenge.coverImageUrl == null
          ? Center(
              child: Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.white.withOpacity(0.7),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusS),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(color: color)
            .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            label: 'Est. Time',
            value: '${challenge.estimatedTimeHours}h',
          ),
        ),
        SizedBox(width: AppSpacing.m),
        Expanded(
          child: _buildStatCard(
            icon: Icons.location_on_outlined,
            label: 'Checkpoints',
            value: '${challenge.checkpoints.length}',
          ),
        ),
        SizedBox(width: AppSpacing.m),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            label: 'Completed',
            value: '${challenge.completionCount}',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          SizedBox(height: AppSpacing.xs),
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

  Widget _buildCheckpoint(Checkpoint checkpoint) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.m),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: checkpoint.isCompleted
              ? AppColors.success100
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          border: Border.all(
            color: checkpoint.isCompleted
                ? AppColors.success500
                : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            // Number circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: checkpoint.isCompleted
                    ? AppColors.success500
                    : AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: checkpoint.isCompleted
                    ? Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '${checkpoint.order}',
                        style: AppTextStyles.button(color: AppColors.gray700),
                      ),
              ),
            ),

            SizedBox(width: AppSpacing.m),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkpoint.placeName,
                    style: AppTextStyles.button(color: AppColors.gray900),
                  ),
                  if (checkpoint.instructions != null)
                    Text(
                      checkpoint.instructions!,
                      style: AppTextStyles.caption(color: AppColors.gray600),
                    ),
                ],
              ),
            ),

            // Points
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusS),
              ),
              child: Text(
                '+${checkpoint.points}',
                style: AppTextStyles.caption(color: AppColors.warning500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChallenge(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Challenge started! Good luck!'),
          ],
        ),
        backgroundColor: AppColors.success500,
      ),
    );
    Navigator.pop(context);
  }

  void _continueChallenge(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation to next checkpoint coming soon!')),
    );
  }
}
