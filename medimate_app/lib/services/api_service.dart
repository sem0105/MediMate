import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  // 🔐 POST with auth
  static Future<http.Response> post(String endpoint, Map body) async {
    final token = await AuthService.getToken();

    return await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
  }
}
