import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/mock_data.dart';
import '../models/project.dart';
import '../models/task_item.dart';
import '../widgets/scaleflow_bottom_nav.dart';

import 'ai_insights_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';
import 'home_screen.dart';

// ============================================================
// DASHBOARD PAGE
// ============================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final visibleProjects = scaleFlowProjects;

    final totalTasks = visibleProjects.fold<int>(
      0,
      (sum, project) => sum + project.tasksTotal,
    );

    final completedTasks = visibleProjects.fold<int>(
      0,
      (sum, project) => sum + project.tasksCompleted,
    );

    final dueToday = visibleProjects
        .expand((project) => project.tasks)
        .where(
          (task) => task.dueLabel.toLowerCase() == 'due today',
        )
        .length;

    final atRiskProjects = visibleProjects
        .where(
          (project) => project.status == ProjectStatus.atRisk,
        )
        .length;

    final onTrackProjects = visibleProjects
        .where(
          (project) => project.status == ProjectStatus.onTrack,
        )
        .length;

    final overallProgress = visibleProjects.isEmpty
        ? 0.0
        : visibleProjects.fold<double>(
              0,
              (sum, project) => sum + project.percentComplete,
            ) /
            visibleProjects.length /
            100;

    final overallHealth = visibleProjects.isEmpty
        ? 0
        : (visibleProjects.fold<int>(
                  0,
                  (sum, project) => sum + project.healthPercent,
                ) /
                visibleProjects.length)
            .round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // الخلفية المخصصة للصورة مع طبقة تدرج شفافة لتوضيح العناصر
          Positioned.fill(
            child: Image.asset(
              'assets/images/Dash-Image.jpg', // تأكدي من مسار الصورة في assets
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF7F6FB).withOpacity(0.92),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar مخصص متناسق مع الخلفية
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Your projects at a glance',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: _openNotifications,
                            icon: const Icon(
                              Icons.notifications_none,
                              color: AppColors.darkCharcoal,
                              size: 27,
                            ),
                          ),
                          if (_notificationsEnabled)
                            Positioned(
                              right: 7,
                              top: 7,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.alertCoral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth < 600
                          ? constraints.maxWidth
                          : 460.0;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxWidth,
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Visual Overview'),
                                const SizedBox(height: 10),
                                _buildVisualOverview(
                                  health: overallHealth,
                                  progress: overallProgress,
                                  projectsCount: visibleProjects.length,
                                ),
                                const SizedBox(height: 20),
                                _buildProjectStatus(
                                  onTrack: onTrackProjects,
                                  atRisk: atRiskProjects,
                                ),
                                const SizedBox(height: 20),
                                _buildProjectPerformance(visibleProjects),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Task Overview'),
                                const SizedBox(height: 10),
                                _buildTaskOverview(
                                  totalTasks: totalTasks,
                                  dueToday: dueToday,
                                  overdue: atRiskProjects,
                                  completedTasks: completedTasks,
                                ),
                                const SizedBox(height: 20),
                                _buildTeamWorkload(),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Upcoming Deadlines'),
                                const SizedBox(height: 10),
                                _buildUpcomingDeadlines(visibleProjects),
                                const SizedBox(height: 20),
                                _buildRecentActivity(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProjectsScreen()),
            );
          } else if (index == 2) {
            return;
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiInsightsPage()),
            );
          } else if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.darkCharcoal,
      ),
    );
  }

  Widget _buildVisualOverview({
    required int health,
    required double progress,
    required int projectsCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Project Health',
            value: '$health%',
            status: health >= 80 ? 'Healthy' : 'Needs Attention',
            progress: health / 100,
            color: AppColors.statusGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'Overall Progress',
            value: '${(progress * 100).round()}%',
            status: progress >= 0.7 ? 'On Track' : 'In Progress',
            progress: progress,
            color: AppColors.dataCyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'Active Projects',
            value: '$projectsCount',
            status: 'Projects',
            progress: projectsCount == 0 ? 0 : 1,
            color: AppColors.usersPink,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String status,
    required double progress,
    required Color color,
  }) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 5,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStatus({required int onTrack, required int atRisk}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.check_circle_outline,
                  label: 'On Track',
                  value: '$onTrack',
                  color: AppColors.statusGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'At Risk',
                  value: '$atRisk',
                  color: AppColors.alertCoral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectPerformance(List<Project> projects) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Performance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 14),
          ...projects.take(4).map((project) {
            final Color color = project.status == ProjectStatus.atRisk
                ? AppColors.alertCoral
                : AppColors.statusGreen;

            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ),
                      Text(
                        '${project.percentComplete}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: project.percentComplete / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskOverview({
    required int totalTasks,
    required int dueToday,
    required int overdue,
    required int completedTasks,
  }) {
    return Row(
      children: [
        Expanded(
            child: _buildTaskStat(
                '$totalTasks', 'Total Tasks', AppColors.dataCyan)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildTaskStat(
                '$dueToday', 'Due Today', AppColors.priorityYellow)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildTaskStat('$overdue', 'At Risk', AppColors.alertCoral)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildTaskStat(
                '$completedTasks', 'Completed', AppColors.statusGreen)),
      ],
    );
  }

  Widget _buildTaskStat(String value, String label, Color color) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamWorkload() {
    final workload = [
      {'name': 'Sadeel', 'percent': 82, 'color': AppColors.statusGreen},
      {'name': 'Saba', 'percent': 74, 'color': AppColors.priorityYellow},
      {'name': 'Shimaa', 'percent': 68, 'color': AppColors.usersPink},
      {'name': 'Mohammad', 'percent': 71, 'color': AppColors.dataCyan},
      {'name': 'Mostafa', 'percent': 64, 'color': AppColors.alertCoral},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Workload',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 14),
          ...workload.map((member) {
            final int percent = member['percent'] as int;
            final Color color = member['color'] as Color;
            final String name = member['name'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.statusGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Overall workload: Balanced',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines(List<Project> projects) {
    final List<Map<String, String>> deadlineItems = [];

    for (final project in projects) {
      for (final task in project.tasks) {
        deadlineItems.add({
          'task': task.title,
          'project': project.name,
          'due': task.dueLabel,
        });
        if (deadlineItems.length >= 5) break;
      }
      if (deadlineItems.length >= 5) break;
    }

    if (deadlineItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: const Text(
          'No upcoming deadlines.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: deadlineItems.length,
        itemBuilder: (context, index) {
          final item = deadlineItems[index];
          final String dueLabel = item['due'] ?? '';
          final Color deadlineColor = dueLabel.toLowerCase() == 'due today'
              ? AppColors.alertCoral
              : dueLabel.toLowerCase() == 'due tomorrow'
                  ? AppColors.priorityYellow
                  : AppColors.statusGreen;

          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: deadlineColor.withOpacity(0.3)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 4)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['task'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['project'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  dueLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: deadlineColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'title': 'Sadeel updated ML data',
        'subtitle': 'AI/ML Preparation',
        'time': 'Today',
        'icon': Icons.analytics_outlined,
        'color': AppColors.dataCyan,
      },
      {
        'title': 'Mohammad updated API work',
        'subtitle': 'Backend Foundation',
        'time': 'Today',
        'icon': Icons.code,
        'color': AppColors.statusGreen,
      },
      {
        'title': 'Mostafa reviewed API security',
        'subtitle': 'Security Testing',
        'time': 'Yesterday',
        'icon': Icons.security_outlined,
        'color': AppColors.alertCoral,
      },
      {
        'title': 'Shimaa updated project design',
        'subtitle': 'ScaleFlow',
        'time': 'Yesterday',
        'icon': Icons.design_services_outlined,
        'color': AppColors.usersPink,
      },
      {
        'title': 'Saba prepared modeling requirements',
        'subtitle': 'AI/ML Modeling',
        'time': 'Yesterday',
        'icon': Icons.model_training_outlined,
        'color': AppColors.aiPurple,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 14),
          ...activities.map((activity) {
            final Color color = activity['color'] as Color;
            final IconData icon = activity['icon'] as IconData;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 17, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activity['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activity['time'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.hintTextInactive,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage your ScaleFlow notifications.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Project Notifications',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      subtitle: const Text(
                        'Receive updates about your projects and tasks.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _notificationsEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.statusGreen,
                      onChanged: (value) {
                        setSheetState(() {
                          _notificationsEnabled = value;
                        });
                        setState(() {});
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Notifications enabled.'
                                  : 'Notifications disabled.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 19,
                            color: AppColors.dataCyan,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'You will receive notifications for important project events, deadlines, and task updates.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
