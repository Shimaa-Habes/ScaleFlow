// ============================================================
// PROJECTS SCREEN WITH TRANSPARENT BACKGROUND OVERLAY
// ============================================================

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
  // Local list of projects initialized from mock data
  late List<Project> projects;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    projects = List<Project>.from(scaleFlowProjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Opens the dialog to add a new project
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

  // Filter projects based on search query and selected status tab
  List<Project> get _filteredProjects {
    List<Project> result = List<Project>.from(projects);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.subtitle.toLowerCase().contains(query);
      }).toList();
    }

    switch (_selectedFilter) {
      case 'Active':
        result =
            result.where((p) => p.status == ProjectStatus.onTrack).toList();
        break;
      case 'On Hold':
        result = result.where((p) => p.status == ProjectStatus.atRisk).toList();
        break;
      case 'Completed':
        result = result.where((p) => p.percentComplete >= 100).toList();
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredProjects;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth < 600 ? constraints.maxWidth : 460.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Stack(
                  children: [
                    // ====================================================
                    // Background Image with Light Opacity (شفافية خفيفة)
                    // ====================================================
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.12, // نسبة شفافية هادئة وخفيفة
                        child: Image.asset(
                          'assets/images/Proj-Image.jpg', // مسار الصورة حسب مشروعك
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // ====================================================
                    // Main Content UI
                    // ====================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row with Title and Add Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Projects',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showAddProjectDialog,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5D5FEF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search Bar Field
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search projects...',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: Color(0xFF5D5FEF),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Filter Status Tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                'All',
                                'Active',
                                'On Hold',
                                'Completed'
                              ].map((filter) {
                                final isSelected = _selectedFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter = filter;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF5D5FEF)
                                            : Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          if (!isSelected)
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.03),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Text(
                                        filter,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Projects List View
                          Expanded(
                            child: filteredList.isEmpty
                                ? Center(
                                    child: _EmptyProjectsState(
                                      onAdd: _showAddProjectDialog,
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: filteredList.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final project = filteredList[index];
                                      return _ProjectCard(
                                        project: project,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProjectDetailsScreen(
                                                project: project,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
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
}

// ============================================================
// PROJECT CARD WIDGET (مع خلفية شبه شفافة لتبرز فوق الصورة)
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
    final Color statusColor = project.status == ProjectStatus.atRisk
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);

    final String statusLabel =
        project.status == ProjectStatus.atRisk ? 'At Risk' : 'On Track';

    return Material(
      color:
          Colors.white.withOpacity(0.92), // شبه شفافة لدمجها مع الخلفية بأناقة
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF1F3F5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D5FEF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_open,
                        color: Color(0xFF5D5FEF), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${project.percentComplete}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text('  •  ',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '${project.tasksTotal > 0 ? project.tasksTotal : 8} tasks',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text('  •  ',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '${project.daysLeft > 0 ? project.daysLeft : 12} days left',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                (project.percentComplete / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF1F3F5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              project.percentComplete >= 100
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((project.memberNames != null &&
                      project.memberNames!.isNotEmpty) ||
                  project.projectLink.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (project.memberNames != null &&
                        project.memberNames!.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.group_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Team: ${project.memberNames!.join(', ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (project.projectLink.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.link,
                              size: 14, color: Color(0xFF5D5FEF)),
                          const SizedBox(width: 3),
                          Text(
                            project.projectLink.startsWith('http')
                                ? 'Workspace URL'
                                : project.projectLink,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D5FEF)),
                          ),
                        ],
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

// ============================================================
// EMPTY PROJECTS STATE
// ============================================================

class _EmptyProjectsState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyProjectsState({required this.onAdd});

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
              color: const Color(0xFF5D5FEF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              color: Color(0xFF5D5FEF),
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
              backgroundColor: const Color(0xFF5D5FEF),
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
// ADD PROJECT DIALOG WIDGET
// ============================================================

class _AddProjectDialog extends StatefulWidget {
  final ValueChanged<Project> onCreate;

  const _AddProjectDialog({required this.onCreate});

  @override
  State<_AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<_AddProjectDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workspaceLinkController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _memberController = TextEditingController();

  final List<String> members = [];
  String status = 'On Track';
  double progress = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _workspaceLinkController.dispose();
    _dueDateController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isEmpty) return;
    if (!members.contains(name)) {
      setState(() {
        members.add(name);
        _memberController.clear();
      });
    }
  }

  Future<void> _pickDate(
      BuildContext context, TextEditingController controller) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) return;
    controller.text = '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  void _createProject() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name.')),
      );
      return;
    }

    final project = Project(
      id: 'project-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      subtitle: _descriptionController.text.trim().isEmpty
          ? 'New custom project.'
          : _descriptionController.text.trim(),
      status:
          status == 'At Risk' ? ProjectStatus.atRisk : ProjectStatus.onTrack,
      percentComplete: progress.round(),
      dueDate: _dueDateController.text.trim().isEmpty
          ? 'Not set'
          : _dueDateController.text.trim(),
      healthPercent: progress.round(),
      healthNote: 'Project health updated successfully.',
      teamCount: members.length,
      tasksCompleted: 0,
      tasksTotal: 10,
      daysLeft: 14,
      aiInsightTitle: 'AI Recommendation',
      aiInsightBody: 'Project initialized successfully.',
      team: [],
      tasks: <TaskItem>[],
      projectLink: _workspaceLinkController.text.trim(),
      memberNames: List<String>.from(members),
    );

    widget.onCreate(project);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Add New Project',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Project Name *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _workspaceLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Workspace / Project URL',
                        hintText: 'https://workspace-link.com or GitHub repo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dueDateController,
                      readOnly: true,
                      onTap: () => _pickDate(context, _dueDateController),
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _memberController,
                            onSubmitted: (_) => _addMember(),
                            decoration: const InputDecoration(
                                labelText: 'Add Team Member Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addMember,
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF5D5FEF), size: 32),
                        ),
                      ],
                    ),
                    if (members.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: members.map((member) {
                          return Chip(
                            label: Text(member,
                                style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setState(() {
                                members.remove(member);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D5FEF),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _createProject,
                      child: const Text('Create'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
