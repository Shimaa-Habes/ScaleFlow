import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';
import '../models/project.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/health_ring.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import '../widgets/stat_chip.dart';
import '../widgets/task_row.dart';
import '../widgets/team_avatars.dart';

/// شاشة تفاصيل المشروع — نفس تصميم الـ Figma المعتمد:
/// Header (رجوع + عنوان) + كرت المشروع الرئيسي + Project Overview
/// + Project Health + ScaleFlow AI Insight + Upcoming Tasks + Project Team
class ProjectDetailsScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: ScaleFlowBottomNav(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) Navigator.of(context).pop();
          },
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth =
                  constraints.maxWidth < 600 ? constraints.maxWidth : 460.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(),
                        const SizedBox(height: 14),

                        _ProjectHeaderCard(project: project),
                        const SizedBox(height: 22),

                        Text('Project Overview',
                            style: DashTextStyles.sectionTitle()),
                        const SizedBox(height: 10),
                        _ProjectOverviewRow(project: project),
                        const SizedBox(height: 22),

                        _ProjectHealthCard(project: project),
                        const SizedBox(height: 22),

                        AiInsightCard(body: project.aiInsightBody),
                        const SizedBox(height: 22),

                        Text('Upcoming Tasks',
                            style: DashTextStyles.sectionTitle()),
                        const SizedBox(height: 4),
                        ...project.tasks.map((task) => TaskRow(task: task)),
                        const SizedBox(height: 22),

                        Text('Project Team',
                            style: DashTextStyles.sectionTitle()),
                        const SizedBox(height: 10),
                        TeamAvatars(
                          members: project.team,
                          totalCount: project.teamCount,
                          size: 34,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// شريط علوي: زر رجوع + "Project Details" + زر خيارات إضافية
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.arrow_back, color: AppColors.darkCharcoal),
          ),
        ),
        Expanded(
          child: Text('Project Details',
              textAlign: TextAlign.center,
              style: DashTextStyles.sectionTitle(size: 17)),
        ),
        GestureDetector(
          onTap: () {
            // مكان مستقبلي لقائمة خيارات إضافية (تعديل/أرشفة/مشاركة...)
            // بننتظر تحديد سلوكها من فريق الـ UX/Backend
          },
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.more_horiz, color: AppColors.darkCharcoal),
          ),
        ),
      ],
    );
  }
}

/// كرت المشروع الرئيسي: الاسم + حالة On Track/At Risk + شريط التقدم
class _ProjectHeaderCard extends StatelessWidget {
  final Project project;

  const _ProjectHeaderCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(project.name,
                    style: DashTextStyles.cardTitle(size: 19)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tint(project.status.color, 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.status.label,
                  style: DashTextStyles.label(
                      color: project.status.color, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(project.subtitle, style: DashTextStyles.body()),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: project.percentComplete / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFE9ECEE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.dataCyan),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${project.percentComplete}% Complete',
                  style: DashTextStyles.label(size: 13)),
              Text(project.dueDate, style: DashTextStyles.caption()),
            ],
          ),
        ],
      ),
    );
  }
}

/// صف الإحصائيات الثلاث: Team / Tasks / Days Left — كل وحدة بلونها
/// الدلالي من نظام الألوان الرسمي (pink للأشخاص، cyan للبيانات، أصفر للوقت)
class _ProjectOverviewRow extends StatelessWidget {
  final Project project;

  const _ProjectOverviewRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatChip(
            value: '${project.teamCount} members',
            label: 'Team',
            color: AppColors.usersPink,
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            value: '${project.tasksCompleted} / ${project.tasksTotal}',
            label: 'Tasks completed',
            color: AppColors.dataCyan,
            icon: Icons.checklist_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            value: '${project.daysLeft} days',
            label: 'Days Left',
            color: AppColors.priorityYellow,
            icon: Icons.calendar_today_outlined,
          ),
        ),
      ],
    );
  }
}

/// كرت "Project Health" بنفس الحلقة الدائرية مستخدمة بشاشة الـ Home
class _ProjectHealthCard extends StatelessWidget {
  final Project project;

  const _ProjectHealthCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final label = project.healthPercent >= 75
        ? 'Healthy'
        : (project.healthPercent >= 50 ? 'Needs attention' : 'At risk');
    final color = project.healthPercent >= 75
        ? AppColors.statusGreen
        : (project.healthPercent >= 50
            ? AppColors.priorityYellow
            : AppColors.alertCoral);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project Health',
                    style: DashTextStyles.cardTitle(size: 15)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${project.healthPercent}%',
                        style: DashTextStyles.metric(size: 26)),
                    const SizedBox(width: 8),
                    Text(label,
                        style: DashTextStyles.label(color: color, size: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(project.healthNote, style: DashTextStyles.body()),
              ],
            ),
          ),
          HealthRing(percent: project.healthPercent, size: 64),
        ],
      ),
    );
  }
}
