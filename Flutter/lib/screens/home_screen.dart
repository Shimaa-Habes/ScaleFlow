import 'package:flutter/material.dart';

import '../services/home_service.dart';
import '../data/mock_data.dart';
import 'ai_insights_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import 'tasks_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(0xFFF8F9FB);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF2C2D30);
  static const Color _secondaryText = Color(0xFF737780);

  static const Color _purple = Color(0xFF6C5CE7);
  static const Color _blue = Color(0xFF5B9BD5);
  static const Color _green = Color(0xFF72B968);
  static const Color _coral = Color(0xFFE88973);
  static const Color _border = Color(0xFFE7E8EC);

  // ============================================================
  // SERVICES
  // ============================================================

  final HomeService _homeService = HomeService();

  // ============================================================
  // STATE
  // ============================================================

  HomeData? _homeData;

  bool _isLoading = true;
  bool _isRefreshing = false;

  String _selectedFilter = 'All';

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  // ============================================================
  // LOAD HOME DATA
  // ============================================================

  Future<void> _loadHomeData({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final data = await _homeService.loadHomeData();

      if (!mounted) {
        return;
      }

      setState(() {
        _homeData = data;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load Home data.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshHome() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadHomeData(showLoading: false);
  }

  // ============================================================
  // FILTERED PROJECTS
  // ============================================================

  List<Map<String, dynamic>> _visibleProjects(HomeData data) {
    final projects = List<Map<String, dynamic>>.from(data.projects);

    if (_selectedFilter == 'At Risk') {
      return projects.where((project) {
        final projectId = _toInt(project['id']);

        if (projectId == null) {
          return false;
        }

        return data.atRiskProjectIds.contains(projectId);
      }).toList();
    }

    return projects;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String _projectStatus(Map<String, dynamic> project) {
    final projectId = _toInt(project['id']);

    if (projectId != null &&
        _homeData?.atRiskProjectIds.contains(projectId) == true) {
      return 'At Risk';
    }

    final status = _toInt(project['status']);

    if (status == 5) {
      return 'Completed';
    }

    if (status == 2) {
      return 'Active';
    }

    return 'Planning';
  }

  bool _isAtRisk(
    Map<String, dynamic> project,
    HomeData data,
  ) {
    final projectId = _toInt(project['id']);

    if (projectId == null) {
      return false;
    }

    return data.atRiskProjectIds.contains(projectId);
  }

  int _projectProgress(Map<String, dynamic> project) {
    final progress = _toInt(project['progress']);

    if (progress != null) {
      return progress.clamp(0, 100);
    }

    return 0;
  }

  String _formatProgress(int progress) {
    return '$progress%';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _isLoading && _homeData == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: _purple,
                ),
              )
            : RefreshIndicator(
                color: _purple,
                onRefresh: _refreshHome,
                child: _buildHomeContent(),
              ),
      ),
      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 0,
        onTap: _handleBottomNavigation,
      ),
    );
  }

  // ============================================================
  // HOME CONTENT
  // ============================================================

  Widget _buildHomeContent() {
    final data = _homeData;

    if (data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No Home data available.',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 15,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        _buildHeader(data),
        const SizedBox(height: 22),
        _buildStatsRow(data),
        const SizedBox(height: 26),
        _buildActiveProjectSection(data),
        const SizedBox(height: 26),
        _buildTasksSection(data),
        const SizedBox(height: 26),
        _buildProjectsSection(data),
        const SizedBox(height: 26),
        _buildUpcomingSection(data),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(HomeData data) {
    final unread = data.unreadNotifications;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning, Shimaa',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Here is your project overview.',
                style: TextStyle(
                  fontSize: 14,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _text,
                size: 23,
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _coral,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _background,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow(HomeData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.folder_outlined,
            color: _purple,
            value: data.projects.length.toString(),
            label: 'Projects',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.task_alt_rounded,
            color: _blue,
            value: data.activeTaskCount.toString(),
            label: 'Tasks',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline_rounded,
            color: _green,
            value: data.completedTasks.toString(),
            label: 'Completed',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.warning_amber_rounded,
            color: _coral,
            value: data.atRiskProjectIds.length.toString(),
            label: 'At Risk',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 13, 10, 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE PROJECT
  // ============================================================

  Widget _buildActiveProjectSection(HomeData data) {
    final projects = _visibleProjects(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Active Project',
          actionText: 'View all',
          onAction: _openProjects,
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          _buildEmptyCard(
            icon: _selectedFilter == 'At Risk'
                ? Icons.check_circle_outline_rounded
                : Icons.folder_open_outlined,
            title: _selectedFilter == 'At Risk'
                ? 'No projects at risk'
                : 'No active projects',
            message: _selectedFilter == 'At Risk'
                ? 'All active projects are currently on track.'
                : 'Create a project to see it here.',
          )
        else
          _buildActiveProjectCard(
            projects.first,
            data,
          ),
      ],
    );
  }

  Widget _buildActiveProjectCard(
    Map<String, dynamic> project,
    HomeData data,
  ) {
    final projectId = _toInt(project['id']);
    final name = project['name']?.toString() ?? 'Untitled Project';
    final description =
        project['description']?.toString() ?? 'No description available.';
    final progress = _projectProgress(project);
    final atRisk = _isAtRisk(project, data);

    return InkWell(
      onTap: () {
        _openProject(project);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: atRisk ? _coral.withValues(alpha: 0.45) : _border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: atRisk
                              ? _coral.withValues(alpha: 0.10)
                              : _purple.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          atRisk
                              ? Icons.warning_amber_rounded
                              : Icons.folder_outlined,
                          color: atRisk ? _coral : _purple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _projectStatus(project),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: atRisk ? _coral : _green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (atRisk)
                  _buildStatusBadge(
                    label: 'At Risk',
                    color: _coral,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _secondaryText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatProgress(progress),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 7,
                backgroundColor: const Color(0xFFEDEEF2),
                color: atRisk ? _coral : _purple,
              ),
            ),
            if (projectId != null) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _purple,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Open project',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _purple,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TASKS
  // ============================================================

  Widget _buildTasksSection(HomeData data) {
    final tasks = data.todayTasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Today\'s Tasks',
          actionText: 'View all',
          onAction: _openTasks,
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          _buildEmptyCard(
            icon: Icons.event_available_rounded,
            title: 'No tasks for today',
            message: 'You have no active tasks due today.',
          )
        else
          ...tasks.map(_buildTaskCard),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? 'Untitled Task';
    final projectName = task['_projectName']?.toString() ?? 'Project';
    final status = _toInt(task['status']);

    final isBlocked = status == 6;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked ? _coral.withValues(alpha: 0.40) : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isBlocked
                  ? _coral.withValues(alpha: 0.10)
                  : _blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isBlocked ? Icons.block_rounded : Icons.task_alt_rounded,
              color: isBlocked ? _coral : _blue,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (isBlocked)
            _buildStatusBadge(
              label: 'Blocked',
              color: _coral,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROJECTS SECTION
  // ============================================================

  Widget _buildProjectsSection(HomeData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Projects',
          actionText: null,
          onAction: null,
        ),
        const SizedBox(height: 12),
        _buildFilterRow(data),
        const SizedBox(height: 12),
        ..._visibleProjects(data).take(4).map(
              (project) => _buildProjectListItem(
                project,
                data,
              ),
            ),
      ],
    );
  }

  Widget _buildFilterRow(HomeData data) {
    return Row(
      children: [
        _buildFilterButton(
          label: 'All',
          selected: _selectedFilter == 'All',
        ),
        const SizedBox(width: 8),
        _buildFilterButton(
          label: 'At Risk',
          selected: _selectedFilter == 'At Risk',
          count: data.atRiskProjectIds.length,
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool selected,
    int? count,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? _purple : _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _purple : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _text,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.20)
                      : _coral.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _coral,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectListItem(
    Map<String, dynamic> project,
    HomeData data,
  ) {
    final name = project['name']?.toString() ?? 'Untitled Project';
    final progress = _projectProgress(project);
    final atRisk = _isAtRisk(project, data);

    return InkWell(
      onTap: () => _openProject(project),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: atRisk ? _coral.withValues(alpha: 0.40) : _border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: atRisk
                    ? _coral.withValues(alpha: 0.10)
                    : _purple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                atRisk ? Icons.warning_amber_rounded : Icons.folder_outlined,
                color: atRisk ? _coral : _purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFEDEEF2),
                            color: atRisk ? _coral : _green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (atRisk) ...[
              const SizedBox(width: 9),
              _buildStatusBadge(
                label: 'Risk',
                color: _coral,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPCOMING
  // ============================================================

  Widget _buildUpcomingSection(HomeData data) {
    final tasks = data.upcomingTasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Upcoming',
          actionText: null,
          onAction: null,
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          _buildEmptyCard(
            icon: Icons.calendar_today_outlined,
            title: 'Nothing upcoming',
            message: 'No upcoming active tasks found.',
          )
        else
          ...tasks.map(
            (task) => _buildUpcomingTask(task),
          ),
      ],
    );
  }

  Widget _buildUpcomingTask(
    Map<String, dynamic> task,
  ) {
    final title = task['title']?.toString() ?? 'Untitled Task';
    final projectName = task['_projectName']?.toString() ?? 'Project';

    final plannedEnd = task['plannedEnd']?.toString();

    DateTime? date;

    if (plannedEnd != null) {
      date = DateTime.tryParse(plannedEnd);
    }

    String dateText = 'No due date';

    if (date != null) {
      dateText = '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: _green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 11,
              color: _secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required String? actionText,
    required VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _purple,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: _secondaryText,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _handleBottomNavigation(int index) async {
    if (index == 0) {
      return;
    }

    if (index == 1) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProjectsScreen(),
        ),
      );

      if (mounted) {
        await _loadHomeData(showLoading: false);
      }
    } else if (index == 2) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        ),
      );

      if (mounted) {
        await _loadHomeData(showLoading: false);
      }
    } else if (index == 3) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AiInsightsPage(),
        ),
      );

      if (mounted) {
        await _loadHomeData(showLoading: false);
      }
    } else if (index == 4) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );

      if (mounted) {
        await _loadHomeData(showLoading: false);
      }
    }
  }

  // ============================================================
  // OPEN PROJECTS
  // ============================================================

  Future<void> _openProjects() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProjectsScreen(),
      ),
    );

    if (mounted) {
      await _loadHomeData(showLoading: false);
    }
  }

  // ============================================================
  // OPEN TASKS
  // ============================================================

  Future<void> _openTasks() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TasksScreen(),
      ),
    );

    if (mounted) {
      await _loadHomeData(showLoading: false);
    }
  }

  // ============================================================
  // OPEN PROJECT
  // ============================================================

  void _openProject(
    Map<String, dynamic> project,
  ) {
    final projectId = _toInt(project['id']);

    if (projectId == null) {
      return;
    }

    // Keep this navigation compatible with the current project
    // structure. If ProjectsScreen handles project selection,
    // open the Projects screen and refresh after returning.
    _openProjects();
  }
}
