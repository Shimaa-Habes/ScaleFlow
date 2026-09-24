import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class RiskAnalysisResult {
  final int projectId;
  final double riskScore;
  final double confidence;
  final String explanation;

  RiskAnalysisResult({
    required this.projectId,
    required this.riskScore,
    required this.confidence,
    required this.explanation,
  });

  factory RiskAnalysisResult.fromJson(Map<String, dynamic> json) {
    return RiskAnalysisResult(
      projectId: (json['projectId'] as num?)?.toInt() ?? 0,
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class RiskAnalysisService {
  static const String baseUrl = 'http://localhost:5233/api';

  Future<RiskAnalysisResult> analyzeRisk({
    required int projectId,
    int inputWindowDays = 30,
  }) async {
    final token = AuthService.accessToken;

    final response = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/ai/risk-analysis'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'inputWindowDays': inputWindowDays,
      }),
    );

    print('========== RISK ANALYSIS ==========');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('====================================');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Risk analysis failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid risk analysis response.');
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid risk analysis data.');
    }

    return RiskAnalysisResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}
