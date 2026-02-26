import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/secure_storage_service.dart';

class ApiClient {

  static Future<http.Response> get(String url) async {
    final token = await SecureStorageService.getToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      await SecureStorageService.clearAll();
      throw Exception("Session expired");
    }

    return response;
  }

  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final token = await SecureStorageService.getToken();

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
      throw Exception("Session expired");
    }

    return response;
  }

  
}