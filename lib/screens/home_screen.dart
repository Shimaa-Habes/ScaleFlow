import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';
import '../data/mock_data.dart';
import '../models/project.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/health_ring.dart';
import '../widgets/project_card.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import '../widgets/stat_chip.dart';
import '../widgets/task_row.dart';
import 'project_details_screen.dart';

/// شاشة الـ Home — نفس تصميم الـ Figma المعتمد:
/// تحية + Today's Overview + Overall Project Health + My Projects
/// + ScaleFlow AI Insight + Priority Tasks + Bottom Navigation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openProject(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Directionality صريحة LTR متل باقي شاشات التطبيق، حتى التصميم
    // والتنقل بالقوائم الأفقية يضلوا متوقعين بغض النظر عن لغة الجهاز
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: ScaleFlowBottomNav(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1 && MockData.projects.isNotEmpty) {
              _openProject(context, MockData.projects.first);
            }
          },
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // تصميم متجاوب: عرض أقصى للمحتوى على الشاشات الكبيرة
              final maxContentWidth =
                  constraints.maxWidth < 600 ? constraints.maxWidth : 480.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(),
                        const SizedBox(height: 20),

                        Text("Today's Overview",
                            style: DashTextStyles.sectionTitle()),
                        const SizedBox(height: 10),
                        _TodaysOverview(),
                        const SizedBox(height: 18),

                        _OverallHealthCard(),
                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('My Projects',
                                style: DashTextStyles.sectionTitle()),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _MyProjectsList(onOpenProject: _openProject),
                        const SizedBox(height: 18),

                        AiInsightCard(
                          body: MockData.projects.first.aiInsightBody,
                          onTap: () =>
                              _openProject(context, MockData.projects.first),
                        ),
                        const SizedBox(height: 22),

                        Text('Priority Tasks',
                            style: DashTextStyles.sectionTitle()),
                        const SizedBox(height: 4),
                        ...MockData.priorityTasks
                            .map((task) => TaskRow(task: task)),
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

/// رأس الصفحة: التحية باسم المستخدم الأول + الجرس + الأفاتار
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // بنجيب أول اسم بس من المستخدم الحالي — mock مؤقتاً لحد ما
    // يترابط مع نتيجة تسجيل الدخول الحقيقية
    final firstName = CurrentUser.firstName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning, $firstName 👋',
                  style: DashTextStyles.screenTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text("Here's what's happening across your projects today.",
                  style: DashTextStyles.body()),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.darkCharcoal, 0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_none,
              size: 20, color: AppColors.darkCharcoal),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.usersPink,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// صف الأربع كروت الإحصائية (Active Projects / Tasks Due / Overdue / At Risk)
class _TodaysOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatChip(
            value: '${MockData.activeProjects}',
            label: 'Active Projects',
            color: AppColors.statusGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            value: '${MockData.tasksDue}',
            label: 'Tasks Due',
            color: AppColors.dataCyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            value: '${MockData.overdueTasks}',
            label: 'Overdue',
            color: AppColors.alertCoral,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            value: '${MockData.atRiskCount}',
            label: 'At Risk',
            color: AppColors.priorityYellow,
          ),
        ),
      ],
    );
  }
}

/// كرت "Overall Project Health" بحلقة النسبة على اليمين
class _OverallHealthCard extends StatelessWidget {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Project Health',
                    style: DashTextStyles.cardTitle(size: 15)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${MockData.overallHealthPercent}%',
                        style: DashTextStyles.metric(size: 26)),
                    const SizedBox(width: 8),
                    Text('Healthy',
                        style: DashTextStyles.label(
                            color: AppColors.statusGreen, size: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(MockData.overallHealthTrend,
                    style: DashTextStyles.caption(
                        color: AppColors.statusGreen)),
              ],
            ),
          ),
          HealthRing(percent: MockData.overallHealthPercent, size: 64),
        ],
      ),
    );
  }
}

/// قائمة "My Projects" الأفقية القابلة للتمرير
class _MyProjectsList extends StatelessWidget {
  final void Function(BuildContext, Project) onOpenProject;

  const _MyProjectsList({required this.onOpenProject});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MockData.projects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final project = MockData.projects[index];
          return ProjectCard(
            project: project,
            onTap: () => onOpenProject(context, project),
          );
        },
      ),
    );
  }
}
