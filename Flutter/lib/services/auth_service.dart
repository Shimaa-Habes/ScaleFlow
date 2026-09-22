import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://localhost:5233/api/Auth";

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            "Login failed. Status: ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error during login: $e");
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": name,
          "email": email,
          "password": password,
          "phone": "0591234567",
          "organizationId": 1
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print(
            "Register failed. Status: ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error during register: $e");
      return false;
    }
  }
}
