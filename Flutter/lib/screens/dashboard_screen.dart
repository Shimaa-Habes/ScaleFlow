import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/scaleflow_bottom_nav.dart';

import 'ai_insights_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';

// ============================================================
// DASHBOARD PAGE
// ============================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const String _dashboardUrl =
      'http://localhost:5233/api/Dashboard/Overview';

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool _notificationsEnabled = true;

  Map<String, dynamic>? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Your session has expired. Please login again.';
      });

      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_dashboardUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('========== DASHBOARD RESPONSE ==========');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('========================================');

      if (response.statusCode != 200) {
        Map<String, dynamic> errorData = {};

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            errorData = decoded;
          }
        } catch (_) {}

        throw Exception(
          errorData['message']?.toString() ?? 'Unable to load dashboard data.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid dashboard response.');
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Dashboard data is missing.');
      }

      if (!mounted) return;

      setState(() {
        _dashboard = data;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('========== DASHBOARD ERROR ==========');
      debugPrint(e.toString());
      debugPrint('=====================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Unable to load dashboard data. Please try again.';
      });
    }
  }

  // ============================================================
  // SAFE VALUE HELPERS
  // ============================================================

  int _intValue(String key) {
    final value = _dashboard?[key];

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(String key) {
    final value = _dashboard?[key];

    if (value is double) return value;

    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _listValue(String key) {
    final value = _dashboard?[key];

    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    return [];
  }

  String _stringValue(
    Map<String, dynamic> item,
    String key, {
    String fallback = '',
  }) {
    return item[key]?.toString() ?? fallback;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                      ? _buildErrorState()
                      : _buildDashboardContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 2,
        onTap: _handleNavigation,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
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
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 27,
                  color: AppColors.darkCharcoal,
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
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          _buildLoadingCard(height: 145),
          const SizedBox(height: 14),
          _buildLoadingCard(height: 115),
          const SizedBox(height: 14),
          _buildLoadingCard(height: 190),
          const SizedBox(height: 14),
          _buildLoadingCard(height: 125),
          const SizedBox(height: 14),
          _buildLoadingCard(height: 210),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EAF0),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.aiPurple,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 54,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 18),
          const Text(
            'Dashboard unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCharcoal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 180),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================

  Widget _buildDashboardContent() {
    final activeProjects = _intValue('activeProjects');
    final tasksDue = _intValue('tasksDue');
    final overdueTasks = _intValue('overdueTasks');
    final atRiskProjects = _intValue('atRiskProjects');
    final completedTasks = _intValue('completedTasks');
    final totalTasks = _intValue('totalTasks');
    final overallProgress = _doubleValue('overallProgress');
    final onTrackProjects = _intValue('onTrackProjects');

    final performance = _listValue('projectPerformance');
    final deadlines = _listValue('upcomingDeadlines');
    final workload = _listValue('teamWorkload');

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.aiPurple,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth < 700 ? constraints.maxWidth : 520.0;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                children: [
                  _buildOverviewCards(
                    activeProjects: activeProjects,
                    overallProgress: overallProgress,
                    totalTasks: totalTasks,
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('Project Status'),
                  const SizedBox(height: 10),
                  _buildProjectStatus(
                    onTrack: onTrackProjects,
                    atRisk: atRiskProjects,
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('Task Overview'),
                  const SizedBox(height: 10),
                  _buildTaskOverview(
                    totalTasks: totalTasks,
                    dueToday: tasksDue,
                    overdue: overdueTasks,
                    completedTasks: completedTasks,
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('Project Performance'),
                  const SizedBox(height: 10),
                  _buildProjectPerformance(performance),
                  const SizedBox(height: 18),
                  _buildSectionTitle('Team Workload'),
                  const SizedBox(height: 10),
                  _buildTeamWorkload(workload),
                  const SizedBox(height: 18),
                  _buildSectionTitle('Upcoming Deadlines'),
                  const SizedBox(height: 10),
                  _buildUpcomingDeadlines(deadlines),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

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

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverviewCards({
    required int activeProjects,
    required double overallProgress,
    required int totalTasks,
  }) {
    final progress = overallProgress.clamp(0, 100).toDouble();

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            icon: Icons.folder_outlined,
            title: 'Active Projects',
            value: '$activeProjects',
            subtitle: 'Projects',
            color: AppColors.aiPurple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOverviewCard(
            icon: Icons.trending_up_rounded,
            title: 'Overall Progress',
            value: '${progress.round()}%',
            subtitle: 'Progress',
            color: AppColors.dataCyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOverviewCard(
            icon: Icons.checklist_rounded,
            title: 'Total Tasks',
            value: '$totalTasks',
            subtitle: 'Tasks',
            color: AppColors.statusGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE7E9EF),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROJECT STATUS
  // ============================================================

  Widget _buildProjectStatus({
    required int onTrack,
    required int atRisk,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusItem(
              icon: Icons.check_circle_outline_rounded,
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
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
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

  // ============================================================
  // TASK OVERVIEW
  // ============================================================

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
            '$totalTasks',
            'Total Tasks',
            AppColors.dataCyan,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _buildTaskStat(
            '$dueToday',
            'Due Today',
            AppColors.priorityYellow,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _buildTaskStat(
            '$overdue',
            'Overdue',
            AppColors.alertCoral,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _buildTaskStat(
            '$completedTasks',
            'Completed',
            AppColors.statusGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStat(
    String value,
    String label,
    Color color,
  ) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE7E9EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROJECT PERFORMANCE
  // ============================================================

  Widget _buildProjectPerformance(
    List<Map<String, dynamic>> projects,
  ) {
    if (projects.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.folder_open_outlined,
        message: 'No project performance data available.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          ...projects.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final project = entry.value;

              final name = _stringValue(
                project,
                'projectName',
                fallback: 'Unnamed Project',
              );

              final progressValue = (project['completionPercent'] is num)
                  ? (project['completionPercent'] as num).toInt()
                  : int.tryParse(
                        project['completionPercent']?.toString() ?? '',
                      ) ??
                      0;

              final status = _stringValue(
                project,
                'status',
                fallback: 'In Progress',
              );

              final isRisk = status.toLowerCase() == 'at risk';
              final isCompleted = status.toLowerCase() == 'completed';

              final color = isRisk
                  ? AppColors.alertCoral
                  : isCompleted
                      ? AppColors.statusGreen
                      : AppColors.aiPurple;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == projects.length - 1 ? 0 : 16,
                ),
                child: _buildPerformanceItem(
                  name: name,
                  progress: progressValue,
                  status: status,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem({
    required String name,
    required int progress,
    required String status,
    required Color color,
  }) {
    final safeProgress = progress.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$safeProgress%',
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
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: safeProgress / 100,
            minHeight: 7,
            backgroundColor: const Color(0xFFEDEEF2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          status,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEAM WORKLOAD
  // ============================================================

  Widget _buildTeamWorkload(
    List<Map<String, dynamic>> workload,
  ) {
    if (workload.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.groups_outlined,
        message: 'No team workload data available.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...workload.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final member = entry.value;

              final name = _stringValue(
                member,
                'fullName',
                fallback: 'Team Member',
              );

              final percent = member['workloadPercent'] is num
                  ? (member['workloadPercent'] as num).toDouble()
                  : double.tryParse(
                        member['workloadPercent']?.toString() ?? '',
                      ) ??
                      0;

              final status = _stringValue(
                member,
                'workloadStatus',
                fallback: 'Normal',
              );

              final color = _workloadColor(status);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == workload.length - 1 ? 0 : 15,
                ),
                child: _buildWorkloadItem(
                  name: name,
                  percent: percent,
                  status: status,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadItem({
    required String name,
    required double percent,
    required String status,
    required Color color,
  }) {
    final safePercent = percent.clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
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
              '${percent.round()}%',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: safePercent / 100,
            minHeight: 7,
            backgroundColor: const Color(0xFFEDEEF2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _workloadColor(String status) {
    switch (status.toLowerCase()) {
      case 'overloaded':
        return AppColors.alertCoral;

      case 'underutilized':
        return AppColors.priorityYellow;

      default:
        return AppColors.statusGreen;
    }
  }

  // ============================================================
  // UPCOMING DEADLINES
  // ============================================================

  Widget _buildUpcomingDeadlines(
    List<Map<String, dynamic>> deadlines,
  ) {
    if (deadlines.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.event_available_outlined,
        message: 'No upcoming deadlines.',
      );
    }

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: deadlines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final deadline = deadlines[index];

          final taskTitle = _stringValue(
            deadline,
            'taskTitle',
            fallback: 'Task',
          );

          final projectName = _stringValue(
            deadline,
            'projectName',
            fallback: 'Project',
          );

          final dueDate = _parseDate(
            deadline['dueDate'],
          );

          final dueInfo = _formatDueDate(dueDate);

          final color = dueInfo.isOverdue
              ? AppColors.alertCoral
              : dueInfo.isToday
                  ? AppColors.priorityYellow
                  : AppColors.dataCyan;

          return Container(
            width: 205,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: color.withOpacity(0.20),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dueInfo.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  taskTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString())?.toLocal();
  }

  _DueInfo _formatDueDate(DateTime? date) {
    if (date == null) {
      return const _DueInfo(
        label: 'Scheduled',
        isToday: false,
        isOverdue: false,
      );
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference = target.difference(today).inDays;

    if (difference < 0) {
      return _DueInfo(
        label: 'Overdue',
        isToday: false,
        isOverdue: true,
      );
    }

    if (difference == 0) {
      return _DueInfo(
        label: 'Due today',
        isToday: true,
        isOverdue: false,
      );
    }

    if (difference == 1) {
      return const _DueInfo(
        label: 'Due tomorrow',
        isToday: false,
        isOverdue: false,
      );
    }

    return _DueInfo(
      label: '${date.day}/${date.month}/${date.year}',
      isToday: false,
      isOverdue: false,
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _buildEmptyCard({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 25,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: const Color(0xFFE7E9EF),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 7,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
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
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE7E9EF),
                        ),
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

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } else if (index == 1) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => const ProjectsScreen(),
        ),
      )
          .then((_) {
        _loadDashboard();
      });
    } else if (index == 2) {
      return;
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AiInsightsPage(),
        ),
      );
    } else if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }
  }
}

// ============================================================
// DUE INFO
// ============================================================

class _DueInfo {
  final String label;
  final bool isToday;
  final bool isOverdue;

  const _DueInfo({
    required this.label,
    required this.isToday,
    required this.isOverdue,
  });
}
