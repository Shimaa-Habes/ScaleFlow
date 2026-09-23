import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../data/archive_manager.dart';
import '../models/project.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import 'architecture_screen.dart';

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
  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static const String _baseUrl = 'http://localhost:5233/api';

  Project get project => widget.project;

  late String _projectName;
  late String _projectSubtitle;

  File? _selectedImageFile;
  String? _projectImageUrl;

  int _selectedTabIndex = 0;

  final ImagePicker _picker = ImagePicker();
  final TaskService _taskService = TaskService();

  bool _isUpdatingProject = false;
  bool _isDeletingTask = false;

  // ============================================================
  // TASKS
  // ============================================================

  List<Map<String, dynamic>> _tasks = [];

  bool _isLoadingTasks = false;
  bool _isRefreshingTasks = false;
  String? _tasksError;

  // ============================================================
  // FILES
  // Local until backend file endpoints are added.
  // ============================================================

  final List<Map<String, String>> _mockFiles = [
    {
      'name': 'Structural_Blueprint_v2.pdf',
      'size': '14.2 MB',
      'date': '2026-06-10',
      'type': 'pdf',
    },
    {
      'name': 'Budget_Allocation_Q3.xlsx',
      'size': '2.8 MB',
      'date': '2026-06-12',
      'type': 'xls',
    },
  ];

  // ============================================================
  // TEAM
  // Local until backend project-member endpoints are connected.
  // ============================================================

  final List<Map<String, String>> _mockTeam = [
    {
      'name': 'Alexander Wright',
      'role': 'Lead Project Manager',
      'email': 'alex.w@scaleflow.com',
      'avatar': 'AW',
    },
    {
      'name': 'Sophia Martinez',
      'role': 'Senior Architect',
      'email': 'sophia.m@scaleflow.com',
      'avatar': 'SM',
    },
  ];

  @override
  void initState() {
    super.initState();

    _projectName = project.name;
    _projectSubtitle = project.subtitle;

    _projectImageUrl = _normalizeImageUrl(project.imageUrl);

    _loadProjectTasks();
  }

  // ============================================================
  // TASK API
  // ============================================================

  Future<void> _loadProjectTasks() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTasks = true;
      _tasksError = null;
    });

    try {
      final allTasks = await _taskService.getAllTasks();

      final projectTasks = allTasks.where((task) {
        final taskProjectId = _toInt(
          task['_projectId'] ?? task['projectId'],
        );

        return taskProjectId == _projectId;
      }).toList();

      _sortTasksByDueDate(projectTasks);

      if (!mounted) return;

      setState(() {
        _tasks = projectTasks;
        _isLoadingTasks = false;
        _tasksError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTasks = false;
        _tasksError = _cleanErrorMessage(e);
      });
    }
  }

  Future<void> _refreshProjectTasks() async {
    if (_isRefreshingTasks) return;

    setState(() {
      _isRefreshingTasks = true;
      _tasksError = null;
    });

    try {
      final allTasks = await _taskService.getAllTasks();

      final projectTasks = allTasks.where((task) {
        final taskProjectId = _toInt(
          task['_projectId'] ?? task['projectId'],
        );

        return taskProjectId == _projectId;
      }).toList();

      _sortTasksByDueDate(projectTasks);

      if (!mounted) return;

      setState(() {
        _tasks = projectTasks;
        _isRefreshingTasks = false;
        _tasksError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRefreshingTasks = false;
        _tasksError = _cleanErrorMessage(e);
      });
    }
  }

  void _sortTasksByDueDate(List<Map<String, dynamic>> tasks) {
    tasks.sort((a, b) {
      final aDate = _parseDate(a['plannedEnd']);
      final bDate = _parseDate(b['plannedEnd']);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });
  }

  Future<bool> _createTask({
    required String title,
    String? description,
    required int status,
    required int priority,
    required int type,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    double? estimatedHours,
    int? completionPercent,
  }) async {
    try {
      final createdTask = await _taskService.createTask(
        projectId: _projectId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        type: type,
        plannedStart: plannedStart,
        plannedEnd: plannedEnd,
        estimatedHours: estimatedHours,
        completionPercent: completionPercent,
        projectName: _projectName,
      );

      if (!mounted) return false;

      setState(() {
        _tasks.add(createdTask);
        _sortTasksByDueDate(_tasks);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task added successfully!'),
        ),
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add task: ${_cleanErrorMessage(e)}',
          ),
        ),
      );

      return false;
    }
  }

  Future<void> _toggleTaskCompletion(
    Map<String, dynamic> task,
    bool completed,
  ) async {
    final taskId = _toInt(task['id']);

    if (taskId == null) return;

    final oldStatus = _toInt(task['status']) ?? 2;
    final oldCompletionPercent = _toInt(task['completionPercent']) ?? 0;

    try {
      final updatedTask = await _taskService.updateTask(
        projectId: _projectId,
        taskId: taskId,
        title: task['title']?.toString() ?? '',
        description: task['description']?.toString(),
        status: completed ? 5 : 3,
        priority: _toInt(task['priority']) ?? 2,
        type: _toInt(task['type']) ?? 1,
        plannedStart: _parseDate(task['plannedStart']),
        plannedEnd: _parseDate(task['plannedEnd']),
        estimatedHours: _toDouble(task['estimatedHours']),
        completionPercent: completed ? 100 : 0,
        projectName: _projectName,
      );

      if (!mounted) return;

      setState(() {
        final index = _tasks.indexWhere(
          (item) => _toInt(item['id']) == taskId,
        );

        if (index != -1) {
          _tasks[index] = updatedTask;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        final index = _tasks.indexWhere(
          (item) => _toInt(item['id']) == taskId,
        );

        if (index != -1) {
          _tasks[index]['status'] = oldStatus;
          _tasks[index]['completionPercent'] = oldCompletionPercent;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update task: ${_cleanErrorMessage(e)}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteTask(
    Map<String, dynamic> task,
  ) async {
    if (_isDeletingTask) return;

    final taskId = _toInt(task['id']);

    if (taskId == null) {
      _showMessage('This task has no valid ID.');
      return;
    }

    final taskTitle = task['title']?.toString().trim().isNotEmpty == true
        ? task['title'].toString()
        : 'this task';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Delete Task?'),
          content: Text(
            'Are you sure you want to delete "$taskTitle"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeletingTask = true;
    });

    try {
      await _taskService.deleteTask(
        projectId: _projectId,
        taskId: taskId,
      );

      if (!mounted) return;

      setState(() {
        _tasks.removeWhere(
          (item) => _toInt(item['id']) == taskId,
        );
        _isDeletingTask = false;
      });

      _showMessage('Task deleted successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeletingTask = false;
      });

      _showMessage(
        'Failed to delete task: ${_cleanErrorMessage(e)}',
      );
    }
  }

  // ============================================================
  // PROJECT UPDATE API
  // ============================================================

  Future<bool> _updateProject({
    required String name,
    required String description,
  }) async {
    if (_isUpdatingProject) return false;

    setState(() {
      _isUpdatingProject = true;
    });

    try {
      final body = {
        'name': name,
        'description': description.trim().isEmpty ? null : description.trim(),
        'workspaceUrl': project.workspaceUrl,
        'progress': project.progress.clamp(0, 100),
        'isAtRisk': project.isAtRisk,
        'status': _enumToInt(project.status),
        'priority': _enumToInt(project.priority),
        'budget': project.budget,
        'startDate': project.startDate?.toUtc().toIso8601String(),
        'endDate': project.endDate?.toUtc().toIso8601String(),

        // Do not send fake member IDs.
        // The current screen does not have a real project-member
        // synchronization flow yet.
        'memberUserIds': <int>[],
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/Projects/$_projectId'),
        headers: _jsonHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Update project failed: '
          '${response.statusCode} ${response.body}',
        );
      }

      Map<String, dynamic> responseData = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          responseData = decoded;

          final data = decoded['data'];

          if (data is Map<String, dynamic>) {
            final imageUrl = data['imageUrl']?.toString();

            if (imageUrl != null && imageUrl.isNotEmpty) {
              _projectImageUrl = _normalizeImageUrl(imageUrl);
            }
          }
        }
      } catch (_) {}

      if (!mounted) return false;

      setState(() {
        _projectName = name;
        _projectSubtitle = description.trim();
        _isUpdatingProject = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            responseData['message']?.toString() ??
                'Project updated successfully!',
          ),
        ),
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      setState(() {
        _isUpdatingProject = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update project: '
            '${_cleanErrorMessage(e)}',
          ),
        ),
      );

      return false;
    }
  }

  Map<String, String> _jsonHeaders() {
    final token = AuthService.accessToken;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // PROJECT IMAGE API
  // ============================================================

  Future<void> _pickProjectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final file = File(image.path);

      if (!await file.exists()) {
        throw Exception(
          'Selected image could not be found.',
        );
      }

      final fileLength = await file.length();

      if (fileLength > 5 * 1024 * 1024) {
        if (!mounted) return;

        _showMessage(
          'Image is too large. Maximum size is 5 MB.',
        );

        return;
      }

      final token = AuthService.accessToken;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$_baseUrl/Projects/$_projectId/image',
        ),
      );

      request.headers['Accept'] = 'application/json';

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          file.path,
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Image upload failed: '
          '${response.statusCode} ${response.body}',
        );
      }

      String? returnedImageUrl;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          if (data is Map<String, dynamic>) {
            returnedImageUrl = data['imageUrl']?.toString();
          } else if (data is String) {
            returnedImageUrl = data;
          }
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _selectedImageFile = file;

        if (returnedImageUrl != null && returnedImageUrl.isNotEmpty) {
          _projectImageUrl = _normalizeImageUrl(returnedImageUrl);
        }
      });

      _showMessage(
        'Project image uploaded successfully!',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Image upload failed: '
        '${_cleanErrorMessage(e)}',
      );
    }
  }

  // ============================================================
  // ADD TASK DIALOG
  // ============================================================

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final hoursController = TextEditingController();

    String selectedPriority = 'Medium';
    String selectedStatus = 'Todo';
    String selectedType = 'Task';

    DateTime? selectedStartDate;
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogBuildContext,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Add New Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        DropdownMenuItem(
                          value: 'Critical',
                          child: Text('Critical'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Backlog',
                          child: Text('Backlog'),
                        ),
                        DropdownMenuItem(
                          value: 'Todo',
                          child: Text('To Do'),
                        ),
                        DropdownMenuItem(
                          value: 'InProgress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'Review',
                          child: Text('Review'),
                        ),
                        DropdownMenuItem(
                          value: 'Blocked',
                          child: Text('Blocked'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Task Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Task',
                          child: Text('Task'),
                        ),
                        DropdownMenuItem(
                          value: 'Bug',
                          child: Text('Bug'),
                        ),
                        DropdownMenuItem(
                          value: 'Feature',
                          child: Text('Feature'),
                        ),
                        DropdownMenuItem(
                          value: 'Research',
                          child: Text('Research'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: hoursController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Estimated Hours',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: dialogBuildContext,
                                initialDate:
                                    selectedStartDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (date == null) return;

                              setDialogState(() {
                                selectedStartDate = date;
                              });
                            },
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                            ),
                            label: Text(
                              selectedStartDate == null
                                  ? 'Start Date'
                                  : _formatDate(
                                      selectedStartDate!,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: dialogBuildContext,
                                initialDate: selectedDueDate ??
                                    selectedStartDate ??
                                    DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (date == null) return;

                              setDialogState(() {
                                selectedDueDate = date;
                              });
                            },
                            icon: const Icon(
                              Icons.event_outlined,
                              size: 16,
                            ),
                            label: Text(
                              selectedDueDate == null
                                  ? 'Due Date'
                                  : _formatDate(
                                      selectedDueDate!,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      _showMessage(
                        'Please enter a task title.',
                      );
                      return;
                    }

                    if (selectedStartDate != null &&
                        selectedDueDate != null &&
                        selectedDueDate!.isBefore(selectedStartDate!)) {
                      _showMessage(
                        'Due date cannot be before start date.',
                      );
                      return;
                    }

                    final success = await _createTask(
                      title: title,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      status: _statusToInt(
                        selectedStatus,
                      ),
                      priority: _priorityToInt(
                        selectedPriority,
                      ),
                      type: _typeToInt(
                        selectedType,
                      ),
                      plannedStart: selectedStartDate,
                      plannedEnd: selectedDueDate,
                      estimatedHours: double.tryParse(
                        hoursController.text.trim(),
                      ),
                      completionPercent: 0,
                    );

                    if (success && dialogContext.mounted) {
                      Navigator.of(
                        dialogContext,
                      ).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FILES
  // ============================================================

  Future<void> _simulateUploadFile() async {
    try {
      final XFile? file = await _picker.pickMedia();

      if (file == null) return;

      if (!mounted) return;

      setState(() {
        _mockFiles.insert(
          0,
          {
            'name': file.name,
            'size': 'Local',
            'date': DateTime.now().toIso8601String().substring(0, 10),
            'type':
                file.name.contains('.') ? file.name.split('.').last : 'file',
          },
        );
      });

      _showMessage(
        'File "${file.name}" added locally.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'File selection failed: '
        '${_cleanErrorMessage(e)}',
      );
    }
  }

  // ============================================================
  // TEAM
  // ============================================================

  void _showAddTeamMemberDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    String selectedRole = 'Developer';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogBuildContext,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Invite Team Member',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Lead Project Manager',
                        child: Text(
                          'Lead Project Manager',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Senior Architect',
                        child: Text(
                          'Senior Architect',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Site Engineer',
                        child: Text(
                          'Site Engineer',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Developer',
                        child: Text('Developer'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();

                    if (name.isEmpty || email.isEmpty) {
                      _showMessage(
                        'Please enter name and email.',
                      );
                      return;
                    }

                    final initials = name
                        .split(' ')
                        .where(
                          (part) => part.isNotEmpty,
                        )
                        .map(
                          (part) => part[0],
                        )
                        .take(2)
                        .join()
                        .toUpperCase();

                    setState(() {
                      _mockTeam.add(
                        {
                          'name': name,
                          'role': selectedRole,
                          'email': email,
                          'avatar': initials,
                        },
                      );
                    });

                    Navigator.of(
                      dialogContext,
                    ).pop();

                    _showMessage(
                      'Member "$name" added locally.',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Member'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT PROJECT
  // ============================================================

  void _showEditProjectDialog() {
    final nameController = TextEditingController(
      text: _projectName,
    );

    final descriptionController = TextEditingController(
      text: _projectSubtitle,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogBuildContext,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Edit Project',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description / Subtitle',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isUpdatingProject
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isUpdatingProject
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            _showMessage(
                              'Please enter a project name.',
                            );
                            return;
                          }

                          setDialogState(() {});

                          final success = await _updateProject(
                            name: name,
                            description: descriptionController.text.trim(),
                          );

                          if (success && dialogContext.mounted) {
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: _isUpdatingProject
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<void> _confirmArchiveProject() async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Archive Project?',
          ),
          content: const Text(
            'This will remove the project from the local active-project view.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true) return;

    ArchiveManager.archive(project);

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  // ============================================================
  // AI DIAGNOSTIC POPUPS
  // ============================================================

  void _showAiPopup(
    String title,
    String details,
    Color color,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Diagnostic Analysis:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  details,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showBottleneckPopup() {
    _showAiPopup(
      'Bottleneck Detector Analysis',
      'This diagnostic is currently presented as a demo insight. Connect it to the project workload and dependency analysis service for live results.',
      Colors.orange,
      Icons.hourglass_bottom,
    );
  }

  void _showRiskPopup() {
    _showAiPopup(
      'Risk Prediction Analysis',
      'This diagnostic is currently presented as a demo insight. Connect it to the project risk model for live risk prediction.',
      Colors.red,
      Icons.warning_amber_rounded,
    );
  }

  void _showDelayPopup() {
    _showAiPopup(
      'Delay Forecast Analysis',
      'This diagnostic is currently presented as a demo insight. Live forecasting should use task dates, completion rates, dependencies and historical velocity.',
      Colors.green,
      Icons.trending_up,
    );
  }

  void _showHealthPopup() {
    _showAiPopup(
      'Project Health Matrix Analysis',
      'Current project progress is ${project.progress}%. A complete health score should combine progress, overdue tasks, blocked tasks, workload and project risk.',
      const Color(0xFF4F46E5),
      Icons.health_and_safety_outlined,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        bottomNavigationBar: ScaleFlowBottomNav(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pop();
            }
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProjectHeaderImageCard(
                  projectName: _projectName,
                  projectSubtitle: _projectSubtitle,
                  selectedImageFile: _selectedImageFile,
                  imageUrl: _projectImageUrl,
                  onUploadImage: _pickProjectImage,
                  onMenuSelected: (value) {
                    if (value == 'edit') {
                      _showEditProjectDialog();
                    } else if (value == 'upload_image') {
                      _pickProjectImage();
                    } else if (value == 'archive') {
                      _confirmArchiveProject();
                    }
                  },
                ),

                const SizedBox(height: 16),

                _ProjectTabsRow(
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });

                    if (index == 1 && _tasks.isEmpty) {
                      _loadProjectTasks();
                    }
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // OVERVIEW
                // ==================================================

                if (_selectedTabIndex == 0) ...[
                  const Text(
                    'Project Summary & Health',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProjectDescriptionAndHealthCard(
                    projectName: _projectName,
                    projectSubtitle: _projectSubtitle,
                    progress: project.progress,
                    ownerId: project.ownerId,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Project Architecture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AiDiagnosticCard(
                    title: 'System Architecture View',
                    subtitle:
                        'Tap to inspect system architecture, layers & components',
                    status: 'View Map',
                    statusColor: const Color(0xFF4F46E5),
                    icon: Icons.account_tree_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ArchitecturePage(
                            projectId: _projectId,
                            projectName: _projectName,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'AI Diagnostic Modules',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AiDiagnosticCard(
                    title: 'Bottleneck Detector',
                    subtitle:
                        'Review resource congestion and task dependencies',
                    status: 'Demo',
                    statusColor: Colors.orange,
                    icon: Icons.hourglass_bottom,
                    onTap: _showBottleneckPopup,
                  ),
                  const SizedBox(height: 10),
                  _AiDiagnosticCard(
                    title: 'Risk Prediction Model',
                    subtitle: 'Review project risk indicators',
                    status: project.isAtRisk ? 'At Risk' : 'Demo',
                    statusColor: project.isAtRisk ? Colors.red : Colors.orange,
                    icon: Icons.warning_amber_rounded,
                    onTap: _showRiskPopup,
                  ),
                  const SizedBox(height: 10),
                  _AiDiagnosticCard(
                    title: 'Delay Forecast Engine',
                    subtitle: 'Review task dates and completion trends',
                    status: 'Demo',
                    statusColor: Colors.green,
                    icon: Icons.trending_up,
                    onTap: _showDelayPopup,
                  ),
                  const SizedBox(height: 10),
                  _AiDiagnosticCard(
                    title: 'Project Health Matrix',
                    subtitle: 'Current project progress and risk overview',
                    status: '${project.progress}%',
                    statusColor: const Color(0xFF4F46E5),
                    icon: Icons.health_and_safety_outlined,
                    onTap: _showHealthPopup,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _KeyMetricsRow(
                    budget: project.budget,
                    progress: project.progress,
                    tasksCount: _tasks.length,
                  ),
                ]

                // ==================================================
                // TASKS
                // ==================================================

                else if (_selectedTabIndex == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Project Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTaskDialog,
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                        ),
                        label: const Text('Add Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF4F46E5,
                          ),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingTasks)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 40,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    )
                  else if (_tasksError != null)
                    _TaskErrorCard(
                      message: _tasksError!,
                      onRetry: _loadProjectTasks,
                    )
                  else if (_tasks.isEmpty)
                    _EmptyTasksCard(
                      onAddTask: _showAddTaskDialog,
                    )
                  else
                    RefreshIndicator(
                      onRefresh: _refreshProjectTasks,
                      color: const Color(
                        0xFF4F46E5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(
                            _tasks[index],
                          );
                        },
                      ),
                    ),
                  if (_isRefreshingTasks)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                ]

                // ==================================================
                // FILES
                // ==================================================

                else if (_selectedTabIndex == 2) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Project Files',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _simulateUploadFile,
                        icon: const Icon(
                          Icons.upload_file,
                          size: 16,
                        ),
                        label: const Text(
                          'Upload File',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF4F46E5,
                          ),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mockFiles.length,
                    itemBuilder: (context, index) {
                      final file = _mockFiles[index];

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.03,
                              ),
                              blurRadius: 4,
                              offset: const Offset(
                                0,
                                2,
                              ),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: Color(0xFF4F46E5),
                              size: 28,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    '${file['size'] ?? ''} • ${file['date'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.download,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _showMessage(
                                  'File opening is local/demo only.',
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]

                // ==================================================
                // TEAM
                // ==================================================

                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Team Members',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTeamMemberDialog,
                        icon: const Icon(
                          Icons.person_add,
                          size: 16,
                        ),
                        label: const Text(
                          'Add Member',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF4F46E5,
                          ),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mockTeam.length,
                    itemBuilder: (context, index) {
                      final member = _mockTeam[index];

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.03,
                              ),
                              blurRadius: 4,
                              offset: const Offset(
                                0,
                                2,
                              ),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(
                                0xFF4F46E5,
                              ).withOpacity(0.1),
                              foregroundColor: const Color(
                                0xFF4F46E5,
                              ),
                              child: Text(
                                member['avatar'] ?? 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    member['role'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(
                                        0xFF4F46E5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    member['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(
                                  6,
                                ),
                              ),
                              child: const Text(
                                'Local',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _buildTaskCard(
    Map<String, dynamic> task,
  ) {
    final taskId = _toInt(task['id']);

    final status = _toInt(task['status']) ?? 2;
    final priority = _toInt(task['priority']) ?? 2;

    final completed = status == 5;

    final title = task['title']?.toString() ?? 'Untitled Task';

    final description = task['description']?.toString().trim() ?? '';

    final dueDate = _parseDate(task['plannedEnd']);

    final estimatedHours = _toDouble(task['estimatedHours']);

    final statusLabel = _statusLabel(status);

    final priorityLabel = _priorityLabel(priority);

    final priorityColor = _priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: completed,
                activeColor: const Color(0xFF4F46E5),
                onChanged: taskId == null
                    ? null
                    : (value) {
                        _toggleTaskCompletion(
                          task,
                          value ?? false,
                        );
                      },
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed
                        ? Colors.grey
                        : const Color(
                            0xFF1E293B,
                          ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteTask(task);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 40,
              ),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(
              left: 40,
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TaskInfoChip(
                  icon: Icons.flag_outlined,
                  label: statusLabel,
                ),
                if (dueDate != null)
                  _TaskInfoChip(
                    icon: Icons.event_outlined,
                    label: _formatDate(dueDate),
                  ),
                if (estimatedHours != null)
                  _TaskInfoChip(
                    icon: Icons.schedule_outlined,
                    label: '${_formatNumber(estimatedHours)}h',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int get _projectId {
    return int.tryParse(project.id) ?? 0;
  }

  int _enumToInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    final text = value?.toString().toLowerCase() ?? '';

    if (text.contains('draft')) return 0;
    if (text.contains('planning')) return 1;
    if (text.contains('active')) return 2;
    if (text.contains('onhold')) return 3;
    if (text.contains('completed')) return 4;
    if (text.contains('cancelled')) return 5;
    if (text.contains('archived')) return 6;

    if (text.contains('low')) return 1;
    if (text.contains('medium')) return 2;
    if (text.contains('high')) return 3;
    if (text.contains('critical')) return 4;

    return 2;
  }

  int _statusToInt(String status) {
    switch (status) {
      case 'Backlog':
        return 1;
      case 'Todo':
        return 2;
      case 'InProgress':
        return 3;
      case 'Review':
        return 4;
      case 'Done':
        return 5;
      case 'Blocked':
        return 6;
      case 'Cancelled':
        return 7;
      default:
        return 2;
    }
  }

  int _priorityToInt(
    String priority,
  ) {
    switch (priority) {
      case 'Low':
        return 1;
      case 'Medium':
        return 2;
      case 'High':
        return 3;
      case 'Critical':
        return 4;
      default:
        return 2;
    }
  }

  int _typeToInt(String type) {
    switch (type) {
      case 'Task':
        return 1;
      case 'Bug':
        return 2;
      case 'Feature':
        return 3;
      case 'Research':
        return 4;
      default:
        return 1;
    }
  }

  String _statusLabel(int status) {
    switch (status) {
      case 1:
        return 'Backlog';
      case 2:
        return 'To Do';
      case 3:
        return 'In Progress';
      case 4:
        return 'Review';
      case 5:
        return 'Done';
      case 6:
        return 'Blocked';
      case 7:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _priorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      case 4:
        return 'Critical';
      default:
        return 'Medium';
    }
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final stringValue = value.toString().trim();

    if (stringValue.isEmpty) return null;

    return DateTime.tryParse(
      stringValue,
    )?.toLocal();
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatBudget(decimalValue) {
    if (decimalValue == null) {
      return '—';
    }

    final value = _toDouble(decimalValue);

    if (value == null) {
      return '—';
    }

    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }

    return '\$${value.toStringAsFixed(0)}';
  }

  String? _normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final value = url.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return 'http://localhost:5233$value';
    }

    return 'http://localhost:5233/$value';
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ================================================================
// HEADER
// ================================================================

class _ProjectHeaderImageCard extends StatelessWidget {
  final String projectName;
  final String projectSubtitle;
  final File? selectedImageFile;
  final String? imageUrl;
  final VoidCallback onUploadImage;
  final ValueChanged<String> onMenuSelected;

  const _ProjectHeaderImageCard({
    required this.projectName,
    required this.projectSubtitle,
    required this.selectedImageFile,
    required this.imageUrl,
    required this.onUploadImage,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    const defaultImageUrl =
        'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b3?auto=format&fit=crop&w=1000&q=80';

    Widget image;

    if (selectedImageFile != null) {
      image = Image.file(
        selectedImageFile!,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null) {
      image = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackImage();
        },
      );
    } else {
      image = Image.network(
        defaultImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackImage();
        },
      );
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: image,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.30),
                      Colors.transparent,
                      Colors.black.withOpacity(0.70),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 18,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF1E293B),
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(
                          0.9,
                        ),
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: Color(
                              0xFF1E293B,
                            ),
                          ),
                          onPressed: onUploadImage,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(
                          0.9,
                        ),
                        radius: 18,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: onMenuSelected,
                          icon: const Icon(
                            Icons.more_horiz,
                            size: 20,
                            color: Color(
                              0xFF1E293B,
                            ),
                          ),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'upload_image',
                              child: Text(
                                'Upload Image',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                'Edit Details',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Text(
                                'Archive',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    projectSubtitle.isEmpty
                        ? 'No description'
                        : projectSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
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

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFCBD5E1),
      child: const Center(
        child: Icon(
          Icons.apartment,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ================================================================
// TABS
// ================================================================

class _ProjectTabsRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _ProjectTabsRow({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Overview',
      'Tasks',
      'Files',
      'Team',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        tabs.length,
        (index) {
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(
                            0xFF4F46E5,
                          )
                        : const Color(
                            0xFF94A3B8,
                          ),
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Container(
                  height: 3,
                  width: isSelected ? 32 : 0,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF4F46E5,
                    ),
                    borderRadius: BorderRadius.circular(
                      2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================================================================
// PROJECT HEALTH
// ================================================================

class _ProjectDescriptionAndHealthCard extends StatelessWidget {
  final String projectName;
  final String projectSubtitle;
  final int progress;
  final int ownerId;

  const _ProjectDescriptionAndHealthCard({
    required this.projectName,
    required this.projectSubtitle,
    required this.progress,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1.5,
                  child: CircularProgressIndicator(
                    value: safeProgress / 100,
                    strokeWidth: 5,
                    backgroundColor: const Color(
                      0xFFE2E8F0,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(
                        0xFF3E8746,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$safeProgress%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(
                          0xFF1E293B,
                        ),
                        height: 1,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectSubtitle.isEmpty ? 'No description' : projectSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    const Text(
                      'Owner ID: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ownerId.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(
                            0xFF4F46E5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// AI CARD
// ================================================================

class _AiDiagnosticCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;
  final VoidCallback onTap;

  const _AiDiagnosticCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.02,
              ),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                icon,
                color: statusColor,
                size: 22,
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(
                              0xFF1E293B,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            4,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// TASK INFO CHIP
// ================================================================

class _TaskInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TaskInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF666A70),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666A70),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// EMPTY TASKS
// ================================================================

class _EmptyTasksCard extends StatelessWidget {
  final VoidCallback onAddTask;

  const _EmptyTasksCard({
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_outlined,
            size: 42,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          const Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Create the first task for this project.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onAddTask,
            icon: const Icon(
              Icons.add,
              size: 16,
            ),
            label: const Text('Add Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF4F46E5,
              ),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// TASK ERROR
// ================================================================

class _TaskErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TaskErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 38,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          const Text(
            'Could not load project tasks',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh,
              size: 16,
            ),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// KEY METRICS
// ================================================================

class _KeyMetricsRow extends StatelessWidget {
  final dynamic budget;
  final int progress;
  final int tasksCount;

  const _KeyMetricsRow({
    required this.budget,
    required this.progress,
    required this.tasksCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Budget',
            value: _formatBudgetValue(
              budget,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'Progress',
            value: '$progress%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'Tasks',
            value: tasksCount.toString(),
          ),
        ),
      ],
    );
  }

  String _formatBudgetValue(
    dynamic value,
  ) {
    if (value == null) return '—';

    double? number;

    if (value is num) {
      number = value.toDouble();
    } else {
      number = double.tryParse(value.toString());
    }

    if (number == null) return '—';

    if (number >= 1000000) {
      return '\$${(number / 1000000).toStringAsFixed(1)}M';
    }

    if (number >= 1000) {
      return '\$${(number / 1000).toStringAsFixed(1)}K';
    }

    return '\$${number.toStringAsFixed(0)}';
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.02,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
