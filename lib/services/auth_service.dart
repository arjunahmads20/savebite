import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://arjunahmads24.pythonanywhere.com/api';

  Future<String?> login(String usernameOrEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': usernameOrEmail, // SimpleJWT defaults to username
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access'];
        await _saveToken(token);
        return null; // Null means success (no error)
      } else {
        final errorData = json.decode(response.body);
        return errorData['detail'] ?? 'Failed to login. Please check your credentials.';
      }
    } catch (e) {
      return 'Network error occurred. Please try again.';
    }
  }

  Future<String?> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        return null; // Success
      } else {
        final errorData = json.decode(response.body);
        // Extract the first error message
        final firstError = errorData.values.first;
        return (firstError is List) ? firstError[0] : firstError.toString();
      }
    } catch (e) {
      return 'Network error occurred. Please try again.';
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
