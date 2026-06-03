import 'dart:convert';
import 'package:http/http.dart' as http;
import 'medication_log_service.dart';

class MeasurementService {
  static const baseUrl = "http://10.0.2.2:5000/api/measurements";

  static Future<bool> add(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return res.statusCode == 201;
  }

  static Future<List<dynamic>> getForUser(String userId) async {
    final res = await http.get(Uri.parse("$baseUrl/user/$userId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<dynamic>.from(data["measurements"] ?? []);
    }
    return [];
  }

  static Future<List<dynamic>> getForDate(String userId, DateTime date) async {
    final d = MedicationLogService.formatDate(date);
    final res = await http.get(Uri.parse("$baseUrl/date/$userId/$d"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<dynamic>.from(data["measurements"] ?? []);
    }
    return [];
  }

  static Future<bool> delete(String id) async {
    final res = await http.delete(Uri.parse("$baseUrl/$id"));
    return res.statusCode == 200;
  }
}
