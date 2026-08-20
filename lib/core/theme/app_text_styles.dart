import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Heading font: Cinzel Decorative (via Google Fonts)
  static TextStyle get displayLarge => GoogleFonts.cinzelDecorative(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.goldAccent,
        letterSpacing: 2.0,
      );

  static TextStyle get displayMedium => GoogleFonts.cinzelDecorative(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.goldAccent,
        letterSpacing: 1.5,
      );

  static TextStyle get displaySmall => GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.parchmentBeige,
        letterSpacing: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.cinzelDecorative(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.parchmentBeige,
        letterSpacing: 1.0,
      );

  static TextStyle get headlineMedium => GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.parchmentBeige,
        letterSpacing: 0.8,
      );

  static TextStyle get headlineSmall => GoogleFonts.cinzelDecorative(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.parchmentBeige,
        letterSpacing: 0.5,
      );

  // Body font: Noto Serif JP (via Google Fonts)
  static TextStyle get bodyLarge => GoogleFonts.notoSerifJp(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.notoSerifJp(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodySmall => GoogleFonts.notoSerifJp(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.notoSerifJp(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.parchmentBeige,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => GoogleFonts.notoSerifJp(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      );

  static TextStyle get labelSmall => GoogleFonts.notoSerifJp(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  // Special styles
  static TextStyle get battleReport => GoogleFonts.notoSerifJp(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.inkBrown,
        height: 1.8,
      );

  static TextStyle get goldTitle => GoogleFonts.cinzelDecorative(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.goldAccent,
        shadows: const [
          Shadow(color: AppColors.goldLight, blurRadius: 4),
        ],
      );

  static TextStyle get ticketCount => GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.goldLight,
      );
}
