import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:5233/api';

  // ============================================================
  // GET ALL PROJECTS
  // ============================================================
  // This is separate from getAllTasks().
  // It allows the Add Task screen to show projects even when
  // those projects currently have ZERO tasks.
  // ============================================================

  Future<List<Map<String, dynamic>>> getProjects() async {
    final response = await _get(
      '$baseUrl/Projects?page=1&pageSize=100',
    );

    final projects = _extractList(response);

    // Keep only projects that are not archived.
    return projects.where((project) {
      return project['isArchived'] != true;
    }).toList();
  }

  // ============================================================
  // GET ALL TASKS FROM ALL ACCESSIBLE PROJECTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final projects = await getProjects();

    final allTasks = <Map<String, dynamic>>[];

    for (final project in projects) {
      final projectId = _toInt(project['id']);

      if (projectId == null) {
        continue;
      }

      final projectName = project['name']?.toString().trim().isNotEmpty == true
          ? project['name'].toString()
          : 'Unknown Project';

      try {
        final tasksResponse = await _get(
          '$baseUrl/projects/$projectId/Tasks?page=1&pageSize=100',
        );

        final tasks = _extractList(tasksResponse);

        for (final task in tasks) {
          task['_projectName'] = projectName;
          task['_projectId'] = projectId;

          allTasks.add(task);
        }
      } catch (_) {
        // If one project's tasks fail, continue loading
        // tasks from the other accessible projects.
        continue;
      }
    }

    return allTasks;
  }

  // ============================================================
  // CREATE TASK
  // ============================================================

  Future<Map<String, dynamic>> createTask({
    required int projectId,
    required String title,
    String? description,
    required int status,
    required int priority,
    int type = 1,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    double? estimatedHours,
    int? completionPercent,
    String? projectName,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'type': type,
      'plannedStart': plannedStart?.toUtc().toIso8601String(),
      'plannedEnd': plannedEnd?.toUtc().toIso8601String(),
      'estimatedHours': estimatedHours,
      'completionPercent': completionPercent,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/Tasks'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Create task failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic> &&
        decoded['data'] is Map<String, dynamic>) {
      final task = Map<String, dynamic>.from(decoded['data']);

      task['_projectName'] = projectName ?? '';
      task['_projectId'] = projectId;

      return task;
    }

    throw Exception('Invalid create task response.');
  }

  // ============================================================
  // UPDATE TASK
  // ============================================================

  Future<Map<String, dynamic>> updateTask({
    required int projectId,
    required int taskId,
    required String title,
    String? description,
    required int status,
    required int priority,
    int type = 1,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    double? estimatedHours,
    int? completionPercent,
    String? projectName,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'type': type,
      'plannedStart': plannedStart?.toUtc().toIso8601String(),
      'plannedEnd': plannedEnd?.toUtc().toIso8601String(),
      'estimatedHours': estimatedHours,
      'completionPercent': completionPercent,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/projects/$projectId/Tasks/$taskId'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Update task failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic> &&
        decoded['data'] is Map<String, dynamic>) {
      final task = Map<String, dynamic>.from(decoded['data']);

      task['_projectName'] = projectName ?? '';
      task['_projectId'] = projectId;

      return task;
    }

    throw Exception('Invalid update task response.');
  }

  // ============================================================
  // DELETE TASK
  // ============================================================

  Future<void> deleteTask({
    required int projectId,
    required int taskId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$projectId/Tasks/$taskId'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Delete task failed: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  // ============================================================
  // GET
  // ============================================================

  Future<Map<String, dynamic>> _get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET $url failed: '
        '${response.statusCode} ${response.body}',
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
  // EXTRACT LIST
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
}
