import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../core/api_config.dart';

class AuthService {
  static Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": username,
          "password": password,
          "expiresInMins": 30,
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(decoded);
      } else {
        return LoginResponse(message: decoded['message'] ?? "Login failed");
      }
    } catch (e) {
      return LoginResponse(message: "Network error");
    }
  }
}