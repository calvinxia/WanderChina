import 'package:flutter/material.dart';

/// WanderChina Color System
/// Based on MVP v2.0 Design Specifications
class AppColors {
  AppColors._();

  // ============================================================================
  // PRIMARY COLORS - Jade Green (Custom scale, not Material Green)
  // ============================================================================
  static const Color jade50 = Color(0xFFE4F9ED);
  static const Color jade100 = Color(0xFFB0EDC8);
  static const Color jade200 = Color(0xFF6EDBA0);
  static const Color jade300 = Color(0xFF4DD18D);
  static const Color jade400 = Color(0xFF32C87A);
  static const Color jade500 = Color(0xFF1FB368); // Brand primary
  static const Color jade600 = Color(0xFF189A58);
  static const Color jade700 = Color(0xFF14804A);
  static const Color jade900 = Color(0xFF0D5230);

  static const Color primary = jade500;
  static const Color primaryDark = jade700;
  static const Color primaryLight = jade400;

  // ============================================================================
  // VOICE / ACCENT COLORS
  // ============================================================================
  static const Color orange = Color(0xFFE8723A); // Voice button, high-priority POI badge

  // ============================================================================
  // LOGO / BRAND MARK COLORS
  // ============================================================================
  static const Color logoDark = Color(0xFF1A1A1E); // Logo background
  static const Color logoBiscuit = Color(0xFFE8D5C4); // Logo WW stroke color
  static const Color warmGold = Color(0xFFD4A853); // Onboarding slide 2, language accent

  // ============================================================================
  // INK (Deep background series — header, onboarding, splash)
  // ============================================================================
  static const Color ink900 = Color(0xFF16162A); // Deepest, main background
  static const Color ink800 = Color(0xFF1E1E38);
  static const Color ink700 = Color(0xFF2A2A48); // Header gradient end
  static const Color ink600 = Color(0xFF383860); // Mountain silhouette front layer
  static const Color ink500 = Color(0xFF50507A);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  // Error (Red)
  static const Color error100 = Color(0xFFFFCDD2);
  static const Color error300 = Color(0xFFEF5350);
  static const Color error500 = Color(0xFFF44336);
  static const Color error700 = Color(0xFFC62828);
  static const Color error = error500;

  // Success (Green)
  static const Color success100 = Color(0xFFD4F4E2);
  static const Color success300 = Color(0xFF6FDB9F);
  static const Color success500 = Color(0xFF10B759);
  static const Color success700 = Color(0xFF0F7B3E);
  static const Color success = success500;

  // Warning (Yellow/Orange)
  static const Color warning100 = Color(0xFFFFE9B8);
  static const Color warning300 = Color(0xFFFFC34D);
  static const Color warning500 = Color(0xFFFFA500);
  static const Color warning700 = Color(0xFFB76E00);
  static const Color warning = warning500;

  // Info (Blue)
  static const Color info100 = Color(0xFFBBDEFB);
  static const Color info300 = Color(0xFF64B5F6);
  static const Color info500 = Color(0xFF2196F3);
  static const Color info700 = Color(0xFF1565C0);
  static const Color info = info500;

  // ============================================================================
  // NEUTRAL COLORS - Gray Scale
  // ============================================================================
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  static const Color textPrimary = gray900;
  static const Color textSecondary = gray700;
  static const Color border = gray200;
  static const Color background = gray50;

  // ============================================================================
  // SECONDARY COLORS - Sandstone (kept for backwards compatibility)
  // ============================================================================
  static const Color sand900 = Color(0xFFC4A87D);
  static const Color sand700 = Color(0xFFD9C299);
  static const Color sand500 = Color(0xFFF5E4C3);
  static const Color sand300 = Color(0xFFF8EDDA);
  static const Color sand100 = Color(0xFFFBF6ED);

  static const Color secondary = sand500;
  static const Color secondaryDark = sand700;
  static const Color secondaryLight = sand300;

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
    colors: [jade500, jade400],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sand500, sand300],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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

  // Header gradient (INK series)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment(0.2, -1),
    end: Alignment(-0.2, 1),
    colors: [ink900, ink700],
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
        return success;
      case 'intermediate':
        return warmGold;
      case 'advanced':
        return error500;
      case 'expert':
        return const Color(0xFFC62828);
      case 'master':
        return jade700;
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
        return const Color(0xFF2196F3); // Blue
      case 'epic':
        return const Color(0xFF9C27B0); // Purple
      case 'legendary':
        return warmGold;
      default:
        return gray500;
    }
  }

  /// Get category color
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return orange;
      case 'accommodation':
        return const Color(0xFF4ECDC4);
      case 'transport':
        return const Color(0xFF45B7D1);
      case 'attractions':
        return const Color(0xFFFFA07A);
      case 'nature':
        return const Color(0xFF98D8C8);
      case 'culture':
        return const Color(0xFFBA68C8);
      case 'shopping':
        return warmGold;
      default:
        return jade500;
    }
  }
}
