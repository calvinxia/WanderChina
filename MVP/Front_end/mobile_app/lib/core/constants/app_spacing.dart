import 'package:flutter/material.dart';

/// WanderChina Spacing System
/// Based on 8-point grid system
class AppSpacing {
  AppSpacing._();

  // ============================================================================
  // SPACING VALUES (8-point grid)
  // ============================================================================
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusPill = 999.0;
  static const double radiusCircle = 999.0;

  // ============================================================================
  // SCREEN PADDING
  // ============================================================================
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets screenPaddingV = EdgeInsets.symmetric(vertical: l);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: m,
    vertical: l,
  );

  // ============================================================================
  // CARD PADDING
  // ============================================================================
  static const EdgeInsets cardPadding = EdgeInsets.all(m);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(s);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(l);

  // ============================================================================
  // LIST PADDING
  // ============================================================================
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: m,
    vertical: s,
  );
  static const EdgeInsets listPadding = EdgeInsets.all(m);

  // ============================================================================
  // BUTTON PADDING
  // ============================================================================
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: l,
    vertical: s,
  );
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: m,
    vertical: xs,
  );
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: m,
  );

  // ============================================================================
  // ICON SIZES
  // ============================================================================
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ============================================================================
  // AVATAR SIZES
  // ============================================================================
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXLarge = 96.0;

  // ============================================================================
  // BUTTON HEIGHTS
  // ============================================================================
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;

  // ============================================================================
  // INPUT HEIGHTS
  // ============================================================================
  static const double inputHeight = 48.0;
  static const double searchBarHeight = 44.0;

  // ============================================================================
  // APP BAR HEIGHTS
  // ============================================================================
  static const double appBarHeight = 56.0;
  static const double appBarHeightIOS = 44.0;

  // ============================================================================
  // BOTTOM NAV BAR HEIGHTS
  // ============================================================================
  static const double bottomNavBarHeight = 56.0;
  static const double bottomNavBarHeightIOS = 80.0; // With safe area

  // ============================================================================
  // CARD SIZES
  // ============================================================================
  static const double placeCardHeight = 120.0;
  static const double challengeCardWidth = 280.0;
  static const double challengeCardHeight = 360.0;

  // ============================================================================
  // IMAGE SIZES
  // ============================================================================
  static const double imageThumbnailSize = 100.0;
  static const double imageSmall = 120.0;
  static const double imageMedium = 240.0;
  static const double imageLarge = 360.0;

  // ============================================================================
  // HERO IMAGE HEIGHTS
  // ============================================================================
  static const double heroImageHeight = 240.0;
  static const double heroImageHeightLarge = 320.0;

  // ============================================================================
  // TOUCH TARGETS (minimum 44x44 for accessibility)
  // ============================================================================
  static const double minTouchTarget = 44.0;

  // ============================================================================
  // SAFE AREA INSETS
  // ============================================================================
  static const double safeAreaTopIOS = 44.0;
  static const double safeAreaBottomIOS = 34.0;
  static const double safeAreaTopAndroid = 24.0;
  static const double safeAreaBottomAndroid = 0.0;

  // ============================================================================
  // SEPARATOR HEIGHTS
  // ============================================================================
  static const double separatorHeight = 1.0;
  static const double thickSeparatorHeight = 8.0;

  // ============================================================================
  // GAP WIDGETS (for Flex layouts)
  // ============================================================================
  static const Widget gapXXS = SizedBox(width: xxs, height: xxs);
  static const Widget gapXS = SizedBox(width: xs, height: xs);
  static const Widget gapS = SizedBox(width: s, height: s);
  static const Widget gapM = SizedBox(width: m, height: m);
  static const Widget gapL = SizedBox(width: l, height: l);
  static const Widget gapXL = SizedBox(width: xl, height: xl);
  static const Widget gapXXL = SizedBox(width: xxl, height: xxl);

  static const Widget gapWidthXS = SizedBox(width: xs);
  static const Widget gapWidthS = SizedBox(width: s);
  static const Widget gapWidthM = SizedBox(width: m);
  static const Widget gapWidthL = SizedBox(width: l);
  static const Widget gapWidthXL = SizedBox(width: xl);

  static const Widget gapHeightXS = SizedBox(height: xs);
  static const Widget gapHeightS = SizedBox(height: s);
  static const Widget gapHeightM = SizedBox(height: m);
  static const Widget gapHeightL = SizedBox(height: l);
  static const Widget gapHeightXL = SizedBox(height: xl);
  static const Widget gapHeightXXL = SizedBox(height: xxl);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create horizontal gap
  static Widget horizontalGap(double width) => SizedBox(width: width);

  /// Create vertical gap
  static Widget verticalGap(double height) => SizedBox(height: height);

  /// Create square gap
  static Widget gap(double size) => SizedBox(width: size, height: size);
}
