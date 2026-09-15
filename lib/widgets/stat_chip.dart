import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';

/// كرت إحصائية صغير بخلفية ملوّنة خفيفة (tint) — مستخدم بـ
/// "Today's Overview" (4 كروت بصف واحد) وبـ "Project Overview"
/// (Team / Tasks / Days Left)
class StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  const StatChip({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
          ],
          Text(value, style: DashTextStyles.metric(color: color, size: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: DashTextStyles.caption(color: AppColors.darkCharcoal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
