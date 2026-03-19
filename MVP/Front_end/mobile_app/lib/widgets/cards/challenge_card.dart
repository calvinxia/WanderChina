import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Challenge Card - Used in Home and Challenges screens
/// Based on Figma design - Components/Challenge Card
class ChallengeCard extends StatefulWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final int points;
  final String difficulty; // 'easy', 'medium', 'hard'
  final int totalSteps;
  final int completedSteps;
  final String? timeRemaining;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.points,
    required this.difficulty,
    required this.totalSteps,
    this.completedSteps = 0,
    this.timeRemaining,
    this.isActive = false,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.completedSteps / widget.totalSteps;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: AppSpacing.challengeCardWidth,
          height: AppSpacing.challengeCardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with overlay
              _buildImageSection(),

              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Difficulty & Points
                      _buildHeaderRow(),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        widget.title,
                        style: AppTextStyles.button(color: AppColors.gray900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // Description
                      Flexible(
                        child: Text(
                          widget.description,
                          style: AppTextStyles.caption(color: AppColors.gray600)
                              .copyWith(fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Progress section
                      if (!widget.isCompleted) _buildProgressSection(progress),

                      // Completed badge
                      if (widget.isCompleted) _buildCompletedBadge(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXL),
            ),
            image: widget.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.imageUrl == null
              ? const Center(
                  child: Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: AppColors.gray300,
                  ),
                )
              : null,
        ),

        // Gradient overlay
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXL),
            ),
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

        // Active badge
        if (widget.isActive)
          Positioned(
            top: AppSpacing.s,
            left: AppSpacing.s,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeOut(duration: 1000.ms)
                      .then()
                      .fadeIn(duration: 1000.ms),
                  const SizedBox(width: 6),
                  Text(
                    'Active',
                    style: AppTextStyles.caption(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        // Time remaining
        if (widget.timeRemaining != null && !widget.isCompleted)
          Positioned(
            top: AppSpacing.s,
            right: AppSpacing.s,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.timeRemaining!,
                    style: AppTextStyles.caption(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // Difficulty badge
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.getDifficultyColor(widget.difficulty)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusS),
              border: Border.all(
                color: AppColors.getDifficultyColor(widget.difficulty),
                width: 1,
              ),
            ),
            child: Text(
              widget.difficulty.toUpperCase(),
              style: AppTextStyles.caption(
                color: AppColors.getDifficultyColor(widget.difficulty),
              ).copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        const Spacer(),

        // Points
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.warning500, AppColors.warning300],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 3),
              Text(
                '${widget.points} pts',
                style: AppTextStyles.caption(color: Colors.white)
                    .copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusS),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(color: AppColors.gray100),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Progress text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.completedSteps}/${widget.totalSteps} steps',
              style: AppTextStyles.caption(color: AppColors.gray600)
                  .copyWith(fontSize: 10),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTextStyles.caption(color: AppColors.primary)
                  .copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.success100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: AppColors.success500, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: AppColors.success500,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Completed!',
            style: AppTextStyles.button(color: AppColors.success700),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms);
  }
}
