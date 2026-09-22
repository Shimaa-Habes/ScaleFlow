import 'package:flutter/material.dart';

/// كل الألوان المستخدمة بالتصميم، مسحوبة من صور الـ Figma
/// حتى نضمن إنو أي صفحة جديدة بتستخدم نفس الهوية البصرية
class AppColors {
  AppColors._();

  // خلفية الشاشة (رمادي فاتح جداً بميل أخضر خفيف)
  static const Color background = Color(0xFFF4F6F6);

  // ألوان اللوغو (التدرج الأزرق-الأخضر) وكلمة Flow البرتقالية
  static const Color logoTeal = Color(0xFF1E88A8);
  static const Color logoGreen = Color(0xFF4CAF50);
  static const Color brandScale = Color(0xFF1A1A1A);
  static const Color brandFlow = Color(0xFFF26B4E);

  // نصوص
  static const Color textPrimary = Color(0xFF16191C);
  static const Color textSecondary = Color(0xFF6C7580);
  static const Color textLabel = Color(0xFF1F2429);
  static const Color placeholder = Color(0xFF9AA5AF);

  // الحقول (input fields)
  static const Color fieldBackground = Color(0xFFFFFFFF);
  static const Color fieldBorder = Color(0xFFD8DEE2);
  static const Color fieldBorderFocused = Color(0xFF1670A6);
  static const Color fieldBorderError = Color(0xFFE04F4F);
  static const Color fieldBorderValid = Color(0xFF2FA86A);

  // صندوق شروط كلمة السر
  static const Color hintBoxBackground = Color(0xFFEEF2F3);
  static const Color hintTextInactive = Color(0xFF8A939C);
  static const Color hintTextActive = Color(0xFF2FA86A);

  // الأزرار والروابط
  static const Color primaryButton = Color(0xFF1670A6);
  static const Color linkTeal = Color(0xFF17A2A2);
  static const Color linkPurple = Color(0xFF9B4DCA);

  static const Color error = Color(0xFFE04F4F);

  // ============================================================
  // نظام الألوان الرسمي من Figma (Color System panel) — هاي نفس
  // القيم بالضبط الموجودة بصفحة "01 — Color system"، وبتنستخدم
  // بشاشتي Home و Project Details (ودائماً أي شاشة جديدة لاحقاً)
  // ============================================================

  /// Dark charcoal #2C2D30 — Primary text, headings, navigation text, icons
  static const Color darkCharcoal = Color(0xFF2C2D30);

  /// Purple #6C5CE7 — AI, insights, AI actions, primary progress accents
  static const Color aiPurple = Color(0xFF6C5CE7);

  /// Green #61BD4F — Healthy, success, completed, on track
  static const Color statusGreen = Color(0xFF61BD4F);

  /// Cyan #26C6DA — Data, information, active projects
  static const Color dataCyan = Color(0xFF26C6DA);

  /// Yellow #F2D600 — Important, processing, due today, medium priority
  static const Color priorityYellow = Color(0xFFF2D600);

  /// Pink #EB5A9A — Users, mobile, profile accents
  static const Color usersPink = Color(0xFFEB5A9A);

  /// Coral #FF6B4A — Alerts, risk, overdue, critical states
  static const Color alertCoral = Color(0xFFFF6B4A);

  /// White #FFFFFF — Main background, card surfaces
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// خلفية خفيفة (tint) لأي لون أساسي — مستخدمة بكروت الإحصائيات
  /// بشاشة الـ Home (مثلاً خلفية خضراء فاتحة جداً وراء رقم أزرق غامق)
  static Color tint(Color base, [double opacity = 0.12]) =>
      base.withOpacity(opacity);
}
