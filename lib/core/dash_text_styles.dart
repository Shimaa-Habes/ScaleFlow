import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// أنماط النصوص الخاصة بشاشات الـ Dashboard (Home + Project Details)،
/// معتمدة بالضبط على "02 — Typography — Inter" من صفحة الـ Figma:
/// Regular 400 / Medium 500 / Semi bold 600 / Bold 700
class DashTextStyles {
  DashTextStyles._();

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color color = AppColors.darkCharcoal,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  /// Bold 700 · Screen titles, main metrics (e.g. "Dashboard", "84%")
  static TextStyle screenTitle({Color? color}) => _inter(
        size: 24,
        weight: FontWeight.w700,
        color: color ?? AppColors.darkCharcoal,
      );

  static TextStyle metric({Color? color, double size = 28}) => _inter(
        size: size,
        weight: FontWeight.w700,
        color: color ?? AppColors.darkCharcoal,
      );

  /// Semi bold 600 · Card titles, section titles (e.g. "Website redesign")
  static TextStyle cardTitle({Color? color, double size = 16}) => _inter(
        size: size,
        weight: FontWeight.w600,
        color: color ?? AppColors.darkCharcoal,
      );

  static TextStyle sectionTitle({Color? color, double size = 17}) => _inter(
        size: size,
        weight: FontWeight.w600,
        color: color ?? AppColors.darkCharcoal,
      );

  /// Medium 500 · Labels, navigation, buttons (e.g. "Healthy · Low risk")
  static TextStyle label({Color? color, double size = 13}) => _inter(
        size: size,
        weight: FontWeight.w500,
        color: color ?? AppColors.darkCharcoal,
      );

  static TextStyle navLabel({Color? color, double size = 11}) => _inter(
        size: size,
        weight: FontWeight.w500,
        color: color ?? AppColors.darkCharcoal,
      );

  /// Regular 400 · Body, descriptions, supporting text
  static TextStyle body({Color? color, double size = 14}) => _inter(
        size: size,
        weight: FontWeight.w400,
        color: color ?? const Color(0xFF6C7580),
        height: 1.35,
      );

  static TextStyle caption({Color? color, double size = 12}) => _inter(
        size: size,
        weight: FontWeight.w400,
        color: color ?? const Color(0xFF8A939C),
      );
}
