class ProjectArchitecture {
  final int id;
  final int projectId;
  final String? frontend;
  final String? backend;
  final String? database;
  final String? authentication;
  final String? aiMl;
  final String? realTime;
  final String? externalServices;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProjectArchitecture({
    required this.id,
    required this.projectId,
    this.frontend,
    this.backend,
    this.database,
    this.authentication,
    this.aiMl,
    this.realTime,
    this.externalServices,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectArchitecture.fromJson(Map<String, dynamic> json) {
    return ProjectArchitecture(
      id: _toInt(json['id']) ?? 0,
      projectId: _toInt(json['projectId']) ?? 0,
      frontend: _nullableString(json['frontend']),
      backend: _nullableString(json['backend']),
      database: _nullableString(json['database']),
      authentication: _nullableString(json['authentication']),
      aiMl: _nullableString(json['aiMl']),
      realTime: _nullableString(json['realTime']),
      externalServices: _nullableString(json['externalServices']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}
