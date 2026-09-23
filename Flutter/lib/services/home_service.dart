import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class HomeService {
  static const String baseUrl = 'http://localhost:5233/api';

  // ============================================================
  // LOAD HOME DATA
  // ============================================================

  Future<HomeData> loadHomeData() async {
    final projects = await _getProjects();

    // Only active projects are shown on Home.
    // AI/ML is intentionally NOT used here.
    final activeProjects = projects.where((project) {
      final status = _toInt(project['status']);

      return status == 2 && project['isArchived'] != true;
    }).toList();

    final allTasks = <Map<String, dynamic>>[];

    // ============================================================
    // LOAD TASKS FOR ACTIVE PROJECTS
    // ============================================================

    for (final project in activeProjects) {
      final projectId = _toInt(project['id']);

      if (projectId == null) {
        continue;
      }

      final tasks = await _getProjectTasks(projectId);

      for (final task in tasks) {
        task['_projectName'] = project['name'];
        task['_projectId'] = projectId;

        allTasks.add(task);
      }
    }

    final now = DateTime.now();

    // ============================================================
    // AT-RISK PROJECTS
    // ============================================================
    //
    // A project is considered At Risk when:
    //
    // 1. Backend explicitly marks the project as IsAtRisk = true
    // OR
    // 2. One of its active tasks is Blocked
    // OR
    // 3. One of its active tasks is Overdue
    //
    // AI/ML prediction is NOT used here.
    // ============================================================

    final atRiskProjectIds = <int>{};

    // ------------------------------------------------------------
    // 1. Read project-level IsAtRisk from Backend
    // ------------------------------------------------------------

    for (final project in activeProjects) {
      final projectId = _toInt(project['id']);

      if (projectId == null) {
        continue;
      }

      if (_toBool(project['isAtRisk'])) {
        atRiskProjectIds.add(projectId);
      }
    }

    // ------------------------------------------------------------
    // 2. Check tasks for Blocked / Overdue
    // ------------------------------------------------------------

    for (final task in allTasks) {
      final projectId = _toInt(task['_projectId']);

      if (projectId == null) {
        continue;
      }

      final status = _toInt(task['status']);
      final plannedEnd = _parseDate(task['plannedEnd']);

      // Status 5 = Done
      // Status 7 = Cancelled
      final isCompleted = status == 5;
      final isCancelled = status == 7;

      // Status 6 = Blocked
      final isBlocked = status == 6;

      final isOverdue = plannedEnd != null &&
          plannedEnd.isBefore(now) &&
          !isCompleted &&
          !isCancelled;

      if (isBlocked || isOverdue) {
        atRiskProjectIds.add(projectId);
      }
    }

    // ============================================================
    // TODAY'S TASKS
    // ============================================================

    final todayTasks = allTasks.where((task) {
      final plannedEnd = _parseDate(task['plannedEnd']);

      if (plannedEnd == null) {
        return false;
      }

      final status = _toInt(task['status']);

      if (status == 5 || status == 7) {
        return false;
      }

      return plannedEnd.year == now.year &&
          plannedEnd.month == now.month &&
          plannedEnd.day == now.day;
    }).toList();

    // ============================================================
    // COMPLETED TASKS
    // ============================================================

    final completedTasks = allTasks.where((task) {
      return _toInt(task['status']) == 5;
    }).length;

    // ============================================================
    // ACTIVE TASKS
    // ============================================================

    final activeTaskCount = allTasks.where((task) {
      final status = _toInt(task['status']);

      return status != 5 && status != 7;
    }).length;

    // ============================================================
    // OVERDUE TASKS
    // ============================================================

    final overdueTasks = allTasks.where((task) {
      final plannedEnd = _parseDate(task['plannedEnd']);

      if (plannedEnd == null) {
        return false;
      }

      final status = _toInt(task['status']);

      if (status == 5 || status == 7) {
        return false;
      }

      return plannedEnd.isBefore(now);
    }).toList();

    // ============================================================
    // UPCOMING TASKS
    // ============================================================

    final upcomingTasks = allTasks.where((task) {
      final plannedEnd = _parseDate(task['plannedEnd']);

      if (plannedEnd == null) {
        return false;
      }

      final status = _toInt(task['status']);

      return status != 5 && status != 7;
    }).toList();

    upcomingTasks.sort((a, b) {
      final aDate = _parseDate(a['plannedEnd']);
      final bDate = _parseDate(b['plannedEnd']);

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return aDate.compareTo(bDate);
    });

    // ============================================================
    // NOTIFICATIONS
    // ============================================================

    final notifications = await _getNotifications();

    // ============================================================
    // RETURN HOME DATA
    // ============================================================

    return HomeData(
      projects: activeProjects,
      allTasks: allTasks,
      todayTasks: todayTasks,
      upcomingTasks: upcomingTasks,
      overdueTasks: overdueTasks,
      completedTasks: completedTasks,
      activeTaskCount: activeTaskCount,
      atRiskProjectIds: atRiskProjectIds,
      notifications: notifications,

      // AI / ML is intentionally not ready yet.
      aiReady: false,
      aiInsight: null,
      projectHealth: null,
    );
  }

  // ============================================================
  // PROJECTS
  // ============================================================

  Future<List<Map<String, dynamic>>> _getProjects() async {
    final response = await _get(
      '$baseUrl/Projects?page=1&pageSize=100',
    );

    return _extractList(response);
  }

  // ============================================================
  // PROJECT TASKS
  // ============================================================

  Future<List<Map<String, dynamic>>> _getProjectTasks(
    int projectId,
  ) async {
    final response = await _get(
      '$baseUrl/projects/$projectId/Tasks?page=1&pageSize=100',
    );

    return _extractList(response);
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<List<HomeNotification>> _getNotifications() async {
    final response = await _get(
      '$baseUrl/Notifications?page=1&pageSize=20',
    );

    final list = _extractList(response);

    return list.map((item) {
      return HomeNotification(
        id: _toInt(item['id']) ?? 0,
        title: item['title']?.toString() ?? '',
        message: item['message']?.toString() ?? '',
        type: item['type']?.toString() ?? '',
        projectId: _toInt(item['projectId']),
        targetType: item['targetType']?.toString() ?? '',
        targetId: _toInt(item['targetId']) ?? 0,
        isRead: item['readAt'] != null,
        createdAt: _parseDate(item['createdAt']),
      );
    }).toList();
  }

  // ============================================================
  // UPDATE TASK COMPLETION
  // ============================================================

  Future<bool> updateTaskCompletion({
    required int projectId,
    required int taskId,
    required Map<String, dynamic> task,
    required bool completed,
  }) async {
    final body = {
      'title': task['title']?.toString() ?? '',
      'description': task['description'],
      'status': completed ? 5 : 3,
      'priority': _toInt(task['priority']) ?? 2,
      'type': _toInt(task['type']) ?? 1,
      'plannedStart': task['plannedStart'],
      'plannedEnd': task['plannedEnd'],
      'estimatedHours': task['estimatedHours'],
      'completionPercent':
          completed ? 100 : (_toInt(task['completionPercent']) ?? 0),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/projects/$projectId/Tasks/$taskId'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // ============================================================
  // MARK NOTIFICATION AS READ
  // ============================================================

  Future<bool> markNotificationAsRead(
    int notificationId,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Notifications/$notificationId/read'),
      headers: _headers(),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ============================================================

  Future<bool> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/Notifications/read-all'),
      headers: _headers(),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // ============================================================
  // HTTP GET
  // ============================================================

  Future<Map<String, dynamic>> _get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET $url failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Invalid API response.');
  }

  // ============================================================
  // HEADERS
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
  // EXTRACT API LIST
  // ============================================================

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    return [];
  }

  // ============================================================
  // INTEGER PARSER
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

  // ============================================================
  // BOOLEAN PARSER
  // ============================================================

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase().trim();

    return text == 'true' || text == '1';
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}

// ================================================================
// HOME DATA
// ================================================================

class HomeData {
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> allTasks;
  final List<Map<String, dynamic>> todayTasks;
  final List<Map<String, dynamic>> upcomingTasks;
  final List<Map<String, dynamic>> overdueTasks;
  final int completedTasks;
  final int activeTaskCount;
  final Set<int> atRiskProjectIds;
  final List<HomeNotification> notifications;

  // ============================================================
  // AI / ML PLACEHOLDERS
  // ============================================================

  final bool aiReady;
  final String? aiInsight;
  final double? projectHealth;

  const HomeData({
    required this.projects,
    required this.allTasks,
    required this.todayTasks,
    required this.upcomingTasks,
    required this.overdueTasks,
    required this.completedTasks,
    required this.activeTaskCount,
    required this.atRiskProjectIds,
    required this.notifications,
    required this.aiReady,
    required this.aiInsight,
    required this.projectHealth,
  });

  // ============================================================
  // GENERAL STATS
  // ============================================================

  int get totalTasks => allTasks.length;

  int get atRiskProjects => atRiskProjectIds.length;

  int get onTrackProjects {
    final result = projects.length - atRiskProjectIds.length;

    return result < 0 ? 0 : result;
  }

  int get unreadNotifications {
    return notifications.where((item) => !item.isRead).length;
  }

  // ============================================================
  // PROGRESS
  // ============================================================
  //
  // This is normal backend data, NOT AI/ML.
  // ============================================================

  double get overallProgress {
    if (allTasks.isEmpty) {
      return 0;
    }

    final totalProgress = allTasks.fold<double>(
      0,
      (sum, task) {
        final status = _taskStatus(task);

        if (status == 5) {
          return sum + 100;
        }

        final completion = task['completionPercent'];

        if (completion is num) {
          return sum + completion.toDouble();
        }

        return sum;
      },
    );

    return totalProgress / allTasks.length;
  }

  int _taskStatus(Map<String, dynamic> task) {
    final value = task['status'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ================================================================
// HOME NOTIFICATION
// ================================================================

class HomeNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String targetType;
  final int targetId;
  final int? projectId;
  final bool isRead;
  final DateTime? createdAt;

  const HomeNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetType,
    required this.targetId,
    required this.projectId,
    required this.isRead,
    required this.createdAt,
  });
}
