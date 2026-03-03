import 'package:flutter/material.dart';

/// WanderChina Color System
/// Based on Figma Design System
class AppColors {
  AppColors._();

  // ============================================================================
  // PRIMARY COLORS - Jade Green
  // ============================================================================
  static const Color jade900 = Color(0xFF1B5E3D);
  static const Color jade700 = Color(0xFF2E8B57);
  static const Color jade500 = Color(0xFF3BAA7A); // Main brand color
  static const Color jade300 = Color(0xFF6BC99D);
  static const Color jade100 = Color(0xFFB8E6D5);

  static const Color primary = jade500;
  static const Color primaryDark = jade700;
  static const Color primaryLight = jade300;

  // ============================================================================
  // SECONDARY COLORS - Sandstone
  // ============================================================================
  static const Color sand900 = Color(0xFFC4A87D);
  static const Color sand700 = Color(0xFFD9C299);
  static const Color sand500 = Color(0xFFF5E4C3); // Accent color
  static const Color sand300 = Color(0xFFF8EDDA);
  static const Color sand100 = Color(0xFFFBF6ED);

  static const Color secondary = sand500;
  static const Color secondaryDark = sand700;
  static const Color secondaryLight = sand300;

  // ============================================================================
  // NEUTRAL COLORS - Gray Scale
  // ============================================================================
  static const Color gray900 = Color(0xFF1A1A1A);
  static const Color gray800 = Color(0xFF333333); // Primary text
  static const Color gray700 = Color(0xFF4D4D4D);
  static const Color gray600 = Color(0xFF666666);
  static const Color gray500 = Color(0xFF808080);
  static const Color gray400 = Color(0xFF999999); // Secondary text
  static const Color gray300 = Color(0xFFB3B3B3);
  static const Color gray200 = Color(0xFFCCCCCC); // Borders
  static const Color gray100 = Color(0xFFE6E6E6); // Light backgrounds
  static const Color gray50 = Color(0xFFF5F5F5);

  static const Color textPrimary = gray800;
  static const Color textSecondary = gray400;
  static const Color border = gray200;
  static const Color background = gray50;

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  // Success (Green)
  static const Color success700 = Color(0xFF0F7B3E);
  static const Color success500 = Color(0xFF10B759);
  static const Color success300 = Color(0xFF6FDB9F);
  static const Color success100 = Color(0xFFD4F4E2);
  static const Color success = success500;

  // Warning (Yellow)
  static const Color warning700 = Color(0xFFB76E00);
  static const Color warning500 = Color(0xFFFFA500);
  static const Color warning300 = Color(0xFFFFC34D);
  static const Color warning100 = Color(0xFFFFE9B8);
  static const Color warning = warning500;

  // Error (Red)
  static const Color error700 = Color(0xFFC62828);
  static const Color error500 = Color(0xFFF44336);
  static const Color error300 = Color(0xFFEF5350);
  static const Color error100 = Color(0xFFFFCDD2);
  static const Color error = error500;

  // Info (Blue)
  static const Color info700 = Color(0xFF1565C0);
  static const Color info500 = Color(0xFF2196F3);
  static const Color info300 = Color(0xFF64B5F6);
  static const Color info100 = Color(0xFFBBDEFB);
  static const Color info = info500;

  // ============================================================================
  // DARK MODE COLORS
  // ============================================================================
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBackgroundSecondary = Color(0xFF1E1E1E);
  static const Color darkBackgroundTertiary = Color(0xFF2C2C2C);
  static const Color darkSurface = Color(0xFF1F1F1F);
  static const Color darkCard = Color(0xFF242424);

  // Dark mode text (with opacity)
  static Color get darkTextPrimary => Colors.white.withOpacity(0.87);
  static Color get darkTextSecondary => Colors.white.withOpacity(0.60);
  static Color get darkTextDisabled => Colors.white.withOpacity(0.38);

  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [jade500, jade300],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sand500, sand300],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success500, success300],
  );

  // Hero gradient for splash/onboarding
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [jade100, Colors.white],
  );

  // Challenge card gradient
  static const LinearGradient challengeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [jade500, jade700],
  );

  // ============================================================================
  // SHADOWS
  // ============================================================================
  static const BoxShadow shadowSm = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    offset: Offset(0, 2),
    blurRadius: 4,
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  static const BoxShadow shadowXl = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.12),
    offset: Offset(0, 8),
    blurRadius: 24,
  );

  static const BoxShadow shadow2xl = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.15),
    offset: Offset(0, 16),
    blurRadius: 48,
  );

  // Jade shadow for primary buttons
  static BoxShadow get jadeShadow => BoxShadow(
    color: jade500.withOpacity(0.2),
    offset: const Offset(0, 2),
    blurRadius: 8,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color by difficulty level
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return success500;
      case 'intermediate':
        return warning500;
      case 'advanced':
        return error500;
      case 'expert':
        return error700;
      case 'master':
        return jade900;
      default:
        return gray500;
    }
  }

  /// Get color by rarity level
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return gray500;
      case 'rare':
        return info500;
      case 'epic':
        return Color(0xFF9C27B0); // Purple
      case 'legendary':
        return Color(0xFFFFD700); // Gold
      default:
        return gray500;
    }
  }

  /// Get category color
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Color(0xFFFF6B6B);
      case 'accommodation':
        return Color(0xFF4ECDC4);
      case 'transport':
        return Color(0xFF45B7D1);
      case 'attractions':
        return Color(0xFFFFA07A);
      case 'nature':
        return Color(0xFF98D8C8);
      case 'culture':
        return Color(0xFFBA68C8);
      case 'shopping':
        return Color(0xFFFFB74D);
      default:
        return jade500;
    }
  }
}
