import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';

/// كرت إحصائية صغير بخلفية ملوّنة خفيفة (tint).
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
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(height: 5),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashTextStyles.metric(
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashTextStyles.caption(
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}
