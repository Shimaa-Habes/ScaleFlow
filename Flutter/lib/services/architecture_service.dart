import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/project_architecture.dart';
import 'auth_service.dart';

class ArchitectureService {
  static const String baseUrl = 'http://localhost:5233/api';

  Future<ProjectArchitecture?> getArchitecture(int projectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/architecture'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Get architecture failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid architecture response.');
    }

    final data = decoded['data'];

    if (data == null) {
      return null;
    }

    if (data is Map<String, dynamic>) {
      return ProjectArchitecture.fromJson(data);
    }

    throw Exception('Invalid architecture data.');
  }

  Future<ProjectArchitecture> createArchitecture({
    required int projectId,
    String? frontend,
    String? backend,
    String? database,
    String? authentication,
    String? aiMl,
    String? realTime,
    String? externalServices,
  }) async {
    return _save(
      method: 'POST',
      projectId: projectId,
      frontend: frontend,
      backend: backend,
      database: database,
      authentication: authentication,
      aiMl: aiMl,
      realTime: realTime,
      externalServices: externalServices,
    );
  }

  Future<ProjectArchitecture> updateArchitecture({
    required int projectId,
    String? frontend,
    String? backend,
    String? database,
    String? authentication,
    String? aiMl,
    String? realTime,
    String? externalServices,
  }) async {
    return _save(
      method: 'PUT',
      projectId: projectId,
      frontend: frontend,
      backend: backend,
      database: database,
      authentication: authentication,
      aiMl: aiMl,
      realTime: realTime,
      externalServices: externalServices,
    );
  }

  Future<ProjectArchitecture> _save({
    required String method,
    required int projectId,
    String? frontend,
    String? backend,
    String? database,
    String? authentication,
    String? aiMl,
    String? realTime,
    String? externalServices,
  }) async {
    final body = <String, dynamic>{
      'frontend': _clean(frontend),
      'backend': _clean(backend),
      'database': _clean(database),
      'authentication': _clean(authentication),
      'aiMl': _clean(aiMl),
      'realTime': _clean(realTime),
      'externalServices': _clean(externalServices),
    };

    final uri = Uri.parse(
      '$baseUrl/projects/$projectId/architecture',
    );

    late http.Response response;

    if (method == 'POST') {
      response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
    } else {
      response = await http.put(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Save architecture failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic> &&
        decoded['data'] is Map<String, dynamic>) {
      return ProjectArchitecture.fromJson(
        Map<String, dynamic>.from(decoded['data']),
      );
    }

    throw Exception('Invalid save architecture response.');
  }

  String? _clean(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  Map<String, String> _headers() {
    final token = AuthService.accessToken;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
