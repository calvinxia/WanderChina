import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Place Card - Used in Discover, Nearby, and Recommendations
/// Based on Figma design - Components/Cards
class PlaceCard extends StatefulWidget {
  final String name;
  final String location;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final String? category;
  final String? distance;
  final List<String>? tags;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final PlaceCardSize size;

  const PlaceCard({
    Key? key,
    required this.name,
    required this.location,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.category,
    this.distance,
    this.tags,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
    this.size = PlaceCardSize.medium,
  }) : super(key: key);

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: Duration(milliseconds: 100),
        child: Container(
          width: _getWidth(),
          height: _getHeight(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.08),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              _buildImageSection(),

              // Content section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Distance
                      if (widget.category != null || widget.distance != null)
                        _buildCategoryDistance(),

                      AppSpacing.gapHeightXS,

                      // Name
                      Text(
                        widget.name,
                        style: AppTextStyles.h4(color: AppColors.gray900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      AppSpacing.gapXXS,

                      // Location
                      Flexible(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppColors.gray500,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.location,
                                style: AppTextStyles.bodySmall(
                                  color: AppColors.gray600,
                                ).copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Spacer(),

                      // Rating & Tags
                      _buildBottomRow(),
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
          height: _getImageHeight(),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusL),
            ),
            image: widget.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.imageUrl == null
              ? Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: AppColors.gray300,
                  ),
                )
              : null,
        ),

        // Gradient overlay
        Container(
          height: _getImageHeight(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusL),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),

        // Favorite button
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: _buildFavoriteButton(),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: widget.onFavorite,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: widget.isFavorite ? AppColors.error500 : AppColors.gray600,
        ),
      ),
    ).animate(target: widget.isFavorite ? 1 : 0).scale(
          begin: Offset(1, 1),
          end: Offset(1.2, 1.2),
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildCategoryDistance() {
    return Row(
      children: [
        if (widget.category != null) ...[
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.getCategoryColor(widget.category!)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusS),
              ),
              child: Text(
                widget.category!,
                style: AppTextStyles.caption(
                  color: AppColors.getCategoryColor(widget.category!),
                ).copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: 4),
        ],
        if (widget.distance != null)
          Flexible(
            child: Text(
              widget.distance!,
              style: AppTextStyles.caption(color: AppColors.gray500)
                  .copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        // Rating
        if (widget.rating != null) ...[
          Icon(Icons.star, size: 11, color: AppColors.warning500),
          SizedBox(width: 2),
          Text(
            widget.rating!.toStringAsFixed(1),
            style: AppTextStyles.bodySmall(color: AppColors.gray900)
                .copyWith(fontSize: 10),
          ),
        ],
      ],
    );
  }

  double _getWidth() {
    switch (widget.size) {
      case PlaceCardSize.small:
        return 160;
      case PlaceCardSize.medium:
        return 200;
      case PlaceCardSize.large:
        return double.infinity;
    }
  }

  double _getHeight() {
    switch (widget.size) {
      case PlaceCardSize.small:
        return 220;
      case PlaceCardSize.medium:
        return 260;
      case PlaceCardSize.large:
        return 140;
    }
  }

  double _getImageHeight() {
    switch (widget.size) {
      case PlaceCardSize.small:
        return 100;
      case PlaceCardSize.medium:
        return 130;
      case PlaceCardSize.large:
        return 140;
    }
  }
}

enum PlaceCardSize { small, medium, large }
