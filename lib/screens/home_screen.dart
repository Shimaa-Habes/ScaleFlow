import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/archive_manager.dart';
import '../models/project.dart';
import '../models/task_item.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import 'ai_insights_screen.dart';
import 'profile_screen.dart';
import 'project_details_screen.dart';
import 'projects_screen.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';

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

// ============================================================
// NOTIFICATION MODEL
// ============================================================

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;

  NotificationItem(
    this.title,
    this.message,
    this.time,
    this.icon,
    this.color,
  );
}

const double projectHealthPercent = 0.84;

const String aiInsightText =
    'Website Redesign may be delayed by API Integration.';

// ============================================================
// PRIORITY TASKS ("Today's Tasks")
// ============================================================

final List<TaskItem> priorityTasks = [
  TaskItem(
    id: 'priority-finalize-api',
    title: 'Finalize API Integration',
    dueLabel: 'Due Today',
    urgency: TaskUrgency.dueToday,
  ),
  TaskItem(
    id: 'priority-review-ui',
    title: 'Review UI Components',
    dueLabel: 'Due Tomorrow',
    urgency: TaskUrgency.dueSoon,
  ),
  TaskItem(
    id: 'priority-client-report',
    title: 'Prepare Client Report',
    dueLabel: 'Due Sep 20',
    urgency: TaskUrgency.upcoming,
  ),
  TaskItem(
    id: 'priority-authentication',
    title: 'Complete Authentication Flow',
    dueLabel: 'Due Sep 20',
    urgency: TaskUrgency.dueToday,
  ),
  TaskItem(
    id: 'priority-dependencies',
    title: 'Test Project Dependencies',
    dueLabel: 'Due Sep 21',
    urgency: TaskUrgency.dueSoon,
  ),
  TaskItem(
    id: 'priority-mobile-navigation',
    title: 'Review Mobile Navigation',
    dueLabel: 'Due Sep 22',
    urgency: TaskUrgency.upcoming,
  ),
  TaskItem(
    id: 'priority-ai-inputs',
    title: 'Prepare AI Model Inputs',
    dueLabel: 'Due Sep 23',
    urgency: TaskUrgency.upcoming,
  ),
];

// ============================================================
// NOTIFICATIONS
// ============================================================

final List<NotificationItem> fakeNotifications = [
  NotificationItem(
    'Task Due Today',
    'Finalize API Integration is due today.',
    '10 min ago',
    Icons.task_alt,
    const Color(0xFFD94A3A),
  ),
  NotificationItem(
    'Project Risk Detected',
    'Mobile App Launch has moved to At Risk.',
    '1 hour ago',
    Icons.warning_amber_rounded,
    const Color(0xFFC76B4F),
  ),
  NotificationItem(
    'AI Insight',
    'Website Redesign may be delayed by API Integration.',
    '2 hours ago',
    Icons.auto_awesome,
    const Color(0xFF6C5CE7),
  ),
  NotificationItem(
    'Project Update',
    'Client Portal reached 81% completion.',
    'Yesterday',
    Icons.trending_up,
    const Color(0xFF3F82B8),
  ),
  NotificationItem(
    'Task Completed',
    'Database schema review has been completed.',
    'Yesterday',
    Icons.check_circle_outline,
    const Color(0xFF4F9A5A),
  ),
  NotificationItem(
    'Deadline Reminder',
    'Review UI Components is due tomorrow.',
    '2 days ago',
    Icons.schedule,
    const Color(0xFFC49A00),
  ),
  NotificationItem(
    'New AI Recommendation',
    'ScaleFlow generated a new project recommendation.',
    '3 days ago',
    Icons.auto_awesome,
    const Color(0xFF6C5CE7),
  ),
];

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String get userName => CurrentUser.firstName;

  late final AnimationController _aiBorderController;

  OverlayEntry? _notificationOverlay;

  final LayerLink _notificationLayerLink = LayerLink();

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<String> _filters = const ['All', 'At Risk'];
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

  @override
  void initState() {
    super.initState();

    _avatarColor = _avatarColors[
        DateTime.now().millisecondsSinceEpoch % _avatarColors.length];

    _aiBorderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _removeNotificationOverlay();
    _aiBorderController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Project> get _visibleProjects {
    return scaleFlowProjects
        .where((project) => !ArchiveManager.isArchived(project))
        .where((project) => project.name
            .toLowerCase()
            .contains(_searchQuery.trim().toLowerCase()))
        .where((project) {
      if (_selectedFilter == 'All') return true;
      return project.status.label == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: Stack(
        children: [
          // خلفية دمج الصورة الاحترافية مع تدرج لوني خفيف وأنيق يعكس بيئة العمل
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
                  errorBuilder: (context, error, stackTrace) {
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
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    );
                  },
                ),
                // طبقة تعتيم خفيفة جداً (Overlay) لضمان وضوح النصوص فوق الصورة
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
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 14),
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 22),
                  _buildActiveProjectSection(),
                  const SizedBox(height: 22),
                  _buildTodaysTasksSection(),
                  const SizedBox(height: 20),
                  _buildProjectHealthCard(),
                  const SizedBox(height: 20),
                  _buildAiInsightCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProjectsScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
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

  Widget _buildHeader() {
    final String firstLetter =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '?';

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
            child: IconButton(
              onPressed: _toggleNotifications,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_none,
                size: 22,
                color: _charcoal,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
          const Icon(Icons.search, size: 20, color: _mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search your projects...',
                hintStyle: TextStyle(fontSize: 13, color: _mutedText),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, color: _charcoal),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.close, size: 17, color: _mutedText),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String filter = _filters[index];
          final bool selected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildStatsRow() {
    final stats = [
      (
        icon: Icons.folder_outlined,
        color: const Color(0xFF3F82B8),
        value: '6',
        label: 'Projects'
      ),
      (
        icon: Icons.task_alt_outlined,
        color: _purple,
        value: '24',
        label: 'Tasks'
      ),
      (
        icon: Icons.check_circle_outline,
        color: _green,
        value: '18',
        label: 'Completed'
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final int index = entry.key;
        final stat = entry.value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == stats.length - 1 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
                    child: Icon(stat.icon, size: 16, color: stat.color),
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
                    style: const TextStyle(fontSize: 10.5, color: _mutedText),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

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
                  fontWeight: FontWeight.bold, fontSize: 15, color: _charcoal),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openProjects,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'See All',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _purple),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (projects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _searchQuery.isEmpty
                  ? 'No projects match "$_selectedFilter"'
                  : 'No projects match "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _mutedText),
            ),
          )
        else
          _buildActiveProjectCard(projects.first),
      ],
    );
  }

  Widget _buildActiveProjectCard(Project project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProjectDetailsScreen(project: project)),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
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
                'assets/images/project_cover.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _purple.withOpacity(0.85),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined,
                        size: 34, color: Colors.white70),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _charcoal),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: _mutedText),
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
                            '${project.percentComplete}%',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _charcoal),
                          ),
                          const Text(
                            'Progress',
                            style: TextStyle(fontSize: 10, color: _mutedText),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: project.percentComplete / 100,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE8EAED),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                project.status.color),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: _mutedText),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${project.dueDate}',
                            style:
                                const TextStyle(fontSize: 11, color: _softText),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.checklist_outlined,
                              size: 13, color: _mutedText),
                          const SizedBox(width: 4),
                          Text(
                            '${project.tasksCompleted}/${project.tasksTotal} Tasks',
                            style:
                                const TextStyle(fontSize: 11, color: _softText),
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
    return Container(
      width: 310,
      height: 390,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9DCE2), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 6)),
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
                    color: _charcoal),
              ),
              IconButton(
                onPressed: _removeNotificationOverlay,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close, size: 19, color: _softText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.only(right: 3, bottom: 2),
                itemCount: fakeNotifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final NotificationItem notification =
                      fakeNotifications[index];

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: notification.color.withOpacity(0.30),
                          width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: notification.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(notification.icon,
                              size: 17, color: notification.color),
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
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _charcoal),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notification.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10.5, color: Color(0xFF50545A)),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notification.time,
                                style: const TextStyle(
                                    fontSize: 9.5, color: _mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeNotificationOverlay() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  void _openProjects() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProjectsScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openAiInsights() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AiInsightsPage()));
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildProjectHealthCard() {
    final int healthValue = (projectHealthPercent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.40), width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Project Health',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _charcoal),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '$healthValue%',
                      style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: _charcoal),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Healthy',
                      style: TextStyle(
                          color: Color(0xFF3F7F46),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '+6% compared with last week',
                  style: TextStyle(fontSize: 11, color: _softText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: CircularProgressIndicator(
                    value: projectHealthPercent,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFFE7E9EC),
                    valueColor: AlwaysStoppedAnimation<Color>(_green),
                  ),
                ),
                Text(
                  '$healthValue%',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _charcoal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return AnimatedBuilder(
      animation: _aiBorderController,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowingBorderPainter(progress: _aiBorderController.value),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AiInsightCard(
              body: aiInsightText,
              actionLabel: 'View recommendation',
              onTap: _openAiInsights,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaysTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Tasks",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: _charcoal),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TasksScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'See All',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _purple),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...priorityTasks.map((task) {
          final bool isCompleted = task.isDone;
          final Color taskColor = task.urgency.color;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 5,
                    offset: Offset(0, 2)),
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
                  child: Icon(Icons.task_alt, size: 17, color: taskColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
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
                        task.dueLabel,
                        style:
                            const TextStyle(fontSize: 10.5, color: _softText),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isCompleted,
                  activeColor: taskColor,
                  side: BorderSide(
                      color: taskColor.withOpacity(0.90), width: 1.5),
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? value) {
                    setState(() {
                      task.isDone = value ?? false;
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _GlowingBorderPainter extends CustomPainter {
  final double progress;

  _GlowingBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect =
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(16));

    final SweepGradient gradient = SweepGradient(
      transform: GradientRotation(progress * 2 * 3.14159265359),
      colors: const [
        Color(0xFF6C5CE7),
        Color(0xFFB9B0F2),
        Color(0xFF6C5CE7),
        Color(0xFFD8D2F8),
        Color(0xFF6C5CE7),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final Paint glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(rrect, glowPaint);

    final Paint borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
