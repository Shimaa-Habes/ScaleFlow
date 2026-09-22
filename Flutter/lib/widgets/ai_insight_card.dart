import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';

/// كرت "ScaleFlow AI Insight" البنفسجي — نفس المكون مستخدم بشاشة
/// الـ Home وشاشة Project Details، بس بنص مختلف حسب السياق
class AiInsightCard extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback? onTap;

  const AiInsightCard({
    super.key,
    this.title = 'ScaleFlow AI Insight',
    required this.body,
    this.actionLabel = 'View recommendation',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.aiPurple, 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tint(AppColors.aiPurple, 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.aiPurple,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: DashTextStyles.cardTitle(
                        color: AppColors.aiPurple, size: 14)),
                const SizedBox(height: 4),
                Text(body, style: DashTextStyles.body()),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: DashTextStyles.label(
                            color: AppColors.aiPurple, size: 13),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 13, color: AppColors.aiPurple),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
