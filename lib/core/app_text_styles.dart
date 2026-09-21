import 'package:flutter/material.dart';
import 'app_colors.dart';

/// أنماط النصوص المشتركة بين صفحتي تسجيل الدخول والتسجيل
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle brandScale = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.brandScale,
    letterSpacing: 0.2,
  );

  static const TextStyle brandFlow = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.brandFlow,
    letterSpacing: 0.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textLabel,
  );

  static const TextStyle fieldInput = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle fieldPlaceholder = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.placeholder,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle footerText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle footerLink = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.linkTeal,
  );

  static const TextStyle hintBoxTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle hintItem = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.hintTextInactive,
  );

  static const TextStyle forgotPassword = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.linkPurple,
  );
}
