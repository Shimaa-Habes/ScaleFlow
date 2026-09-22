import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';
import '../models/project.dart';
import 'team_avatars.dart';

/// كرت مشروع مصغّر بقائمة "My Projects" الأفقية بشاشة الـ Home.
/// بالضغط عليه بينتقل لشاشة Project Details لنفس المشروع.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final double width;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9ECEE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: DashTextStyles.cardTitle(size: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text('${project.percentComplete}% Complete',
                style: DashTextStyles.caption()),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.percentComplete / 100,
                minHeight: 5,
                backgroundColor: const Color(0xFFE9ECEE),
                valueColor:
                    AlwaysStoppedAnimation<Color>(project.status.color),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.tint(project.status.color, 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    project.status.label,
                    style: DashTextStyles.caption(
                        color: project.status.color, size: 11),
                  ),
                ),
                const Spacer(),
                TeamAvatars(
                  members: project.team,
                  totalCount: project.teamCount,
                  size: 20,
                  maxVisible: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
