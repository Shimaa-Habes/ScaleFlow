import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';
import '../models/project.dart';
import '../models/task_item.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/health_ring.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import '../widgets/stat_chip.dart';
import '../widgets/task_row.dart';
import '../widgets/team_avatars.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project get project => widget.project;

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _AddTaskDialog(
          onCreate: (task) {
            setState(() {
              project.tasks.add(task);
            });
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT PROJECT
  // ============================================================

  void _showEditProjectDialog() {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(text: project.subtitle);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Edit Project',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.aiPurple,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.aiPurple,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newDescription = descriptionController.text.trim();

                if (newName.isEmpty) {
                  return;
                }

                // Project fields are final in the current model.
                // The edit dialog is therefore prepared for the UI flow,
                // while actual persistent editing will be handled by backend later.
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Project changes will be saved when backend integration is available.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aiPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      descriptionController.dispose();
    });
  }

  // ============================================================
  // ARCHIVE PROJECT
  // ============================================================

  void _showArchiveConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Archive Project?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          content: Text(
            'Are you sure you want to archive "${project.name}"?',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Temporary local behavior:
                // return to the Projects screen after archiving.
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${project.name} has been archived.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertCoral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Archive',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SHARE PROJECT
  // ============================================================

  void _showShareProjectDialog() {
    final projectUrl = project.projectLink.trim().isNotEmpty
        ? project.projectLink.trim()
        : 'scaleflow.app/projects/${project.id}';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.share_outlined,
                color: AppColors.aiPurple,
                size: 21,
              ),
              SizedBox(width: 9),
              Text(
                'Share Project',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project link',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE1E4E7),
                  ),
                ),
                child: Text(
                  projectUrl,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Project link copied.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.copy_outlined,
                size: 17,
              ),
              label: const Text(
                'Copy Link',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aiPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PROJECT MENU
  // ============================================================

  void _handleProjectMenu(String value) {
    switch (value) {
      case 'edit':
        _showEditProjectDialog();
        break;

      case 'archive':
        _showArchiveConfirmation();
        break;

      case 'share':
        _showShareProjectDialog();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: ScaleFlowBottomNav(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pop();
            }
          },
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth =
                  constraints.maxWidth < 600 ? constraints.maxWidth : 460.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(
                          onMenuSelected: _handleProjectMenu,
                        ),

                        const SizedBox(height: 14),

                        _ProjectHeaderCard(
                          project: project,
                        ),

                        const SizedBox(height: 22),

                        Text(
                          'Project Overview',
                          style: DashTextStyles.sectionTitle(),
                        ),

                        const SizedBox(height: 10),

                        _ProjectOverviewRow(
                          project: project,
                        ),

                        const SizedBox(height: 22),

                        _ProjectHealthCard(
                          project: project,
                        ),

                        const SizedBox(height: 22),

                        AiInsightCard(
                          body: project.aiInsightBody,
                        ),

                        const SizedBox(height: 22),

                        // ==================================================
                        // UPCOMING TASKS HEADER
                        // ==================================================

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Tasks',
                              style: DashTextStyles.sectionTitle(),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showAddTaskDialog,
                              icon: const Icon(
                                Icons.add,
                                size: 17,
                              ),
                              label: const Text(
                                'Add Task',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.aiPurple,
                                side: BorderSide(
                                  color: AppColors.aiPurple.withOpacity(0.45),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // ==================================================
                        // PROJECT TASKS
                        // ==================================================

                        if (project.tasks.isEmpty)
                          _EmptyTasksState(
                            onAdd: _showAddTaskDialog,
                          )
                        else
                          ...project.tasks.map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: 6,
                              ),
                              child: TaskRow(
                                task: task,
                              ),
                            ),
                          ),

                        const SizedBox(height: 22),

                        Text(
                          'Project Team',
                          style: DashTextStyles.sectionTitle(),
                        ),

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

// ============================================================
// TOP BAR
// ============================================================

class _TopBar extends StatelessWidget {
  final ValueChanged<String> onMenuSelected;

  const _TopBar({
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ========================================================
        // BACK BUTTON — LEFT
        // ========================================================

        IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.darkCharcoal,
            size: 22,
          ),
        ),

        // ========================================================
        // TITLE — CENTER
        // ========================================================

        Expanded(
          child: Text(
            'Project Details',
            textAlign: TextAlign.center,
            style: DashTextStyles.sectionTitle(
              size: 17,
            ),
          ),
        ),

        // ========================================================
        // MORE MENU — RIGHT
        // ========================================================

        PopupMenuButton<String>(
          tooltip: 'More options',
          onSelected: onMenuSelected,
          icon: const Icon(
            Icons.more_horiz,
            color: AppColors.darkCharcoal,
            size: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: AppColors.darkCharcoal,
                  ),
                  SizedBox(width: 10),
                  Text('Edit Project'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'archive',
              child: Row(
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 19,
                    color: AppColors.alertCoral,
                  ),
                  SizedBox(width: 10),
                  Text('Archive Project'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 19,
                    color: AppColors.aiPurple,
                  ),
                  SizedBox(width: 10),
                  Text('Share Project'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// PROJECT HEADER CARD
// ============================================================

class _ProjectHeaderCard extends StatelessWidget {
  final Project project;

  const _ProjectHeaderCard({
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9ECEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: DashTextStyles.cardTitle(
                    size: 19,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tint(
                    project.status.color,
                    0.14,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.status.label,
                  style: DashTextStyles.label(
                    color: project.status.color,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            project.subtitle,
            style: DashTextStyles.body(),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (project.percentComplete / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: const Color(0xFFE9ECEE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.dataCyan,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${project.percentComplete}% Complete',
                style: DashTextStyles.label(
                  size: 13,
                ),
              ),
              Text(
                project.dueDate,
                style: DashTextStyles.caption(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROJECT OVERVIEW
// ============================================================

class _ProjectOverviewRow extends StatelessWidget {
  final Project project;

  const _ProjectOverviewRow({
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 105,
            child: StatChip(
              value: '${project.teamCount} members',
              label: 'Team',
              color: AppColors.usersPink,
              icon: Icons.people_outline,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 105,
            child: StatChip(
              value: '${project.tasksCompleted} / ${project.tasksTotal}',
              label: 'Tasks completed',
              color: AppColors.dataCyan,
              icon: Icons.checklist_outlined,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 105,
            child: StatChip(
              value: '${project.daysLeft} days',
              label: 'Days Left',
              color: AppColors.priorityYellow,
              icon: Icons.calendar_today_outlined,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROJECT HEALTH
// ============================================================

class _ProjectHealthCard extends StatelessWidget {
  final Project project;

  const _ProjectHealthCard({
    required this.project,
  });

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
        border: Border.all(
          color: const Color(0xFFE9ECEE),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Health',
                  style: DashTextStyles.cardTitle(
                    size: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${project.healthPercent}%',
                      style: DashTextStyles.metric(
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: DashTextStyles.label(
                        color: color,
                        size: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  project.healthNote,
                  style: DashTextStyles.body(),
                ),
              ],
            ),
          ),
          HealthRing(
            percent: project.healthPercent,
            size: 64,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY TASKS STATE
// ============================================================

class _EmptyTasksState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyTasksState({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEE),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checklist_outlined,
            size: 28,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add a task to start tracking project work.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add,
              size: 16,
            ),
            label: const Text(
              'Add Task',
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.aiPurple,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD TASK DIALOG
// ============================================================

class _AddTaskDialog extends StatefulWidget {
  final ValueChanged<TaskItem> onCreate;

  const _AddTaskDialog({
    required this.onCreate,
  });

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _dueController = TextEditingController();

  TaskUrgency urgency = TaskUrgency.upcoming;

  @override
  void dispose() {
    _titleController.dispose();
    _dueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    _dueController.text =
        'Due ${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  void _createTask() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a task title.',
          ),
        ),
      );
      return;
    }

    final dueLabel = _dueController.text.trim().isEmpty
        ? 'No due date'
        : _dueController.text.trim();

    final task = TaskItem(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      dueLabel: dueLabel,
      urgency: urgency,
    );

    widget.onCreate(task);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Task added successfully.',
        ),
      ),
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
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tint(
                        AppColors.aiPurple,
                        0.12,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: AppColors.aiPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add a task to this project',
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
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _TaskFieldTitle(
                title: 'Task Title',
                requiredField: true,
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  hint: 'e.g. Complete API Integration',
                  icon: Icons.task_alt_outlined,
                ),
              ),
              const SizedBox(height: 16),
              const _TaskFieldTitle(
                title: 'Due Date',
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _dueController,
                readOnly: true,
                onTap: _pickDate,
                decoration: _inputDecoration(
                  hint: 'Select due date',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(height: 16),
              const _TaskFieldTitle(
                title: 'Priority',
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<TaskUrgency>(
                initialValue: urgency,
                decoration: _inputDecoration(
                  hint: 'Select priority',
                  icon: Icons.flag_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                    value: TaskUrgency.dueToday,
                    child: Text('High'),
                  ),
                  DropdownMenuItem(
                    value: TaskUrgency.dueSoon,
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: TaskUrgency.upcoming,
                    child: Text('Low'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    urgency = value;
                  });
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aiPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Add Task',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TASK FIELD TITLE
// ============================================================

class _TaskFieldTitle extends StatelessWidget {
  final String title;
  final bool requiredField;

  const _TaskFieldTitle({
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
