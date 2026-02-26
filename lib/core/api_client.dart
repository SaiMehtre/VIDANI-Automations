import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/secure_storage_service.dart';
import '../core/session_manager.dart';

class ApiClient {

  static Future<String?> _getToken() async {
    String? token = SessionManager.token;
    token ??= await SecureStorageService.getToken();
    return token;
  }

  static Future<http.Response> get(String url) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Session expired");
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      await SecureStorageService.clearAll();
      SessionManager.clear();
      throw Exception("Session expired");
    }

    return response;
  }

  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {

    final token = await _getToken();

    if (token == null) {
      throw Exception("Session expired");
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      await SecureStorageService.clearAll();
      SessionManager.clear();
      throw Exception("Session expired");
    }

    return response;
  }
}