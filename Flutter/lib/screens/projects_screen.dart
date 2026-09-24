// ============================================================
// PROJECTS SCREEN - FULL BACKEND + AI INTEGRATION
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import '../services/auth_service.dart';
import '../models/project.dart';

import 'profile_screen.dart';
import 'ai_insights_screen.dart';
import 'dashboard_screen.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const String _baseUrl = 'http://localhost:5233/api';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _projects = [];

  final Map<int, List<Map<String, dynamic>>> _projectTasks = {};

  String _searchQuery = '';
  String _selectedFilter = 'All';

  bool _isLoading = true;
  bool _isCreating = false;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  Map<String, String> _headers() {
    final token = AuthService.accessToken;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // LOAD PROJECTS
  // ============================================================

  Future<void> _loadProjects() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/Projects?page=1&pageSize=100',
        ),
        headers: _headers(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to load projects: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;

      final projects = <Map<String, dynamic>>[];

      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            projects.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _projects
          ..clear()
          ..addAll(projects);

        _isLoading = false;
        _projectTasks.clear();
      });

      await _loadTasksForProjects(projects);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD TASKS FOR PROJECTS
  // ============================================================

  Future<void> _loadTasksForProjects(
    List<Map<String, dynamic>> projects,
  ) async {
    for (final project in projects) {
      final projectId = _toInt(project['id']);

      if (projectId == null || projectId <= 0) {
        continue;
      }

      try {
        final response = await http.get(
          Uri.parse(
            '$_baseUrl/projects/$projectId/Tasks?page=1&pageSize=100',
          ),
          headers: _headers(),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }

        final decoded = jsonDecode(response.body);

        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;

        final tasks = <Map<String, dynamic>>[];

        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              tasks.add(
                Map<String, dynamic>.from(item),
              );
            }
          }
        }

        if (!mounted) return;

        setState(() {
          _projectTasks[projectId] = tasks;
        });
      } catch (_) {
        // Task loading failure must not prevent
        // projects from being displayed.
      }
    }
  }

  // ============================================================
  // CREATE PROJECT
  // ============================================================

  Future<void> _createProject({
    required String name,
    String? description,
    String? workspaceUrl,
    int progress = 0,
    String statusLabel = 'On Track',
    DateTime? startDate,
    DateTime? endDate,
    List<String> memberNames = const [],
    XFile? image,
  }) async {
    if (_isCreating) return;

    if (mounted) {
      setState(() {
        _isCreating = true;
      });
    }

    try {
      // Backend ProjectStatus:
      // Draft = 0
      // Planning = 1
      // Active = 2
      // OnHold = 3
      // Completed = 4
      // Cancelled = 5
      // Archived = 6

      const backendStatus = 2;

      final body = {
        'name': name.trim(),
        'description': description == null || description.trim().isEmpty
            ? null
            : description.trim(),
        'workspaceUrl': workspaceUrl == null || workspaceUrl.trim().isEmpty
            ? null
            : workspaceUrl.trim(),
        'progress': progress.clamp(0, 100),
        'isAtRisk': statusLabel == 'At Risk',
        'status': backendStatus,
        'priority': 2,
        'budget': null,
        'startDate': startDate?.toUtc().toIso8601String(),
        'endDate': endDate?.toUtc().toIso8601String(),

        // Current create-project endpoint accepts user IDs.
        // The UI currently stores member names only, therefore
        // we do not invent user IDs.
        'memberUserIds': <int>[],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/Projects'),
        headers: _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Failed to create project.';

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            if (decoded['message'] != null) {
              message = decoded['message'].toString();
            }

            if (decoded['errors'] != null) {
              message = decoded['errors'].toString();
            }
          }
        } catch (_) {}

        throw Exception(message);
      }

      int? createdProjectId;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          if (data is Map<String, dynamic>) {
            createdProjectId = _toInt(data['id']);
          }
        }
      } catch (_) {}

      if (image != null && createdProjectId != null) {
        await _uploadProjectImage(
          createdProjectId,
          image,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            image != null
                ? 'Project created successfully with image.'
                : 'Project created successfully.',
          ),
        ),
      );

      await _loadProjects();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  // ============================================================
  // UPLOAD PROJECT IMAGE
  // ============================================================

  Future<void> _uploadProjectImage(
    int projectId,
    XFile image,
  ) async {
    final token = AuthService.accessToken;

    final bytes = await image.readAsBytes();

    if (image.name.toLowerCase().endsWith('.webp')) {
      throw Exception(
        'WEBP images are not supported.',
      );
    }

    const maxSize = 5 * 1024 * 1024;

    if (bytes.length > maxSize) {
      throw Exception(
        'Project image must be 5 MB or smaller.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$_baseUrl/Projects/$projectId/image',
      ),
    );

    request.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Project image upload failed.';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          }

          if (decoded['data'] is Map) {
            final data = Map<String, dynamic>.from(
              decoded['data'],
            );

            if (data['message'] != null) {
              message = data['message'].toString();
            }
          }
        }
      } catch (_) {}

      throw Exception(message);
    }
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<Map<String, dynamic>> get _filteredProjects {
    var result = List<Map<String, dynamic>>.from(
      _projects,
    );

    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((project) {
        final name = project['name']?.toString().toLowerCase() ?? '';

        final description =
            project['description']?.toString().toLowerCase() ?? '';

        return name.contains(query) || description.contains(query);
      }).toList();
    }

    switch (_selectedFilter) {
      case 'Active':
        result = result.where((project) {
          return !_isCompleted(project) && !_isArchived(project);
        }).toList();
        break;

      case 'At Risk':
        result = result.where(_isAtRisk).toList();
        break;

      case 'Completed':
        result = result.where(_isCompleted).toList();
        break;
    }

    return result;
  }

  // ============================================================
  // PROJECT STATUS HELPERS
  // ============================================================

  bool _isArchived(
    Map<String, dynamic> project,
  ) {
    return project['isArchived'] == true || project['isDeleted'] == true;
  }

  bool _isCompleted(
    Map<String, dynamic> project,
  ) {
    final status = _toInt(project['status']);
    final projectId = _toInt(project['id']);

    if (projectId != null) {
      final tasks = _projectTasks[projectId] ?? [];

      final activeTasks = tasks.where((task) {
        final taskStatus = _toInt(task['status']);

        return taskStatus != 7;
      }).toList();

      if (activeTasks.isNotEmpty &&
          activeTasks.every(
            (task) => _toInt(task['status']) == 5,
          )) {
        return true;
      }
    }

    return status == 4;
  }

  bool _isAtRisk(
    Map<String, dynamic> project,
  ) {
    if (project['isAtRisk'] == true) {
      return true;
    }

    final projectId = _toInt(project['id']);

    if (projectId != null) {
      final tasks = _projectTasks[projectId] ?? [];

      final now = DateTime.now();

      for (final task in tasks) {
        final status = _toInt(task['status']);

        // Completed.
        if (status == 5) {
          continue;
        }

        // Cancelled/archived.
        if (status == 7) {
          continue;
        }

        // Blocked.
        if (status == 6) {
          return true;
        }

        final plannedEnd = _parseDate(task['plannedEnd']);

        if (plannedEnd != null && plannedEnd.isBefore(now)) {
          return true;
        }
      }
    }

    final endDate = _parseDate(project['endDate']);

    if (endDate != null &&
        endDate.isBefore(DateTime.now()) &&
        !_isCompleted(project)) {
      return true;
    }

    return false;
  }

  // ============================================================
  // PROJECT PROGRESS
  // ============================================================

  double _projectProgress(
    Map<String, dynamic> project,
  ) {
    final projectId = _toInt(project['id']);

    final tasks = projectId == null
        ? <Map<String, dynamic>>[]
        : (_projectTasks[projectId] ?? []);

    final validTasks = tasks.where((task) {
      return _toInt(task['status']) != 7;
    }).toList();

    if (validTasks.isNotEmpty) {
      final completed = validTasks.where((task) {
        return _toInt(task['status']) == 5;
      }).length;

      return (completed / validTasks.length * 100).clamp(0, 100);
    }

    final backendProgress = (project['progress'] as num?)?.toDouble();

    return (backendProgress ?? 0).clamp(0, 100);
  }

  int _tasksTotal(
    Map<String, dynamic> project,
  ) {
    final projectId = _toInt(project['id']);

    if (projectId == null) return 0;

    return (_projectTasks[projectId] ?? [])
        .where(
          (task) => _toInt(task['status']) != 7,
        )
        .length;
  }

  int _tasksCompleted(
    Map<String, dynamic> project,
  ) {
    final projectId = _toInt(project['id']);

    if (projectId == null) return 0;

    return (_projectTasks[projectId] ?? [])
        .where(
          (task) => _toInt(task['status']) == 5,
        )
        .length;
  }

  int _daysLeft(
    Map<String, dynamic> project,
  ) {
    final endDate = _parseDate(project['endDate']);

    if (endDate == null) return 0;

    final now = DateTime.now();

    return endDate.difference(now).inDays;
  }

  // ============================================================
  // OPEN AI INSIGHTS
  // ============================================================

  void _openAiInsights(
    BuildContext sheetContext,
    int projectId,
  ) {
    if (projectId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open AI Insights because the project ID is missing.',
          ),
        ),
      );

      return;
    }

    Navigator.of(sheetContext).pop();
    print('OPENING AI FOR PROJECT ID: $projectId');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiInsightsPage(
          projectId: projectId,
        ),
      ),
    );
  }

  // ============================================================
  // PROJECT DETAILS
  // ============================================================

  void _openProject(
    Map<String, dynamic> project,
  ) {
    final projectId = _toInt(project['id']);

    if (projectId == null || projectId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open this project because its ID is missing.',
          ),
        ),
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final tasks = _projectTasks[projectId] ?? [];

        final progress = _projectProgress(project);

        final completed = _tasksCompleted(project);

        final total = _tasksTotal(project);

        final imageUrl = project['imageUrl']?.toString();

        final screenHeight = MediaQuery.sizeOf(
          sheetContext,
        ).height;

        final isAtRisk = _isAtRisk(project);

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // DRAG HANDLE
                  // ------------------------------------------------

                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFD9DCE1,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // PROJECT IMAGE
                  // ------------------------------------------------

                  if (imageUrl != null && imageUrl.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      child: Image.network(
                        _absoluteImageUrl(
                          imageUrl,
                        ),
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            width: double.infinity,
                            height: 100,
                            color: const Color(
                              0xFFF8F9FB,
                            ),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(
                                0xFF6C5CE7,
                              ),
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),

                  if (imageUrl != null && imageUrl.trim().isNotEmpty)
                    const SizedBox(
                      height: 14,
                    ),

                  // ------------------------------------------------
                  // PROJECT NAME
                  // ------------------------------------------------

                  Text(
                    project['name']?.toString() ?? 'Project',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // ------------------------------------------------
                  // DESCRIPTION
                  // ------------------------------------------------

                  Text(
                    project['description']?.toString().trim().isNotEmpty == true
                        ? project['description'].toString()
                        : 'No project description.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // STATISTICS
                  // ------------------------------------------------

                  Row(
                    children: [
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.task_alt,
                          label: 'Tasks',
                          value: '$completed / $total',
                        ),
                      ),
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Days Left',
                          value: '${_daysLeft(project)}',
                        ),
                      ),
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.insights_outlined,
                          label: 'Progress',
                          value: '${progress.round()}%',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // PROJECT STATUS
                  // ------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isAtRisk
                          ? const Color(
                              0xFFE88973,
                            ).withOpacity(0.08)
                          : const Color(
                              0xFF72B968,
                            ).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color: isAtRisk
                            ? const Color(
                                0xFFE88973,
                              ).withOpacity(0.18)
                            : const Color(
                                0xFF72B968,
                              ).withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAtRisk
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          size: 19,
                          color: isAtRisk
                              ? const Color(
                                  0xFFE88973,
                                )
                              : const Color(
                                  0xFF72B968,
                                ),
                        ),
                        const SizedBox(
                          width: 9,
                        ),
                        Expanded(
                          child: Text(
                            isAtRisk
                                ? 'This project has an overdue or blocked task.'
                                : 'This project is currently on track.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAtRisk
                                  ? const Color(
                                      0xFFE88973,
                                    )
                                  : const Color(
                                      0xFF72B968,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // AI INSIGHTS
                  // ------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF6C5CE7,
                      ).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFF6C5CE7,
                        ).withOpacity(0.13),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6C5CE7,
                                ).withOpacity(
                                  0.10,
                                ),
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Color(
                                  0xFF6C5CE7,
                                ),
                                size: 20,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Insights',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    'Analyze this project using the ScaleFlow Risk Model.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 13,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _openAiInsights(
                                sheetContext,
                                projectId,
                              );
                            },
                            icon: const Icon(
                              Icons.auto_awesome,
                              size: 17,
                            ),
                            label: const Text(
                              'Open AI Insights',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF6C5CE7,
                              ),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ------------------------------------------------
                  // OPEN PROJECT DETAILS
                  // ------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          sheetContext,
                        ).pop();

                        final projectModel = _toProjectModel(
                          project,
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailsScreen(
                              project: projectModel,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 18,
                      ),
                      label: const Text(
                        'Open Project Details',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(
                          0xFF5D5FEF,
                        ),
                        side: const BorderSide(
                          color: Color(
                            0xFF5D5FEF,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (tasks.isEmpty)
                    const Text(
                      'No tasks found for this project.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONVERT BACKEND PROJECT TO PROJECT MODEL
  // ============================================================

  Project _toProjectModel(
    Map<String, dynamic> project,
  ) {
    final projectId = _toInt(project['id']) ?? 0;

    final projectProgress = _projectProgress(project);

    final tasksTotal = _tasksTotal(project);

    final tasksCompleted = _tasksCompleted(project);

    final daysLeft = _daysLeft(project);

    final isAtRisk = _isAtRisk(project);

    final endDate = _parseDate(project['endDate']);

    String dueDate = 'Not set';

    if (endDate != null) {
      dueDate = '${endDate.month.toString().padLeft(2, '0')}/'
          '${endDate.day.toString().padLeft(2, '0')}/'
          '${endDate.year}';
    }

    return Project(
      id: projectId.toString(),

      name: project['name']?.toString().trim().isNotEmpty == true
          ? project['name'].toString()
          : 'Unnamed Project',

      subtitle: project['description']?.toString() ?? '',

      status: isAtRisk ? ProjectStatus.atRisk : ProjectStatus.onTrack,

      percentComplete: projectProgress.round(),

      dueDate: dueDate,

      // The real AI risk analysis is available
      // through AiInsightsPage.
      //
      // These two values are UI fallback values
      // for the Project model only.
      healthPercent: isAtRisk ? 60 : 84,

      healthNote: isAtRisk
          ? 'This project has an overdue or blocked task.'
          : 'Project is currently on track.',

      teamCount: 0,

      tasksCompleted: tasksCompleted,

      tasksTotal: tasksTotal,

      daysLeft: daysLeft,

      aiInsightTitle: 'AI Insights',

      aiInsightBody: 'AI risk analysis is available for this project.',

      team: const [],

      tasks: const [],

      projectLink: project['workspaceUrl']?.toString() ?? '',

      memberNames: const [],
    );
  }

  // ============================================================
  // ADD PROJECT DIALOG
  // ============================================================

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _AddProjectDialog(
          onCreate: ({
            required String name,
            String? description,
            String? workspaceUrl,
            required int progress,
            required String status,
            DateTime? startDate,
            DateTime? endDate,
            required List<String> memberNames,
            XFile? image,
          }) async {
            await _createProject(
              name: name,
              description: description,
              workspaceUrl: workspaceUrl,
              progress: progress,
              statusLabel: status,
              startDate: startDate,
              endDate: endDate,
              memberNames: memberNames,
              image: image,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // IMAGE URL HELPER
  // ============================================================

  String _absoluteImageUrl(
    String imageUrl,
  ) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    if (imageUrl.startsWith('/')) {
      return 'http://localhost:5233$imageUrl';
    }

    return 'http://localhost:5233/$imageUrl';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final filteredList = _filteredProjects;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final maxWidth =
                constraints.maxWidth < 600 ? constraints.maxWidth : 460.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.asset(
                          'assets/images/Proj-Image.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ==================================================
                          // HEADER
                          // ==================================================

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
                                    color: Color(
                                      0xFF5D5FEF,
                                    ),
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

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // SEARCH
                          // ==================================================

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
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();

                                        setState(
                                          () {
                                            _searchQuery = '';
                                          },
                                        );
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white.withOpacity(
                                0.92,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  24,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  24,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  24,
                                ),
                                borderSide: const BorderSide(
                                  color: Color(
                                    0xFF5D5FEF,
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // FILTERS
                          // ==================================================

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                'All',
                                'Active',
                                'At Risk',
                                'Completed',
                              ].map(
                                (filter) {
                                  final isSelected = _selectedFilter == filter;

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(
                                          () {
                                            _selectedFilter = filter;
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(
                                                  0xFF5D5FEF,
                                                )
                                              : Colors.white.withOpacity(
                                                  0.92,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                },
                              ).toList(),
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // CONTENT
                          // ==================================================

                          Expanded(
                            child: _buildContent(
                              filteredList,
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

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

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
            // AI Insights requires a specific projectId.
            // We intentionally do not select a random project.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Select a project first to open AI Insights.',
                ),
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
  // CONTENT BUILDER
  // ============================================================

  Widget _buildContent(
    List<Map<String, dynamic>> filteredList,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5D5FEF),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: Color(
                  0xFF858990,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'Unable to load projects',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed: _loadProjects,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF5D5FEF,
                  ),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredList.isEmpty) {
      return _EmptyProjectsState(
        onAdd: _showAddProjectDialog,
        hasProjects: _projects.isNotEmpty,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF5D5FEF),
      onRefresh: _loadProjects,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: 24,
        ),
        itemCount: filteredList.length,
        separatorBuilder: (_, __) => const SizedBox(
          height: 12,
        ),
        itemBuilder: (context, index) {
          final project = filteredList[index];

          final projectId = _toInt(
                project['id'],
              ) ??
              0;

          return _ProjectCard(
            project: project,
            tasks: _projectTasks[projectId] ?? const [],
            isAtRisk: _isAtRisk(project),
            progress: _projectProgress(
              project,
            ),
            tasksCompleted: _tasksCompleted(
              project,
            ),
            tasksTotal: _tasksTotal(
              project,
            ),
            daysLeft: _daysLeft(
              project,
            ),
            onTap: () => _openProject(
              project,
            ),
            imageUrl: project['imageUrl']?.toString(),
          );
        },
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int? _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    )?.toLocal();
  }
}

// ============================================================
// PROJECT CARD
// ============================================================

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final List<Map<String, dynamic>> tasks;
  final bool isAtRisk;
  final double progress;
  final int tasksCompleted;
  final int tasksTotal;
  final int daysLeft;
  final VoidCallback onTap;
  final String? imageUrl;

  const _ProjectCard({
    required this.project,
    required this.tasks,
    required this.isAtRisk,
    required this.progress,
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.daysLeft,
    required this.onTap,
    this.imageUrl,
  });

  String _absoluteImageUrl(
    String value,
  ) {
    if (value.startsWith(
          'http://',
        ) ||
        value.startsWith(
          'https://',
        )) {
      return value;
    }

    if (value.startsWith('/')) {
      return 'http://localhost:5233$value';
    }

    return 'http://localhost:5233/$value';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final statusColor =
        isAtRisk ? const Color(0xFFE88973) : const Color(0xFF72B968);

    final statusLabel = isAtRisk ? 'At Risk' : 'On Track';

    final name = project['name']?.toString() ?? 'Unnamed Project';

    final description = project['description']?.toString() ?? '';

    final progressValue = (progress / 100).clamp(0.0, 1.0);

    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.white.withOpacity(
        0.94,
      ),
      borderRadius: BorderRadius.circular(
        16,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          16,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: const Color(
                0xFFF1F3F5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF6C5CE7,
                      ).withOpacity(
                        0.09,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: hasImage
                        ? Image.network(
                            _absoluteImageUrl(
                              imageUrl!,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (
                              _,
                              __,
                              ___,
                            ) {
                              return const Icon(
                                Icons.folder_open_outlined,
                                color: Color(
                                  0xFF6C5CE7,
                                ),
                                size: 27,
                              );
                            },
                          )
                        : const Icon(
                            Icons.folder_open_outlined,
                            color: Color(
                              0xFF6C5CE7,
                            ),
                            size: 27,
                          ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(
                                  0.10,
                                ),
                                borderRadius: BorderRadius.circular(
                                  12,
                                ),
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
                                  const SizedBox(
                                    width: 4,
                                  ),
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
                        const SizedBox(
                          height: 6,
                        ),
                        if (description.trim().isNotEmpty)
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(
                          height: 7,
                        ),
                        Row(
                          children: [
                            Text(
                              '${progress.round()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              '  •  ',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$tasksCompleted/$tasksTotal tasks',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              '  •  ',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              daysLeft >= 0
                                  ? '$daysLeft days left'
                                  : '${daysLeft.abs()} days overdue',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  4,
                ),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 5,
                  backgroundColor: const Color(
                    0xFFF1F3F5,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 100
                        ? const Color(
                            0xFF72B968,
                          )
                        : const Color(
                            0xFF5D5FEF,
                          ),
                  ),
                ),
              ),
              if (isAtRisk) ...[
                const SizedBox(
                  height: 9,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: Color(
                        0xFFE88973,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    const Expanded(
                      child: Text(
                        'This project has an overdue or blocked task.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(
                            0xFFE88973,
                          ),
                          fontWeight: FontWeight.w500,
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

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyProjectsState extends StatelessWidget {
  final VoidCallback onAdd;
  final bool hasProjects;

  const _EmptyProjectsState({
    required this.onAdd,
    required this.hasProjects,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF6C5CE7,
                ).withOpacity(
                  0.09,
                ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                color: Color(
                  0xFF6C5CE7,
                ),
                size: 30,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              hasProjects ? 'No Matching Projects' : 'No Projects Yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              hasProjects
                  ? 'Try changing the search or filter.'
                  : 'Create your first project to start managing your work.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (!hasProjects) ...[
              const SizedBox(
                height: 18,
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Create Project',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF5D5FEF,
                  ),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      11,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL ITEM
// ============================================================

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6C5CE7),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.darkCharcoal,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ADD PROJECT DIALOG
// ============================================================

class _AddProjectDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    String? description,
    String? workspaceUrl,
    required int progress,
    required String status,
    DateTime? startDate,
    DateTime? endDate,
    required List<String> memberNames,
    XFile? image,
  }) onCreate;

  const _AddProjectDialog({
    required this.onCreate,
  });

  @override
  State<_AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<_AddProjectDialog> {
  final _nameController = TextEditingController();

  final _descriptionController = TextEditingController();

  final _workspaceLinkController = TextEditingController();

  final _memberController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _startDate;
  DateTime? _endDate;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  final List<String> _members = [];

  String _status = 'On Track';

  double _progress = 0;

  bool _isSubmitting = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _workspaceLinkController.dispose();
    _memberController.dispose();

    super.dispose();
  }

  // ============================================================
  // ADD TEAM MEMBER
  // ============================================================

  void _addMember() {
    final name = _memberController.text.trim();

    if (name.isEmpty) return;

    if (!_members.contains(name)) {
      setState(() {
        _members.add(name);
        _memberController.clear();
      });
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickProjectImage() async {
    if (_isSubmitting) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final fileName = image.name.toLowerCase();

      if (fileName.endsWith('.webp')) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WEBP images are not supported. Please select another image.',
            ),
          ),
        );

        return;
      }

      final bytes = await image.readAsBytes();

      const maxSize = 5 * 1024 * 1024;

      if (bytes.length > maxSize) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image must be 5 MB or smaller.',
            ),
          ),
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = image;

        _selectedImageBytes = Uint8List.fromList(
          bytes,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select image: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void _removeProjectImage() {
    if (_isSubmitting) return;

    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  // ============================================================
  // PICK START DATE
  // ============================================================

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() {
      _startDate = date;
    });

    if (_endDate != null && _endDate!.isBefore(date)) {
      setState(() {
        _endDate = null;
      });
    }
  }

  // ============================================================
  // PICK DUE DATE
  // ============================================================

  Future<void> _pickEndDate() async {
    final initialDate = _startDate ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? initialDate,
      firstDate: initialDate,
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() {
      _endDate = date;
    });
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();

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

    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(
          _startDate!,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Due date cannot be before start date.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onCreate(
        name: name,
        description: _descriptionController.text.trim(),
        workspaceUrl: _workspaceLinkController.text.trim(),
        progress: _progress.round(),
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        memberNames: List<String>.from(
          _members,
        ),
        image: _selectedImage,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Not set';
    }

    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildImageSection() {
    if (_selectedImage == null || _selectedImageBytes == null) {
      return InkWell(
        onTap: _pickProjectImage,
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(
              0xFFF8F9FB,
            ),
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: const Color(
                0xFFE3E6EA,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF6C5CE7,
                  ).withOpacity(
                    0.09,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(
                    0xFF6C5CE7,
                  ),
                  size: 23,
                ),
              ),
              const SizedBox(
                height: 9,
              ),
              const Text(
                'Upload Project Image',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              const Text(
                'JPG, PNG, GIF, BMP, TIFF, HEIC and more • Max 5 MB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            14,
          ),
          child: Image.memory(
            _selectedImageBytes!,
            width: double.infinity,
            height: 145,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (
              _,
              __,
              ___,
            ) {
              return Container(
                width: double.infinity,
                height: 145,
                color: const Color(
                  0xFFF8F9FB,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(
                        0xFF6C5CE7,
                      ),
                      size: 30,
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Preview unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _removeProjectImage,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(
                  7,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD DIALOG
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final screenHeight = MediaQuery.sizeOf(
      context,
    ).height;

    final dialogHeight = (screenHeight * 0.88)
        .clamp(
          360.0,
          720.0,
        )
        .toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: dialogHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: Column(
            children: [
              const Text(
                'Add New Project',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    _buildImageSection(),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller: _nameController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Project Name *',
                        prefixIcon: Icon(
                          Icons.folder_open_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(
                            bottom: 45,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: _workspaceLinkController,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Workspace / Project URL',
                        hintText: 'https://workspace-link.com or GitHub repo',
                        prefixIcon: Icon(
                          Icons.link_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    ListTile(
                      enabled: !_isSubmitting,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(
                          0xFF6C5CE7,
                        ),
                      ),
                      title: const Text(
                        'Start Date',
                      ),
                      subtitle: Text(
                        _formatDate(
                          _startDate,
                        ),
                      ),
                      onTap: _pickStartDate,
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      enabled: !_isSubmitting,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_outlined,
                        color: Color(
                          0xFF6C5CE7,
                        ),
                      ),
                      title: const Text(
                        'Due Date',
                      ),
                      subtitle: Text(
                        _formatDate(
                          _endDate,
                        ),
                      ),
                      onTap: _pickEndDate,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _memberController,
                            enabled: !_isSubmitting,
                            onSubmitted: (_) => _addMember(),
                            decoration: const InputDecoration(
                              labelText: 'Add Team Member Name',
                              prefixIcon: Icon(
                                Icons.person_add_alt_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        IconButton(
                          onPressed: _isSubmitting ? null : _addMember,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(
                              0xFF5D5FEF,
                            ),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    if (_members.isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _members.map(
                          (member) {
                            return Chip(
                              label: Text(
                                member,
                                style: const TextStyle(
                                  fontSize: 11,
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 14,
                              ),
                              onDeleted: _isSubmitting
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _members.remove(
                                            member,
                                          );
                                        },
                                      );
                                    },
                            );
                          },
                        ).toList(),
                      ),
                    ],
                    const SizedBox(
                      height: 16,
                    ),
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.flag_outlined,
                          size: 20,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'On Track',
                          child: Text(
                            'On Track',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'At Risk',
                          child: Text(
                            'At Risk',
                          ),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(
                                () {
                                  _status = value;
                                },
                              );
                            },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        Text(
                          '${_progress.round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(
                              0xFF6C5CE7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _progress,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: const Color(
                        0xFF6C5CE7,
                      ),
                      inactiveColor: const Color(
                        0xFFE8EAF0,
                      ),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(
                                () {
                                  _progress = value;
                                },
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(
                                context,
                              ).pop(),
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF5D5FEF,
                        ),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create',
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
