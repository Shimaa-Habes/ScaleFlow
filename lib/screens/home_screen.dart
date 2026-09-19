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
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// OVERVIEW MODEL
// ============================================================

class OverviewStat {
  final String value;
  final String label;
  final Color color;

  OverviewStat(
    this.value,
    this.label,
    this.color,
  );
}

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

// ============================================================
// OVERVIEW DATA
// ============================================================

final List<OverviewStat> overviewStats = [
  OverviewStat(
    '6',
    'Active Projects',
    const Color(0xFFCFE8D2),
  ),
  OverviewStat(
    '18',
    'Tasks Due',
    const Color(0xFFC9E2F6),
  ),
  OverviewStat(
    '7',
    'Overdue',
    const Color(0xFFF4CACA),
  ),
  OverviewStat(
    '2',
    'At Risk',
    const Color(0xFFF2E0B5),
  ),
];

const double projectHealthPercent = 0.84;

const String aiInsightText =
    'Website Redesign may be delayed by API Integration.';

// ============================================================
// PRIORITY TASKS
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

  // Avatar color is selected once and stays fixed
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

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    // Choose avatar color only once.
    // It will not change when setState() is called.
    _avatarColor = _avatarColors[
        DateTime.now().millisecondsSinceEpoch % _avatarColors.length];

    _aiBorderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _removeNotificationOverlay();
    _aiBorderController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildOverviewSection(),
              const SizedBox(height: 20),
              _buildProjectHealthCard(),
              const SizedBox(height: 20),
              _buildMyProjectsSection(),
              const SizedBox(height: 20),
              _buildAiInsightCard(),
              const SizedBox(height: 20),
              _buildPriorityTasksSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      // ========================================================
      // SHARED SCALEFLOW BOTTOM NAVIGATION
      // Home = index 0
      // ========================================================

      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProjectsScreen(),
              ),
            );
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
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final String firstLetter =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 1),
              Text(
                'Good morning, $userName 👋',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2D30),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Here's what's happening across your projects today.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666A70),
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // NOTIFICATION BUTTON
        // ======================================================

        CompositedTransformTarget(
          link: _notificationLayerLink,
          child: SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              onPressed: _toggleNotifications,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_none,
                size: 25,
                color: Color(0xFF2C2D30),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ======================================================
        // PROFILE AVATAR
        // ======================================================

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openProfile,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 81, 74, 74),
                  width: 0.5,
                ),
              ),
              child: CircleAvatar(
                radius: 18,

                // If there is no image, show the fixed avatar color.
                // If there is an image, no background color is shown.
                backgroundColor: CurrentUser.profileImage == null
                    ? _avatarColor
                    : Colors.transparent,

                // Show the actual uploaded image.
                backgroundImage: CurrentUser.profileImage != null
                    ? MemoryImage(CurrentUser.profileImage!)
                    : null,

                // Show the first letter only when there is no image.
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
      ],
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
              offset: const Offset(-272, 43),
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
          width: 1,
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
                  color: Color(0xFF2C2D30),
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
                  color: Color(0xFF666A70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  right: 3,
                  bottom: 2,
                ),
                itemCount: fakeNotifications.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(height: 7);
                },
                itemBuilder: (context, index) {
                  final NotificationItem notification =
                      fakeNotifications[index];

                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: notification.color.withOpacity(0.30),
                          width: 1,
                        ),
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
                            child: Icon(
                              notification.icon,
                              size: 17,
                              color: notification.color,
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C2D30),
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
                                  notification.time,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF858990),
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

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openProjects() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProjectsScreen(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
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
      // Rebuild Home after returning from Profile.
      // This makes the newly uploaded/deleted image appear immediately.
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  void _openArchive() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final archivedProjects = ArchiveManager.archivedProjects;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Archive',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2D30),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: archivedProjects.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.archive_outlined,
                              size: 45,
                              color: Color(0xFF858990),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No archived projects',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2D30),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: archivedProjects.length,
                        separatorBuilder: (_, __) {
                          return const SizedBox(height: 8);
                        },
                        itemBuilder: (context, index) {
                          final Project project = archivedProjects[index];

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD9DCE2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2C2D30),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${project.percentComplete}% Complete',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF666A70),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ArchiveManager.restore(project);

                                    dialogSetState(() {});

                                    setState(() {});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${project.name} restored.',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Restore',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TODAY'S OVERVIEW
  // ============================================================

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Overview",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF2C2D30),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: overviewStats.asMap().entries.map((entry) {
            final int index = entry.key;
            final OverviewStat stat = entry.value;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == overviewStats.length - 1 ? 0 : 8,
                ),
                child: Container(
                  height: 84,
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    9,
                    8,
                    8,
                  ),
                  decoration: BoxDecoration(
                    color: stat.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x332C2D30),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 25,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            stat.value,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2D30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            stat.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.15,
                              color: Color(0xFF3F4247),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // PROJECT HEALTH
  // ============================================================

  Widget _buildProjectHealthCard() {
    final int healthValue = (projectHealthPercent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4F9A5A).withOpacity(0.40),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Project Health',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2D30),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '$healthValue%',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2D30),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Healthy',
                      style: TextStyle(
                        color: Color(0xFF3F7F46),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '+6% compared with last week',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666A70),
                  ),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4F9A5A),
                    ),
                  ),
                ),
                Text(
                  '$healthValue%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2D30),
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
  // MY PROJECTS
  // ============================================================

  Widget _buildMyProjectsSection() {
    final visibleProjects = scaleFlowProjects
        .where(
          (project) => !ArchiveManager.isArchived(project),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // My Projects + Archive
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Projects',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2C2D30),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openArchive,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.archive_outlined,
                        size: 18,
                        color: Color(0xFF2C2D30),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Archive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2D30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 142,
          child: visibleProjects.isEmpty
              ? const Center(
                  child: Text(
                    'No active projects',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF858990),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    bottom: 3,
                  ),
                  itemCount: visibleProjects.length,
                  itemBuilder: (context, index) {
                    final Project project = visibleProjects[index];

                    final Color projectColor = project.status.color;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailsScreen(
                              project: project,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                      child: Container(
                        width: 165,
                        margin: const EdgeInsets.only(
                          right: 10,
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          12,
                          12,
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: projectColor.withOpacity(0.78),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2D30),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${project.percentComplete}% Complete',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F5359),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: project.percentComplete / 100,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE8EAED),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  projectColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: projectColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                project.status.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: projectColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // AI INSIGHT
  // ============================================================

  Widget _buildAiInsightCard() {
    return AnimatedBuilder(
      animation: _aiBorderController,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowingBorderPainter(
            progress: _aiBorderController.value,
          ),
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

  // ============================================================
  // PRIORITY TASKS
  // ============================================================

  Widget _buildPriorityTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF2C2D30),
          ),
        ),
        const SizedBox(height: 10),
        ...priorityTasks.map(
          (task) {
            final bool isCompleted = task.isDone;
            final Color taskColor = task.urgency.color;

            return Container(
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: taskColor.withOpacity(0.82),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    activeColor: taskColor,
                    side: BorderSide(
                      color: taskColor.withOpacity(0.90),
                      width: 1.5,
                    ),
                    visualDensity: VisualDensity.compact,
                    onChanged: (bool? value) {
                      setState(() {
                        task.isDone = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
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
                            color: isCompleted
                                ? const Color(0xFF8A8D92)
                                : const Color(0xFF2C2D30),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.dueLabel,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF666A70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: taskColor,
                      shape: BoxShape.circle,
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
}

// ============================================================
// ANIMATED AI BORDER
// ============================================================

class _GlowingBorderPainter extends CustomPainter {
  final double progress;

  _GlowingBorderPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Rect rect = Offset.zero & size;

    final RRect rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(16),
    );

    final SweepGradient gradient = SweepGradient(
      transform: GradientRotation(
        progress * 2 * 3.14159265359,
      ),
      colors: const [
        Color(0xFF6C5CE7),
        Color(0xFFB9B0F2),
        Color(0xFF6C5CE7),
        Color(0xFFD8D2F8),
        Color(0xFF6C5CE7),
      ],
      stops: const [
        0.0,
        0.25,
        0.5,
        0.75,
        1.0,
      ],
    );

    // Soft glow
    final Paint glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        2,
      );

    canvas.drawRRect(
      rrect,
      glowPaint,
    );

    // Sharp border
    final Paint borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawRRect(
      rrect,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _GlowingBorderPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
