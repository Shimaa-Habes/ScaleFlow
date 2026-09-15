import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// عنصر واحد من شروط كلمة السر (مثلاً: 8+ أحرف)
/// يتغيّر لونه وأيقونته للأخضر لمّا الشرط يتحقق أثناء الكتابة
class PasswordRequirementItem extends StatelessWidget {
  final String text;
  final bool isSatisfied;

  const PasswordRequirementItem({
    super.key,
    required this.text,
    required this.isSatisfied,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSatisfied ? AppColors.hintTextActive : AppColors.hintTextInactive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.hintItem.copyWith(color: color)),
        ],
      ),
    );
  }
}
