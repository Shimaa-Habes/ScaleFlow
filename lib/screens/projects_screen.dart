import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/mock_data.dart';
import '../models/project.dart';
import '../models/task_item.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import 'project_details_screen.dart';
import 'profile_screen.dart';
import 'ai_insights_screen.dart';
import 'dashboard_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late List<Project> projects;

  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    projects = List<Project>.from(scaleFlowProjects);
  }

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _AddProjectDialog(
          onCreate: (project) {
            setState(() {
              projects.add(project);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.darkCharcoal,
          ),
        ),
        title: const Text(
          'Projects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkCharcoal,
          ),
        ),
        actions: [
          if (_selectedSection == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Add Project',
                onPressed: _showAddProjectDialog,
                icon: const Icon(
                  Icons.add,
                  size: 25,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth < 600 ? constraints.maxWidth : 460.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    0,
                  ),
                  child: Column(
                    children: [
                      _buildSectionTabs(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 180,
                          ),
                          child: _selectedSection == 0
                              ? _buildProjectsContent()
                              : _buildTasksContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
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
  // PROJECTS | TASKS TABS
  // ============================================================

  Widget _buildSectionTabs() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.fieldBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSectionTab(
              title: 'Projects',
              index: 0,
            ),
          ),
          Expanded(
            child: _buildSectionTab(
              title: 'Tasks',
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab({
    required String title,
    required int index,
  }) {
    final bool selected = _selectedSection == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSection = index;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.darkCharcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROJECTS CONTENT
  // ============================================================

  Widget _buildProjectsContent() {
    if (projects.isEmpty) {
      return Center(
        child: _EmptyProjectsState(
          onAdd: _showAddProjectDialog,
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('projects'),
      padding: const EdgeInsets.only(
        top: 2,
        bottom: 24,
      ),
      itemCount: projects.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final Project project = projects[index];

        return _ProjectCard(
          project: project,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailsScreen(
                  project: project,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TASKS CONTENT
  // ============================================================

  Widget _buildTasksContent() {
    final List<_ProjectTask> allTasks = [];

    for (final project in projects) {
      for (final task in project.tasks) {
        allTasks.add(
          _ProjectTask(
            project: project,
            task: task,
          ),
        );
      }
    }

    return _TasksSection(
      key: const ValueKey('tasks'),
      tasks: allTasks,
    );
  }
}

// ============================================================
// PROJECT + TASK WRAPPER
// Uses the existing TaskItem model.
// ============================================================

class _ProjectTask {
  final Project project;
  final TaskItem task;

  const _ProjectTask({
    required this.project,
    required this.task,
  });
}

// ============================================================
// TASKS SECTION
// ============================================================

class _TasksSection extends StatefulWidget {
  final List<_ProjectTask> tasks;

  const _TasksSection({
    super.key,
    required this.tasks,
  });

  @override
  State<_TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<_TasksSection> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filter = 'All';
  String _sort = 'Due Date';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTERED TASKS
  // ============================================================

  List<_ProjectTask> get _filteredTasks {
    List<_ProjectTask> result = List<_ProjectTask>.from(widget.tasks);

    // Search
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();

      result = result.where((item) {
        return item.task.title.toLowerCase().contains(query) ||
            item.project.name.toLowerCase().contains(query);
      }).toList();
    }

    // Filter
    switch (_filter) {
      case 'My Tasks':
        result = result.where((item) {
          return item.project.team.any(
            (member) => member.initials == 'SH',
          );
        }).toList();
        break;

      case 'Today':
        result = result.where((item) {
          return item.task.dueLabel == 'Due Today';
        }).toList();
        break;

      case 'Overdue':
        result = result.where((item) {
          return item.task.dueLabel.toLowerCase().contains('overdue');
        }).toList();
        break;

      case 'Completed':
        result = result.where((item) {
          return item.task.isDone;
        }).toList();
        break;
    }

    // Sort
    switch (_sort) {
      case 'Priority':
        result.sort(
          (a, b) => _priorityValue(a.task.urgency).compareTo(
            _priorityValue(b.task.urgency),
          ),
        );
        break;

      case 'Project':
        result.sort(
          (a, b) => a.project.name.compareTo(
            b.project.name,
          ),
        );
        break;

      case 'Status':
        result.sort(
          (a, b) => _statusValue(a.task).compareTo(
            _statusValue(b.task),
          ),
        );
        break;

      case 'Due Date':
        result.sort(
          (a, b) => _dueValue(a.task).compareTo(
            _dueValue(b.task),
          ),
        );
        break;
    }

    return result;
  }

  int _priorityValue(TaskUrgency urgency) {
    switch (urgency) {
      case TaskUrgency.dueToday:
        return 0;
      case TaskUrgency.dueSoon:
        return 1;
      case TaskUrgency.upcoming:
        return 2;
    }
  }

  int _statusValue(TaskItem task) {
    return task.isDone ? 1 : 0;
  }

  int _dueValue(TaskItem task) {
    if (task.dueLabel == 'Due Today') {
      return 0;
    }

    if (task.dueLabel == 'Due Tomorrow') {
      return 1;
    }

    if (task.dueLabel.toLowerCase().contains('overdue')) {
      return -1;
    }

    return 2;
  }

  // ============================================================
  // QUICK STATS
  // ============================================================

  int get _todayCount {
    return widget.tasks
        .where(
          (item) => item.task.dueLabel == 'Due Today',
        )
        .length;
  }

  int get _overdueCount {
    return widget.tasks
        .where(
          (item) => item.task.dueLabel.toLowerCase().contains('overdue'),
        )
        .length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final tasks = _filteredTasks;

    return Column(
      key: const ValueKey('tasks-section'),
      children: [
        _buildSearchBar(),
        const SizedBox(height: 10),
        _buildFilterTabs(),
        const SizedBox(height: 12),
        _buildQuickStats(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildSortButton(),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: tasks.isEmpty
              ? _buildEmptyTasks()
              : ListView.separated(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    return _buildTaskCard(
                      tasks[index],
                    );
                  },
                ),
        ),
        _buildAiInsight(),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(
          Icons.search,
          size: 21,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(
                  Icons.close,
                  size: 18,
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.fieldBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.fieldBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.dataCyan,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER TABS
  // ============================================================

  Widget _buildFilterTabs() {
    const filters = [
      'All',
      'My Tasks',
      'Today',
      'Overdue',
      'Completed',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final bool selected = _filter == filter;

          return Padding(
            padding: const EdgeInsets.only(
              right: 7,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.dataCyan : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        selected ? AppColors.dataCyan : AppColors.fieldBorder,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // QUICK STATS
  // ============================================================

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard(
          value: '${widget.tasks.length}',
          label: 'Tasks',
          color: AppColors.dataCyan,
        ),
        const SizedBox(width: 8),
        _statCard(
          value: '$_todayCount',
          label: 'Due Today',
          color: AppColors.priorityYellow,
        ),
        const SizedBox(width: 8),
        _statCard(
          value: '$_overdueCount',
          label: 'Overdue',
          color: AppColors.alertCoral,
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: color.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _sort = value;
        });
      },
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'Due Date',
            child: Text('Due Date'),
          ),
          PopupMenuItem(
            value: 'Priority',
            child: Text('Priority'),
          ),
          PopupMenuItem(
            value: 'Project',
            child: Text('Project'),
          ),
          PopupMenuItem(
            value: 'Status',
            child: Text('Status'),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.fieldBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sort,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              _sort,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _buildTaskCard(_ProjectTask item) {
    final TaskItem task = item.task;
    final Project project = item.project;

    final bool completed = task.isDone;
    final Color priorityColor = task.urgency.color;

    final String priorityText = _priorityText(task.urgency);

    final String statusText = completed ? 'Completed' : 'To Do';

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: priorityColor.withOpacity(0.38),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: completed,
              activeColor: priorityColor,
              visualDensity: VisualDensity.compact,
              onChanged: (value) {
                setState(() {
                  task.isDone = value ?? false;
                });
              },
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: completed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.dueLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _buildPill(
                        text: 'Priority: $priorityText',
                        color: priorityColor,
                      ),
                      _buildPill(
                        text: statusText,
                        color: completed
                            ? AppColors.statusGreen
                            : AppColors.dataCyan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(
                top: 5,
                left: 6,
              ),
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priorityText(TaskUrgency urgency) {
    switch (urgency) {
      case TaskUrgency.dueToday:
        return 'High';
      case TaskUrgency.dueSoon:
        return 'Medium';
      case TaskUrgency.upcoming:
        return 'Low';
    }
  }

  Widget _buildPill({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // AI INSIGHT
  // ============================================================

  Widget _buildAiInsight() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 8,
      ),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.tint(
          AppColors.aiPurple,
          0.10,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.aiPurple.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: AppColors.aiPurple,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ScaleFlow AI Insight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Task workload and deadlines are being monitored for potential delays.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
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
  // EMPTY TASKS
  // ============================================================

  Widget _buildEmptyTasks() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 42,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'No tasks found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try another search or filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD PROJECT DIALOG
// ============================================================

class _AddProjectDialog extends StatefulWidget {
  final ValueChanged<Project> onCreate;

  const _AddProjectDialog({
    required this.onCreate,
  });

  @override
  State<_AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<_AddProjectDialog> {
  final _nameController = TextEditingController();

  final _descriptionController = TextEditingController();

  final _linkController = TextEditingController();

  final _startDateController = TextEditingController();

  final _dueDateController = TextEditingController();

  final _memberController = TextEditingController();

  final List<String> members = [];

  String priority = 'Medium';
  String status = 'On Track';
  double progress = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    _memberController.dispose();

    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();

    if (name.isEmpty) {
      return;
    }

    if (!members.contains(name)) {
      setState(() {
        members.add(name);
        _memberController.clear();
      });
    }
  }

  void _removeMember(String member) {
    setState(() {
      members.remove(member);
    });
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    controller.text = '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  void _createProject() {
    final name = _nameController.text.trim();

    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a project name.',
          ),
        ),
      );

      return;
    }

    final project = Project(
      id: 'project-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      subtitle: description.isEmpty ? 'New ScaleFlow project.' : description,
      status:
          status == 'At Risk' ? ProjectStatus.atRisk : ProjectStatus.onTrack,
      percentComplete: progress.round(),
      dueDate: _dueDateController.text.trim().isEmpty
          ? 'Not set'
          : _dueDateController.text.trim(),
      healthPercent: progress.round(),
      healthNote: 'Project health will be updated as project data changes.',
      teamCount: members.length,
      tasksCompleted: 0,
      tasksTotal: 0,
      daysLeft: 0,
      aiInsightTitle: 'AI Recommendation',
      aiInsightBody:
          'AI insights will become available when project data is connected.',
      team: _buildTeamAvatars(),
      tasks: <TaskItem>[],
      projectLink: _linkController.text.trim(),
      memberNames: List<String>.from(members),
    );

    widget.onCreate(project);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name created successfully.',
        ),
      ),
    );
  }

  List<TeamMember> _buildTeamAvatars() {
    final colors = [
      AppColors.usersPink,
      AppColors.dataCyan,
      AppColors.statusGreen,
      AppColors.aiPurple,
      AppColors.alertCoral,
    ];

    return List.generate(
      members.length,
      (index) {
        final name = members[index].trim();

        final initials = name
            .split(RegExp(r'\s+'))
            .where(
              (part) => part.isNotEmpty,
            )
            .take(2)
            .map(
              (part) => part[0].toUpperCase(),
            )
            .join();

        return TeamMember(
          initials: initials.isEmpty ? '?' : initials,
          color: colors[index % colors.length],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 19,
              color: AppColors.textSecondary,
            ),
      filled: true,
      fillColor: AppColors.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFE1E4E7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFE1E4E7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: AppColors.aiPurple,
          width: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceWhite,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
          maxHeight: 680,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                12,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tint(
                        AppColors.aiPurple,
                        0.12,
                      ),
                      borderRadius: BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: AppColors.aiPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Project',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Set up the project details',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: Color(0xFFE9ECEE),
            ),

            // ----------------------------------------------------
            // FORM
            // ----------------------------------------------------

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldTitle(
                      title: 'Project Name',
                      requiredField: true,
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: 'e.g. Mobile App Launch',
                        icon: Icons.folder_outlined,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const _FieldTitle(
                      title: 'Description',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        hint: 'Describe the project briefly',
                        icon: Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const _FieldTitle(
                      title: 'Project Link',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    TextField(
                      controller: _linkController,
                      keyboardType: TextInputType.url,
                      decoration: _inputDecoration(
                        hint: 'https://github.com/...',
                        icon: Icons.link,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const _FieldTitle(
                      title: 'Dates',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startDateController,
                            readOnly: true,
                            onTap: () {
                              _pickDate(
                                context,
                                _startDateController,
                              );
                            },
                            decoration: _inputDecoration(
                              hint: 'Start date',
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _dueDateController,
                            readOnly: true,
                            onTap: () {
                              _pickDate(
                                context,
                                _dueDateController,
                              );
                            },
                            decoration: _inputDecoration(
                              hint: 'Due date',
                              icon: Icons.event_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const _FieldTitle(
                      title: 'Priority',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: _inputDecoration(
                        hint: 'Select priority',
                        icon: Icons.flag_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Low',
                          child: Text('Low'),
                        ),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(
                          value: 'High',
                          child: Text('High'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          priority = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const _FieldTitle(
                      title: 'Project Status',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: _inputDecoration(
                        hint: 'Select status',
                        icon: Icons.track_changes_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'On Track',
                          child: Text('On Track'),
                        ),
                        DropdownMenuItem(
                          value: 'At Risk',
                          child: Text('At Risk'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          status = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const _FieldTitle(
                      title: 'Initial Progress',
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: progress,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            activeColor: AppColors.aiPurple,
                            onChanged: (value) {
                              setState(() {
                                progress = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text(
                            '${progress.round()}%',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const _FieldTitle(
                      title: 'Team Members',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _memberController,
                            onSubmitted: (_) {
                              _addMember();
                            },
                            decoration: _inputDecoration(
                              hint: 'Enter member name',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: IconButton(
                            tooltip: 'Add member',
                            onPressed: _addMember,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.tint(
                                AppColors.usersPink,
                                0.12,
                              ),
                              foregroundColor: AppColors.usersPink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  11,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (members.isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: members.map(
                          (member) {
                            return InputChip(
                              label: Text(
                                member,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 15,
                              ),
                              onDeleted: () {
                                _removeMember(
                                  member,
                                );
                              },
                              backgroundColor: AppColors.tint(
                                AppColors.usersPink,
                                0.08,
                              ),
                              side: BorderSide.none,
                            );
                          },
                        ).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ----------------------------------------------------
            // ACTIONS
            // ----------------------------------------------------

            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                18,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE9ECEE),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            11,
                          ),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFD9DDE1),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aiPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            11,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Create Project',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
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
  }
}

// ============================================================
// FIELD TITLE
// ============================================================

class _FieldTitle extends StatelessWidget {
  final String title;
  final bool requiredField;

  const _FieldTitle({
    required this.title,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.darkCharcoal,
          ),
        ),
        if (requiredField)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.alertCoral,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

// ============================================================
// EMPTY PROJECTS STATE
// ============================================================

class _EmptyProjectsState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyProjectsState({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.tint(
                AppColors.aiPurple,
                0.10,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              color: AppColors.aiPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Projects Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first project to start managing your work.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.aiPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROJECT CARD
// ============================================================

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = project.status.color;

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E6E9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tint(
                        statusColor,
                        0.12,
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      project.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                project.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${project.percentComplete}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (project.percentComplete / 100).clamp(
                    0.0,
                    1.0,
                  ),
                  minHeight: 7,
                  backgroundColor: const Color(
                    0xFFE8EAED,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    statusColor,
                  ),
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Flexible(
                    child: Text(
                      '${project.teamCount} members',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  const Icon(
                    Icons.checklist_outlined,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Flexible(
                    child: Text(
                      '${project.tasksCompleted}/${project.tasksTotal} tasks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF858990),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: Text(
                      'Due ${project.dueDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (project.projectLink.isNotEmpty) ...[
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 15,
                      color: AppColors.dataCyan,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                        project.projectLink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.dataCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
