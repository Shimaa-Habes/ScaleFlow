import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/scaleflow_bottom_nav.dart';

import 'ai_insights_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';

import '../services/home_service.dart';

// ============================================================
// APP ENTRY POINT
// ============================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScaleFlow Dashboard',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7F6FB),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// SCALEFLOW COLORS
// ============================================================

const Color _charcoal = Color(0xFF2C2D30);
const Color _softText = Color(0xFF666A70);
const Color _mutedText = Color(0xFF858990);
const Color _pageBackground = Color(0xFFF7F6FB);

const Color _purple = Color(0xFF6C5CE7);
const Color _green = Color(0xFF4F9A5A);
const Color _blue = Color(0xFF3F82B8);
const Color _coral = Color(0xFFE88973);
const Color _amber = Color(0xFFD8B84C);

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeService _homeService = HomeService();

  HomeData? _homeData;

  bool _isLoadingHome = true;
  bool _isUpdatingTask = false;

  String? _homeError;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<String> _filters = const [
    'All',
    'At Risk',
  ];

  String _selectedFilter = 'All';

  Color _avatarColor = const Color(0xFFD985AE);

  final List<Color> _avatarColors = [
    const Color(0xFFD985AE),
    const Color(0xFF6C5CE7),
    const Color(0xFF5B9BD5),
    const Color(0xFF72B968),
    const Color(0xFFE88973),
    const Color(0xFF63BFC7),
    const Color(0xFFD8B84C),
  ];

  OverlayEntry? _notificationOverlay;

  final LayerLink _notificationLayerLink = LayerLink();

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _avatarColor = _avatarColors[
        DateTime.now().millisecondsSinceEpoch % _avatarColors.length];

    _loadHomeData();
  }

  @override
  void dispose() {
    _removeNotificationOverlay();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD HOME DATA
  // ==========================================================

  Future<void> _loadHomeData() async {
    if (mounted) {
      setState(() {
        _isLoadingHome = true;
        _homeError = null;
      });
    }

    try {
      final data = await _homeService.loadHomeData();

      if (!mounted) return;

      setState(() {
        _homeData = data;
        _isLoadingHome = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingHome = false;
        _homeError = 'Unable to load Home data.';
      });
    }
  }

  // ==========================================================
  // USER NAME
  // ==========================================================

  String get userName {
    final name = CurrentUser.firstName.trim();

    if (name.isEmpty) {
      return 'User';
    }

    return name;
  }

  // ==========================================================
  // VISIBLE PROJECTS
  // ==========================================================

  List<Map<String, dynamic>> get _visibleProjects {
    final data = _homeData;

    if (data == null) {
      return [];
    }

    final query = _searchQuery.trim().toLowerCase();

    return data.projects.where((project) {
      final name = project['name']?.toString().toLowerCase() ?? '';

      final projectId = _toInt(project['id']);

      final matchesSearch = query.isEmpty || name.contains(query);

      final matchesFilter = _selectedFilter == 'All' ||
          (projectId != null && data.atRiskProjectIds.contains(projectId));

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/Home-Image.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE7DEF6),
                            Color(0xFFF1E9F2),
                            Color(0xFFF7F6FB),
                          ],
                          stops: [
                            0.0,
                            0.55,
                            1.0,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.75),
                        Colors.white.withOpacity(0.88),
                        _pageBackground,
                      ],
                      stops: const [
                        0.0,
                        0.6,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    if (_isLoadingHome)
                      _buildLoadingState()
                    else if (_homeError != null)
                      _buildErrorState()
                    else ...[
                      _buildStatsRow(),
                      const SizedBox(height: 22),
                      _buildActiveProjectSection(),
                      const SizedBox(height: 22),
                      _buildTodaysTasksSection(),
                      const SizedBox(height: 20),
                      _buildUpcomingDeadlinesSection(),
                      const SizedBox(height: 20),
                      _buildProjectHealthCard(),
                      const SizedBox(height: 20),
                      _buildAiInsightCard(),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 0,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProjectsScreen(),
              ),
            );

            // Refresh Home after returning from Projects.
            if (mounted) {
              await _loadHomeData();
            }
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DashboardPage(),
              ),
            );
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
        },
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Column(
        children: [
          CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _purple,
          ),
          SizedBox(height: 14),
          Text(
            'Loading your workspace...',
            style: TextStyle(
              fontSize: 12,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 34,
            color: _coral,
          ),
          const SizedBox(height: 10),
          const Text(
            'Could not load Home data',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _charcoal,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Please make sure the backend is running and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadHomeData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final String firstLetter =
        userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openProfile,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: CurrentUser.profileImage == null
                    ? _avatarColor
                    : Colors.transparent,
                backgroundImage: CurrentUser.profileImage != null
                    ? MemoryImage(CurrentUser.profileImage!)
                    : null,
                child: CurrentUser.profileImage == null
                    ? Text(
                        firstLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello 👋',
                style: TextStyle(
                  fontSize: 12,
                  color: _softText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _charcoal,
                ),
              ),
            ],
          ),
        ),
        CompositedTransformTarget(
          link: _notificationLayerLink,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _toggleNotifications,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.notifications_none,
                    size: 22,
                    color: _charcoal,
                  ),
                ),
                if ((_homeData?.unreadNotifications ?? 0) > 0)
                  Positioned(
                    right: 7,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 20,
            color: _mutedText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search your projects...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: _mutedText,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: _charcoal,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(
                Icons.close,
                size: 17,
                color: _mutedText,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final String filter = _filters[index];

          final bool selected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _purple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? []
                    : const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _softText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow() {
    final data = _homeData!;

    final stats = [
      (
        icon: Icons.folder_outlined,
        color: _blue,
        value: data.projects.length.toString(),
        label: 'Projects',
      ),
      (
        icon: Icons.task_alt_outlined,
        color: _purple,
        value: data.totalTasks.toString(),
        label: 'Tasks',
      ),
      (
        icon: Icons.check_circle_outline,
        color: _green,
        value: data.completedTasks.toString(),
        label: 'Completed',
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final int index = entry.key;
        final stat = entry.value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == stats.length - 1 ? 0 : 8,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: stat.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      stat.icon,
                      size: 16,
                      color: stat.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: _mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ACTIVE PROJECT
  // ============================================================

  Widget _buildActiveProjectSection() {
    final projects = _visibleProjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Project',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _charcoal,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openProjects,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _purple,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (projects.isEmpty)
          _buildEmptyProjectState()
        else
          _buildActiveProjectCard(projects.first),
      ],
    );
  }

  Widget _buildEmptyProjectState() {
    final bool filtered =
        _selectedFilter != 'All' || _searchQuery.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        filtered
            ? 'No projects match the current filter.'
            : 'No active projects found.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: _mutedText,
        ),
      ),
    );
  }

  Widget _buildActiveProjectCard(
    Map<String, dynamic> project,
  ) {
    final int projectId = _toInt(project['id']) ?? 0;

    final data = _homeData!;

    final projectTasks = data.allTasks.where((task) {
      return _toInt(task['_projectId']) == projectId;
    }).toList();

    final int totalTasks = projectTasks.length;

    final int completedTasks = projectTasks.where((task) {
      return _toInt(task['status']) == 5;
    }).length;

    final double progress = _calculateProjectProgress(
      projectTasks,
    );

    final bool atRisk = data.atRiskProjectIds.contains(projectId);

    final String? dueDate = _formatDate(project['endDate']);

    return GestureDetector(
      onTap: _openProjects,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Image.asset(
                'assets/images/Home-Image.jpg',
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    color: _purple.withOpacity(0.85),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 34,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                12,
                14,
                14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project['name']?.toString() ?? 'Unnamed Project',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(
                        atRisk ? 'At Risk' : 'On Track',
                        atRisk ? _coral : _green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${progress.toInt()}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _charcoal,
                            ),
                          ),
                          const Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 10,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE8EAED),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              atRisk ? _coral : _green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (dueDate != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: _mutedText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due $dueDate',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _softText,
                              ),
                            ),
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: _mutedText,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'No deadline',
                              style: TextStyle(
                                fontSize: 11,
                                color: _softText,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          const Icon(
                            Icons.checklist_outlined,
                            size: 13,
                            color: _mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$completedTasks/$totalTasks Tasks',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _softText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TODAY'S TASKS
  // ============================================================

  Widget _buildTodaysTasksSection() {
    final data = _homeData!;

    final tasks = data.todayTasks.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Tasks",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _charcoal,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TasksScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _purple,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          _buildEmptyTasksState()
        else
          ...tasks.map(_buildTaskItem),
      ],
    );
  }

  Widget _buildEmptyTasksState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.task_alt,
            size: 30,
            color: _green,
          ),
          SizedBox(height: 8),
          Text(
            'No tasks due today',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _charcoal,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'You are all clear for today.',
            style: TextStyle(
              fontSize: 10.5,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    Map<String, dynamic> task,
  ) {
    final int status = _toInt(task['status']) ?? 0;

    final bool isCompleted = status == 5;

    final bool isBlocked = status == 6;

    final Color taskColor = isBlocked
        ? _coral
        : isCompleted
            ? _green
            : _purple;

    final int? projectId = _toInt(task['_projectId']);

    final int? taskId = _toInt(task['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: taskColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBlocked ? Icons.block_outlined : Icons.task_alt,
              size: 17,
              color: taskColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title']?.toString() ?? 'Untitled Task',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: isCompleted ? _mutedText : _charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task['_projectName']?.toString() ?? 'Project',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _softText,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: isCompleted,
            activeColor: taskColor,
            side: BorderSide(
              color: taskColor.withOpacity(0.90),
              width: 1.5,
            ),
            visualDensity: VisualDensity.compact,
            onChanged: _isUpdatingTask ||
                    projectId == null ||
                    taskId == null ||
                    isBlocked
                ? null
                : (value) async {
                    await _toggleTask(
                      task,
                      projectId,
                      taskId,
                      value ?? false,
                    );
                  },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPDATE TASK
  // ============================================================

  Future<void> _toggleTask(
    Map<String, dynamic> task,
    int projectId,
    int taskId,
    bool completed,
  ) async {
    if (_isUpdatingTask) {
      return;
    }

    setState(() {
      _isUpdatingTask = true;
    });

    try {
      final success = await _homeService.updateTaskCompletion(
        projectId: projectId,
        taskId: taskId,
        task: task,
        completed: completed,
      );

      if (!mounted) return;

      if (success) {
        await _loadHomeData();
      } else {
        _showMessage(
          'Unable to update the task.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to update the task.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingTask = false;
        });
      }
    }
  }

  // ============================================================
  // UPCOMING DEADLINES
  // ============================================================

  Widget _buildUpcomingDeadlinesSection() {
    final data = _homeData!;

    final tasks = data.upcomingTasks.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Deadlines',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: _charcoal,
          ),
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'No upcoming deadlines.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: _mutedText,
              ),
            ),
          )
        else
          ...tasks.map(
            (task) {
              final DateTime? dueDate = _parseDate(task['plannedEnd']);

              final bool overdue =
                  dueDate != null && dueDate.isBefore(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 8,
                ),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (overdue ? _coral : _amber).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        overdue
                            ? Icons.warning_amber_rounded
                            : Icons.schedule_outlined,
                        size: 17,
                        color: overdue ? _coral : _amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title']?.toString() ?? 'Untitled Task',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task['_projectName']?.toString() ?? 'Project',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dueDate == null
                          ? 'No date'
                          : _formatShortDate(
                              dueDate,
                            ),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: overdue ? _coral : _softText,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ============================================================
  // PROJECT HEALTH
  //
  // AI / ML NOT READY YET
  // ============================================================

  Widget _buildProjectHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD9DCE2),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: _purple,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Project Health',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _charcoal,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Not Ready Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'AI/ML health analysis will be available later.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _mutedText,
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
  // AI INSIGHT
  //
  // AI / ML NOT READY YET
  // ============================================================

  Widget _buildAiInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _purple.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: _purple,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Not Ready',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: _purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'AI-powered project insights and recommendations '
            'will appear here when the AI/ML integration is ready.',
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: _softText,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: _openAiInsights,
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: BorderSide(
                  color: _purple.withOpacity(0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'AI Insights — Not Ready Yet',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _toggleNotifications() {
    if (_notificationOverlay != null) {
      _removeNotificationOverlay();
      return;
    }

    _showNotificationOverlay();
  }

  void _showNotificationOverlay() {
    final OverlayState overlay = Overlay.of(context);

    _notificationOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeNotificationOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _notificationLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(-272, 47),
              child: Material(
                color: Colors.transparent,
                child: _buildNotificationDropdown(),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_notificationOverlay!);
  }

  Widget _buildNotificationDropdown() {
    final notifications = _homeData?.notifications ?? [];

    return Container(
      width: 310,
      height: 390,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD9DCE2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _charcoal,
                ),
              ),
              Row(
                children: [
                  if (notifications.any(
                    (item) => !item.isRead,
                  ))
                    TextButton(
                      onPressed: _markAllNotificationsRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                      ),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 10,
                          color: _purple,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: _removeNotificationOverlay,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.close,
                      size: 19,
                      color: _softText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _mutedText,
                      ),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(
                        right: 3,
                        bottom: 2,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) {
                        return const SizedBox(
                          height: 7,
                        );
                      },
                      itemBuilder: (context, index) {
                        final notification = notifications[index];

                        return _buildNotificationItem(
                          notification,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    HomeNotification notification,
  ) {
    final NotificationVisual visual = _notificationVisual(
      notification.type,
    );

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _markNotificationRead(
            notification.id,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: notification.isRead
              ? const Color(0xFFF8F9FB)
              : visual.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFE4E6EA)
                : visual.color.withOpacity(0.30),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: visual.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                visual.icon,
                size: 17,
                color: visual.color,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: notification.isRead
                          ? FontWeight.w600
                          : FontWeight.bold,
                      color: _charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF50545A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _relativeTime(
                      notification.createdAt,
                    ),
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: _mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(
                  top: 4,
                  left: 5,
                ),
                decoration: const BoxDecoration(
                  color: _purple,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MARK NOTIFICATION READ
  // ============================================================

  Future<void> _markNotificationRead(
    int notificationId,
  ) async {
    try {
      final success = await _homeService.markNotificationAsRead(
        notificationId,
      );

      if (!success) {
        return;
      }

      await _loadHomeData();

      if (mounted && _notificationOverlay != null) {
        _removeNotificationOverlay();
        _showNotificationOverlay();
      }
    } catch (_) {}
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS READ
  // ============================================================

  Future<void> _markAllNotificationsRead() async {
    try {
      final success = await _homeService.markAllNotificationsAsRead();

      if (!success) {
        return;
      }

      await _loadHomeData();

      if (mounted && _notificationOverlay != null) {
        _removeNotificationOverlay();
        _showNotificationOverlay();
      }
    } catch (_) {}
  }

  // ============================================================
  // NOTIFICATION VISUAL
  // ============================================================

  NotificationVisual _notificationVisual(
    String type,
  ) {
    final normalized = type.toLowerCase();

    if (normalized.contains('task')) {
      return const NotificationVisual(
        Icons.task_alt,
        _purple,
      );
    }

    if (normalized.contains('risk') || normalized.contains('warning')) {
      return const NotificationVisual(
        Icons.warning_amber_rounded,
        _coral,
      );
    }

    if (normalized.contains('project')) {
      return const NotificationVisual(
        Icons.folder_outlined,
        _blue,
      );
    }

    if (normalized.contains('deadline') || normalized.contains('due')) {
      return const NotificationVisual(
        Icons.schedule,
        _amber,
      );
    }

    if (normalized.contains('complete')) {
      return const NotificationVisual(
        Icons.check_circle_outline,
        _green,
      );
    }

    return const NotificationVisual(
      Icons.notifications_none,
      _purple,
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openProjects() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProjectsScreen(),
      ),
    );

    if (mounted) {
      await _loadHomeData();
    }
  }

  void _openAiInsights() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiInsightsPage(),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _calculateProjectProgress(
    List<Map<String, dynamic>> tasks,
  ) {
    if (tasks.isEmpty) {
      return 0;
    }

    final activeTasks = tasks.where((task) {
      final status = _toInt(task['status']);

      return status != 7;
    }).toList();

    if (activeTasks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final task in activeTasks) {
      final status = _toInt(task['status']);

      if (status == 5) {
        total += 100;
        continue;
      }

      final completion = task['completionPercent'];

      if (completion is num) {
        total += completion.toDouble();
      }
    }

    return (total / activeTasks.length).clamp(0, 100).toDouble();
  }

  Widget _buildStatusBadge(
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String? _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return null;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _relativeTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hour'
          '${difference.inHours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return _formatDate(date) ?? '';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _removeNotificationOverlay() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }
}

// ================================================================
// NOTIFICATION VISUAL
// ================================================================

class NotificationVisual {
  final IconData icon;
  final Color color;

  const NotificationVisual(
    this.icon,
    this.color,
  );
}
