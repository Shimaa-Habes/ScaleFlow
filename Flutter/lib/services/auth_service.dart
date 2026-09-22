import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://localhost:5233/api/Auth';

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      print('========== LOGIN RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================');

      Map<String, dynamic> responseData = {};

      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful.',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Invalid email or password.',
      };
    } catch (e) {
      print('========== LOGIN ERROR ==========');
      print(e);
      print('=================================');

      return {
        'success': false,
        'message': 'Unable to connect to the server. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'fullName': name.trim(),
          'email': email.trim(),
          'password': password,
          'phone': '0591234567',
          'organizationId': 1,
        }),
      );

      print('========== REGISTER RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=======================================');

      Map<String, dynamic> responseData = {};

      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Account created successfully.',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message':
            responseData['message'] ?? 'Registration failed. Please try again.',
      };
    } catch (e) {
      print('========== REGISTER ERROR ==========');
      print(e);
      print('====================================');

      return {
        'success': false,
        'message': 'Unable to connect to the server. Please try again.',
      };
    }
  }
}
