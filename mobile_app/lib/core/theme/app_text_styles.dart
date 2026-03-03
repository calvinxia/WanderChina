import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// WanderChina Typography System
/// Based on Figma Design System
class AppTextStyles {
  AppTextStyles._();

  // Base font family
  static String get _fontFamily => GoogleFonts.inter().fontFamily!;
  static String get _chineseFontFamily => GoogleFonts.notoSansSc().fontFamily!;

  // ============================================================================
  // HEADINGS
  // ============================================================================

  /// H1: 32px, Bold, -0.5px letter spacing
  /// Usage: Page titles
  static TextStyle h1({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.5,
        color: color ?? AppColors.gray900,
      );

  /// H2: 28px, Bold, -0.3px letter spacing
  /// Usage: Section headers
  static TextStyle h2({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.3,
        color: color ?? AppColors.gray900,
      );

  /// H3: 24px, Semibold, 0px letter spacing
  /// Usage: Card titles
  static TextStyle h3({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: 0,
        color: color ?? AppColors.gray900,
      );

  /// H4: 20px, Semibold, 0px letter spacing
  /// Usage: Subsection headers
  static TextStyle h4({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: 0,
        color: color ?? AppColors.gray900,
      );

  // ============================================================================
  // BODY TEXT
  // ============================================================================

  /// Body Large: 18px, Regular, 0px letter spacing
  /// Usage: Prominent body text
  static TextStyle bodyLarge({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        letterSpacing: 0,
        color: color ?? AppColors.gray800,
      );

  /// Body: 16px, Regular, 0px letter spacing
  /// Usage: Default body text
  static TextStyle body({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: 0,
        color: color ?? AppColors.gray800,
      );

  /// Body Small: 14px, Regular, 0px letter spacing
  /// Usage: Secondary text
  static TextStyle bodySmall({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: 0,
        color: color ?? AppColors.gray700,
      );

  // ============================================================================
  // SPECIAL TEXT
  // ============================================================================

  /// Caption: 12px, Regular, 0.3px letter spacing
  /// Usage: Captions, labels, timestamps
  static TextStyle caption({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0.3,
        color: color ?? AppColors.gray600,
      );

  /// Overline: 11px, Medium, 1px letter spacing (uppercase)
  /// Usage: Uppercase labels
  static TextStyle overline({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        letterSpacing: 1,
        color: color ?? AppColors.gray700,
      );

  // ============================================================================
  // BUTTON TEXT
  // ============================================================================

  /// Button Large: 18px, Semibold, 0.5px letter spacing
  /// Usage: Primary CTAs
  static TextStyle buttonLarge({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        letterSpacing: 0.5,
        color: color ?? Colors.white,
      );

  /// Button: 16px, Semibold, 0.5px letter spacing
  /// Usage: Standard buttons
  static TextStyle button({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 20 / 16,
        letterSpacing: 0.5,
        color: color ?? Colors.white,
      );

  /// Button Small: 14px, Medium, 0.3px letter spacing
  /// Usage: Small buttons
  static TextStyle buttonSmall({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
        letterSpacing: 0.3,
        color: color ?? Colors.white,
      );

  // ============================================================================
  // SPECIALIZED STYLES
  // ============================================================================

  /// Link text
  static TextStyle link({Color? color}) => body(
        color: color ?? AppColors.jade500,
      ).copyWith(
        decoration: TextDecoration.underline,
      );

  /// Error text
  static TextStyle error({Color? color}) => bodySmall(
        color: color ?? AppColors.error500,
      );

  /// Success text
  static TextStyle success({Color? color}) => bodySmall(
        color: color ?? AppColors.success500,
      );

  /// Price text
  static TextStyle price({Color? color}) => body(
        color: color ?? AppColors.jade500,
      ).copyWith(
        fontWeight: FontWeight.w600,
      );

  /// Rating text
  static TextStyle rating({Color? color}) => caption(
        color: color ?? AppColors.gray700,
      ).copyWith(
        fontWeight: FontWeight.w500,
      );

  /// Badge text
  static TextStyle badge({Color? color}) => caption(
        color: color ?? AppColors.jade700,
      ).copyWith(
        fontWeight: FontWeight.w600,
      );

  /// Timestamp
  static TextStyle timestamp({Color? color}) => caption(
        color: color ?? AppColors.gray500,
      );

  /// Username
  static TextStyle username({Color? color}) => body(
        color: color ?? AppColors.gray900,
      ).copyWith(
        fontWeight: FontWeight.w600,
      );

  /// Location text
  static TextStyle location({Color? color}) => caption(
        color: color ?? AppColors.gray600,
      );

  /// Tab label active
  static TextStyle tabActive({Color? color}) => caption(
        color: color ?? AppColors.jade500,
      ).copyWith(
        fontWeight: FontWeight.w600,
      );

  /// Tab label inactive
  static TextStyle tabInactive({Color? color}) => caption(
        color: color ?? AppColors.gray500,
      );

  // ============================================================================
  // NUMBER STYLES (for stats, points, etc.)
  // ============================================================================

  /// Large number (stats)
  static TextStyle numberLarge({Color? color}) => TextStyle(
        fontFamily: GoogleFonts.robotoMono().fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color ?? AppColors.jade500,
      );

  /// Medium number
  static TextStyle numberMedium({Color? color}) => TextStyle(
        fontFamily: GoogleFonts.robotoMono().fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0,
        color: color ?? AppColors.jade500,
      );

  /// Small number
  static TextStyle numberSmall({Color? color}) => TextStyle(
        fontFamily: GoogleFonts.robotoMono().fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0,
        color: color ?? AppColors.gray800,
      );

  // ============================================================================
  // CHINESE TEXT STYLES
  // ============================================================================

  /// Chinese heading
  static TextStyle chineseH1({Color? color}) => h1(color: color).copyWith(
        fontFamily: _chineseFontFamily,
      );

  static TextStyle chineseH2({Color? color}) => h2(color: color).copyWith(
        fontFamily: _chineseFontFamily,
      );

  static TextStyle chineseH3({Color? color}) => h3(color: color).copyWith(
        fontFamily: _chineseFontFamily,
      );

  /// Chinese body
  static TextStyle chineseBody({Color? color}) => body(color: color).copyWith(
        fontFamily: _chineseFontFamily,
      );

  static TextStyle chineseBodySmall({Color? color}) => bodySmall(color: color).copyWith(
        fontFamily: _chineseFontFamily,
      );
}
