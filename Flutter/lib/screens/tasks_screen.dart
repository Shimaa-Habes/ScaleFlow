import 'package:flutter/material.dart';

import '../services/task_service.dart';

// ============================================================
// SCALEFLOW COLORS & CONSTANTS
// ============================================================

const Color _charcoal = Color(0xFF2C2D30);
const Color _softText = Color(0xFF666A70);
const Color _mutedText = Color(0xFF858990);
const Color _pageBackground = Color(0xFFF7F6FB);
const Color _purple = Color(0xFF6C5CE7);

// Backend TaskStatus enum
const int _statusBacklog = 1;
const int _statusTodo = 2;
const int _statusInProgress = 3;
const int _statusReview = 4;
const int _statusDone = 5;
const int _statusBlocked = 6;
const int _statusCancelled = 7;

// Backend TaskPriority enum
const int _priorityLow = 1;
const int _priorityMedium = 2;
const int _priorityHigh = 3;
const int _priorityCritical = 4;

// ============================================================
// TASK MODEL
// ============================================================

class TaskModel {
  final int id;
  final int projectId;

  String title;
  String subtitle;
  String time;
  String priority;
  String status;

  DateTime? startDate;
  DateTime? dueDate;

  bool isCompleted;

  String? description;
  int type;
  double? estimatedHours;
  int? completionPercent;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.priority,
    required this.status,
    this.startDate,
    this.dueDate,
    this.isCompleted = false,
    this.description,
    this.type = 1,
    this.estimatedHours,
    this.completionPercent,
  });

  factory TaskModel.fromApi(Map<String, dynamic> task) {
    final status = _toInt(task['status']) ?? _statusBacklog;

    final plannedStart = _parseDate(task['plannedStart']);
    final plannedEnd = _parseDate(task['plannedEnd']);

    return TaskModel(
      id: _toInt(task['id']) ?? 0,
      projectId: _toInt(task['_projectId']) ?? 0,
      title: task['title']?.toString() ?? 'Untitled Task',
      subtitle: task['_projectName']?.toString() ?? 'Unknown Project',
      time: _formatTaskTime(plannedStart, plannedEnd),
      priority: _priorityToLabel(
        _toInt(task['priority']) ?? _priorityMedium,
      ),
      status: _statusToLabel(status),
      startDate: plannedStart,
      dueDate: plannedEnd,
      isCompleted: status == _statusDone,
      description: task['description']?.toString(),
      type: _toInt(task['type']) ?? 1,
      estimatedHours: _toDouble(task['estimatedHours']),
      completionPercent: _toInt(task['completionPercent']),
    );
  }

  Map<String, dynamic> toUpdateData() {
    return {
      'title': title,
      'description': description,
      'status': _statusFromLabel(status),
      'priority': _priorityFromLabel(priority),
      'type': type,
      'plannedStart': startDate?.toUtc().toIso8601String(),
      'plannedEnd': dueDate?.toUtc().toIso8601String(),
      'estimatedHours': estimatedHours,
      'completionPercent': completionPercent,
    };
  }
}

// ============================================================
// TASKS SCREEN
// ============================================================

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedTab = 'All';

  List<TaskModel> _tasks = [];

  // ============================================================
  // IMPORTANT:
  // Projects are loaded separately from Tasks.
  //
  // This means a project with ZERO tasks will still appear
  // inside the Add Task -> Project dropdown.
  // ============================================================

  List<Map<String, dynamic>> _projects = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PROJECTS + TASKS
  // ============================================================

  Future<void> _loadTasks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Load projects independently.
      //
      // This is the important fix:
      // getProjects() returns projects even if they have no tasks.
      final projects = await _taskService.getProjects();

      // Load all tasks.
      final response = await _taskService.getAllTasks();

      final loadedTasks = response
          .map((task) => TaskModel.fromApi(task))
          .where((task) => task.id != 0)
          .toList();

      loadedTasks.sort(_compareTasks);

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _tasks = loadedTasks;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  // ============================================================
  // REFRESH PROJECTS + TASKS
  // ============================================================

  Future<void> _refreshTasks() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final projects = await _taskService.getProjects();
      final response = await _taskService.getAllTasks();

      final loadedTasks = response
          .map((task) => TaskModel.fromApi(task))
          .where((task) => task.id != 0)
          .toList();

      loadedTasks.sort(_compareTasks);

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _tasks = loadedTasks;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<TaskModel> get _filteredTasks {
    final query = _searchQuery.trim().toLowerCase();

    return _tasks.where((task) {
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.subtitle.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      switch (_selectedTab) {
        case 'To Do':
          return task.status == 'To Do';

        case 'In Progress':
          return task.status == 'In Progress';

        case 'Done':
          return task.status == 'Done';

        case 'All':
        default:
          return true;
      }
    }).toList();
  }

  // ============================================================
  // PROJECTS AVAILABLE FOR ADD TASK
  // ============================================================

  Map<int, String> get _availableProjects {
    final projects = <int, String>{};

    // IMPORTANT:
    // We use _projects instead of _tasks.
    //
    // Therefore:
    // Project A -> 5 tasks -> appears
    // Project B -> 0 tasks -> ALSO appears
    // Project C -> 2 tasks -> appears

    for (final project in _projects) {
      final projectId = _toInt(project['id']);

      if (projectId == null || projectId <= 0) {
        continue;
      }

      final projectName = project['name']?.toString().trim() ?? '';

      if (projectName.isNotEmpty) {
        projects[projectId] = projectName;
      }
    }

    return projects;
  }

  // ============================================================
  // ADD TASK
  // ============================================================

  Future<void> _showAddTaskDialog() async {
    if (_availableProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No available projects found. Create a project first.',
          ),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final projectEntries = _availableProjects.entries.toList();

    int selectedProjectId = projectEntries.first.key;

    String selectedPriority = 'Medium';
    String selectedStatus = 'To Do';

    DateTime startDate = DateTime.now();

    DateTime dueDate = DateTime.now().add(
      const Duration(days: 1),
    );

    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> saveTask() async {
              final title = titleController.text.trim();

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

              if (dueDate.isBefore(startDate)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Due date cannot be before the start date.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                final projectName =
                    _availableProjects[selectedProjectId] ?? 'Unknown Project';

                final createdTask = await _taskService.createTask(
                  projectId: selectedProjectId,
                  title: title,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  status: _statusFromLabel(
                    selectedStatus,
                  ),
                  priority: _priorityFromLabel(
                    selectedPriority,
                  ),
                  type: 1,
                  plannedStart: startDate,
                  plannedEnd: dueDate,
                  completionPercent: selectedStatus == 'Done' ? 100 : 0,
                  projectName: projectName,
                );

                // Make sure the created task has the project
                // information needed by the UI.
                createdTask['_projectId'] = selectedProjectId;

                createdTask['_projectName'] = projectName;

                final newTask = TaskModel.fromApi(createdTask);

                if (!mounted) return;

                setState(() {
                  _tasks.add(newTask);
                  _tasks.sort(_compareTasks);
                });

                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Task added successfully!',
                    ),
                  ),
                );
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                });

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to add task: '
                      '${_cleanErrorMessage(e)}',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add New Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _charcoal,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // TITLE
                    // ==================================================

                    TextField(
                      controller: titleController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PROJECT
                    // ==================================================

                    DropdownButtonFormField<int>(
                      value: selectedProjectId,
                      decoration: InputDecoration(
                        labelText: 'Project',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: projectEntries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setDialogState(() {
                                selectedProjectId = value;
                              });
                            },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    TextField(
                      controller: descriptionController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PRIORITY + STATUS
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              'Low',
                              'Medium',
                              'High',
                              'Critical',
                            ].map((priority) {
                              return DropdownMenuItem<String>(
                                value: priority,
                                child: Text(priority),
                              );
                            }).toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setDialogState(() {
                                      selectedPriority = value;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              'To Do',
                              'In Progress',
                              'Done',
                              'Blocked',
                            ].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setDialogState(() {
                                      selectedStatus = value;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // START DATE
                    // ==================================================

                    ListTile(
                      enabled: !isSaving,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade400,
                        ),
                      ),
                      title: Text(
                        'Start Date: '
                        '${_formatDate(startDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _charcoal,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: _purple,
                      ),
                      onTap: isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: startDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2035),
                              );

                              if (picked != null) {
                                setDialogState(() {
                                  startDate = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    startDate.hour,
                                    startDate.minute,
                                  );

                                  if (dueDate.isBefore(
                                    startDate,
                                  )) {
                                    dueDate = startDate.add(
                                      const Duration(
                                        hours: 1,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // DUE DATE
                    // ==================================================

                    ListTile(
                      enabled: !isSaving,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade400,
                        ),
                      ),
                      title: Text(
                        'Due Date: '
                        '${_formatDate(dueDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _charcoal,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.event_available,
                        size: 18,
                        color: _purple,
                      ),
                      onTap: isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: dueDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2035),
                              );

                              if (picked != null) {
                                setDialogState(() {
                                  dueDate = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    dueDate.hour,
                                    dueDate.minute,
                                  );

                                  if (dueDate.isBefore(
                                    startDate,
                                  )) {
                                    startDate = dueDate.subtract(
                                      const Duration(
                                        hours: 1,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(
                            dialogContext,
                          ).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSaving ? null : saveTask,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  // ============================================================
  // UPDATE TASK STATUS
  // ============================================================

  Future<void> _toggleTaskCompletion(
    TaskModel task,
    bool completed,
  ) async {
    final oldStatus = task.status;
    final oldCompletion = task.completionPercent;

    final newStatus = completed ? 'Done' : 'In Progress';

    setState(() {
      task.isCompleted = completed;
      task.status = newStatus;
      task.completionPercent = completed ? 100 : 0;
    });

    try {
      final updated = await _taskService.updateTask(
        projectId: task.projectId,
        taskId: task.id,
        title: task.title,
        description: task.description,
        status: _statusFromLabel(newStatus),
        priority: _priorityFromLabel(
          task.priority,
        ),
        type: task.type,
        plannedStart: task.startDate,
        plannedEnd: task.dueDate,
        estimatedHours: task.estimatedHours,
        completionPercent: completed ? 100 : 0,
        projectName: task.subtitle,
      );

      final updatedTask = TaskModel.fromApi({
        ...updated,
        '_projectId': task.projectId,
        '_projectName': task.subtitle,
      });

      if (!mounted) return;

      setState(() {
        final index = _tasks.indexWhere(
          (item) => item.id == task.id,
        );

        if (index != -1) {
          _tasks[index] = updatedTask;
        }

        _tasks.sort(_compareTasks);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed ? 'Task marked as Done.' : 'Task moved to In Progress.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        task.status = oldStatus;
        task.isCompleted = oldStatus == 'Done';
        task.completionPercent = oldCompletion;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update task: '
            '${_cleanErrorMessage(e)}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildSearch(),
            const SizedBox(height: 14),
            _buildTabs(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildTaskContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: _charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _charcoal,
                ),
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _purple,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleCalendarScreen(
                        tasks: List<TaskModel>.from(
                          _tasks,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.calendar_month,
                  size: 16,
                ),
                label: const Text(
                  'Calendar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isLoading ? null : _showAddTaskDialog,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? _purple.withOpacity(
                            0.5,
                          )
                        : _purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
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
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
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
                  hintText: 'Search tasks...',
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
              GestureDetector(
                onTap: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: _mutedText,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        children: [
          'All',
          'To Do',
          'In Progress',
          'Done',
        ].map((tab) {
          final isSelected = _selectedTab == tab;

          return Padding(
            padding: const EdgeInsets.only(
              right: 8,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _purple : Colors.white,
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                  boxShadow: isSelected
                      ? []
                      : const [
                          BoxShadow(
                            color: Color(
                              0x08000000,
                            ),
                            blurRadius: 4,
                          ),
                        ],
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _softText,
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
  // TASK CONTENT
  // ============================================================

  Widget _buildTaskContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _purple,
        ),
      );
    }

    if (_errorMessage != null && _tasks.isEmpty) {
      return _buildErrorState();
    }

    final tasks = _filteredTasks;

    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _purple,
      onRefresh: _refreshTasks,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _charcoal,
                ),
              ),
              if (_isRefreshing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _purple,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...tasks.map(
            _buildTaskCard,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: _mutedText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.trim().isNotEmpty || _selectedTab != 'All';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt,
                color: _purple,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters ? 'No matching tasks' : 'No tasks yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try changing your search or filter.'
                  : 'Create your first task to get started.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: _mutedText,
              ),
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text('Add Task'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _buildTaskCard(
    TaskModel task,
  ) {
    final priorityColor = _priorityColor(
      task.priority,
    );

    final statusColor = _statusColor(
      task.status,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: const Icon(
              Icons.task_alt,
              color: _purple,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 12,
                      color: _softText,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Text(
                        task.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _softText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(
                      6,
                    ),
                  ),
                  child: Text(
                    task.status,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(
                    6,
                  ),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Checkbox(
                value: task.isCompleted,
                activeColor: _purple,
                visualDensity: VisualDensity.compact,
                onChanged: task.status == 'Cancelled'
                    ? null
                    : (value) {
                        _toggleTaskCompletion(
                          task,
                          value ?? false,
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCHEDULE / CALENDAR SCREEN
// ============================================================

class ScheduleCalendarScreen extends StatefulWidget {
  final List<TaskModel> tasks;

  const ScheduleCalendarScreen({
    super.key,
    required this.tasks,
  });

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  bool _isTimelineView = true;

  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _displayedMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  // ============================================================
  // CALENDAR HELPERS
  // ============================================================

  List<TaskModel> get _selectedDayTasks {
    return widget.tasks.where((task) {
      final date = task.startDate ?? task.dueDate;

      if (date == null) {
        return false;
      }

      return _sameDay(
        date,
        _selectedDate,
      );
    }).toList()
      ..sort(_compareTasks);
  }

  List<TaskModel> get _monthTasks {
    return widget.tasks.where((task) {
      final date = task.startDate ?? task.dueDate;

      if (date == null) {
        return false;
      }

      return date.year == _displayedMonth.year &&
          date.month == _displayedMonth.month;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isTimelineView
                  ? _buildTimelineView()
                  : _buildColorCalendarView(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(
                    context,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: _charcoal,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const Flexible(
                  child: Text(
                    'Schedule & Calendar',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              _isTimelineView,
              !_isTimelineView,
            ],
            onPressed: (index) {
              setState(() {
                _isTimelineView = index == 0;
              });
            },
            borderRadius: BorderRadius.circular(
              12,
            ),
            selectedColor: Colors.white,
            fillColor: _purple,
            color: _charcoal,
            constraints: const BoxConstraints(
              minHeight: 32,
              minWidth: 45,
            ),
            children: const [
              Icon(
                Icons.view_agenda_outlined,
                size: 18,
              ),
              Icon(
                Icons.calendar_month_outlined,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMELINE VIEW
  // ============================================================

  Widget _buildTimelineView() {
    final hours = List.generate(
      12,
      (index) => index + 8,
    );

    return RefreshIndicator(
      color: _purple,
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        children: [
          _buildTimelineDateHeader(),
          const SizedBox(height: 12),
          if (_selectedDayTasks.isEmpty)
            _buildCalendarEmptyState(
              'No scheduled tasks',
              'There are no tasks scheduled for this day.',
            )
          else
            ...hours.map(
              (hour) => _buildTimelineHour(
                hour,
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineDateHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Text(
              '${_selectedDate.day}',
              style: const TextStyle(
                color: _purple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatFullDate(
                  _selectedDate,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _charcoal,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_selectedDayTasks.length} scheduled task${_selectedDayTasks.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHour(
    int hour,
  ) {
    final tasks = _selectedDayTasks.where(
      (task) {
        final date = task.startDate ?? task.dueDate;

        if (date == null) {
          return false;
        }

        return date.hour == hour;
      },
    ).toList();

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 55,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ),
              child: Text(
                _formatHour(hour),
                style: const TextStyle(
                  fontSize: 12,
                  color: _mutedText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: tasks
                        .map(
                          (task) => _buildTimelineTaskCard(
                            task,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTaskCard(
    TaskModel task,
  ) {
    final statusColor = _statusColor(
      task.status,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _charcoal,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            task.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _softText,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                task.time,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: _softText,
                ),
              ),
              const SizedBox(width: 8),
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
                    5,
                  ),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
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
  // COLOR CALENDAR
  // ============================================================

  Widget _buildColorCalendarView() {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              20,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMonthNavigation(),
              const SizedBox(
                height: 14,
              ),
              _buildWeekDays(),
              const SizedBox(
                height: 8,
              ),
              _buildCalendarGrid(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _sameDay(
            _selectedDate,
            DateTime.now(),
          )
              ? "Today's Scheduled Tasks"
              : 'Scheduled Tasks',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: _charcoal,
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedDayTasks.isEmpty)
          _buildCalendarEmptyState(
            'No tasks on this date',
            'Select another date or schedule a task for this day.',
          )
        else
          ..._selectedDayTasks.map(
            _buildCalendarTaskCard,
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // MONTH NAVIGATION
  // ============================================================

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _displayedMonth = DateTime(
                _displayedMonth.year,
                _displayedMonth.month - 1,
                1,
              );
            });
          },
          icon: const Icon(
            Icons.chevron_left,
            color: _charcoal,
          ),
        ),
        Text(
          _formatMonthYear(
            _displayedMonth,
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _charcoal,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _displayedMonth = DateTime(
                _displayedMonth.year,
                _displayedMonth.month + 1,
                1,
              );
            });
          },
          icon: const Icon(
            Icons.chevron_right,
            color: _charcoal,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WEEK DAYS
  // ============================================================

  Widget _buildWeekDays() {
    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Row(
      children: days.map(
        (day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _mutedText,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // CALENDAR GRID
  // ============================================================

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;

    // Monday = 1 ... Sunday = 7
    final leadingEmptyDays = firstDay.weekday - 1;

    final totalCells = ((leadingEmptyDays + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < leadingEmptyDays) {
          return const SizedBox.shrink();
        }

        final day = index - leadingEmptyDays + 1;

        if (day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          day,
        );

        final isToday = _sameDay(
          date,
          DateTime.now(),
        );

        final isSelected = _sameDay(
          date,
          _selectedDate,
        );

        final taskCount = _tasksForDate(
          date,
        ).length;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? _purple
                  : isToday
                      ? _purple.withOpacity(
                          0.12,
                        )
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                8,
              ),
              border: isToday && !isSelected
                  ? Border.all(
                      color: _purple,
                      width: 1,
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : _charcoal,
                  ),
                ),
                if (taskCount > 0)
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : _purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CALENDAR TASK CARD
  // ============================================================

  Widget _buildCalendarTaskCard(
    TaskModel task,
  ) {
    final statusColor = _statusColor(
      task.status,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.time,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _charcoal,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            task.subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: _softText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(
                    5,
                  ),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                task.priority,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: _priorityColor(
                    task.priority,
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
  // CALENDAR EMPTY STATE
  // ============================================================

  Widget _buildCalendarEmptyState(
    String title,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            color: _mutedText,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TASKS FOR DATE
  // ============================================================

  List<TaskModel> _tasksForDate(
    DateTime date,
  ) {
    final result = widget.tasks.where(
      (task) {
        final start = task.startDate;
        final end = task.dueDate;

        if (start == null && end == null) {
          return false;
        }

        if (start != null &&
            _sameDay(
              start,
              date,
            )) {
          return true;
        }

        if (end != null &&
            _sameDay(
              end,
              date,
            )) {
          return true;
        }

        if (start != null &&
            end != null &&
            date.isAfter(
              DateTime(
                start.year,
                start.month,
                start.day,
              ),
            ) &&
            date.isBefore(
              DateTime(
                end.year,
                end.month,
                end.day,
              ),
            )) {
          return true;
        }

        return false;
      },
    ).toList();

    result.sort(_compareTasks);

    return result;
  }
}

// ============================================================
// GLOBAL HELPERS
// ============================================================

String _statusToLabel(
  int status,
) {
  switch (status) {
    case _statusTodo:
      return 'To Do';

    case _statusInProgress:
      return 'In Progress';

    case _statusReview:
      return 'Review';

    case _statusDone:
      return 'Done';

    case _statusBlocked:
      return 'Blocked';

    case _statusCancelled:
      return 'Cancelled';

    case _statusBacklog:
    default:
      return 'Backlog';
  }
}

int _statusFromLabel(
  String status,
) {
  switch (status) {
    case 'To Do':
      return _statusTodo;

    case 'In Progress':
      return _statusInProgress;

    case 'Review':
      return _statusReview;

    case 'Done':
      return _statusDone;

    case 'Blocked':
      return _statusBlocked;

    case 'Cancelled':
      return _statusCancelled;

    case 'Backlog':
    default:
      return _statusBacklog;
  }
}

String _priorityToLabel(
  int priority,
) {
  switch (priority) {
    case _priorityLow:
      return 'Low';

    case _priorityHigh:
      return 'High';

    case _priorityCritical:
      return 'Critical';

    case _priorityMedium:
    default:
      return 'Medium';
  }
}

int _priorityFromLabel(
  String priority,
) {
  switch (priority) {
    case 'Low':
      return _priorityLow;

    case 'High':
      return _priorityHigh;

    case 'Critical':
      return _priorityCritical;

    case 'Medium':
    default:
      return _priorityMedium;
  }
}

Color _priorityColor(
  String priority,
) {
  switch (priority) {
    case 'Low':
      return Colors.green;

    case 'Medium':
      return Colors.orange;

    case 'High':
      return Colors.red;

    case 'Critical':
      return Colors.deepPurple;

    default:
      return Colors.grey;
  }
}

Color _statusColor(
  String status,
) {
  switch (status) {
    case 'Done':
      return Colors.green;

    case 'In Progress':
      return _purple;

    case 'To Do':
      return Colors.blue;

    case 'Review':
      return Colors.orange;

    case 'Blocked':
      return Colors.red;

    case 'Cancelled':
      return Colors.grey;

    case 'Backlog':
    default:
      return _mutedText;
  }
}

DateTime? _parseDate(
  dynamic value,
) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value.toLocal();
  }

  return DateTime.tryParse(
    value.toString(),
  )?.toLocal();
}

int? _toInt(
  dynamic value,
) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value?.toString() ?? '',
  );
}

double? _toDouble(
  dynamic value,
) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  );
}

String _formatDate(
  DateTime date,
) {
  final day = date.day.toString().padLeft(
        2,
        '0',
      );

  final month = date.month.toString().padLeft(
        2,
        '0',
      );

  return '$day/$month/${date.year}';
}

String _formatFullDate(
  DateTime date,
) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${weekdays[date.weekday - 1]}, '
      '${months[date.month - 1]} '
      '${date.day}, ${date.year}';
}

String _formatMonthYear(
  DateTime date,
) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} '
      '${date.year}';
}

String _formatHour(
  int hour,
) {
  final period = hour >= 12 ? 'PM' : 'AM';

  final displayHour = hour == 0
      ? 12
      : hour > 12
          ? hour - 12
          : hour;

  return '$displayHour $period';
}

String _formatTime(
  DateTime date,
) {
  final hour = date.hour;
  final minute = date.minute;

  final period = hour >= 12 ? 'PM' : 'AM';

  final displayHour = hour == 0
      ? 12
      : hour > 12
          ? hour - 12
          : hour;

  final minuteText = minute.toString().padLeft(
        2,
        '0',
      );

  return '$displayHour:$minuteText $period';
}

String _formatTaskTime(
  DateTime? start,
  DateTime? end,
) {
  if (start != null && end != null) {
    if (_sameDay(start, end)) {
      return '${_formatTime(start)} - '
          '${_formatTime(end)}';
    }

    return '${_formatDate(start)} - '
        '${_formatDate(end)}';
  }

  if (start != null) {
    return _formatTime(start);
  }

  if (end != null) {
    return 'Due ${_formatDate(end)}';
  }

  return 'No schedule';
}

bool _sameDay(
  DateTime first,
  DateTime second,
) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

int _compareTasks(
  TaskModel a,
  TaskModel b,
) {
  final aDate = a.startDate ?? a.dueDate;

  final bDate = b.startDate ?? b.dueDate;

  if (aDate == null && bDate == null) {
    return a.title.compareTo(
      b.title,
    );
  }

  if (aDate == null) {
    return 1;
  }

  if (bDate == null) {
    return -1;
  }

  return aDate.compareTo(
    bDate,
  );
}

String _cleanErrorMessage(
  Object error,
) {
  final message = error.toString();

  if (message.startsWith(
    'Exception: ',
  )) {
    return message.substring(
      'Exception: '.length,
    );
  }

  return message;
}
