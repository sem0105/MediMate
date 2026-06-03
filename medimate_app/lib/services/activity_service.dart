import 'dart:convert';
import 'package:http/http.dart' as http;
import 'medication_log_service.dart';

class ActivityService {
  static const baseUrl = "http://10.0.2.2:5000/api/activities";

  static Future<bool> add(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return res.statusCode == 201;
  }

  static Future<List<dynamic>> getForDate(String userId, DateTime date) async {
    final d = MedicationLogService.formatDate(date);
    final res = await http.get(
      Uri.parse("http://10.0.2.2:5000/api/activity-logs/date/$userId/$d"),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<dynamic>.from(data["logs"] ?? []);
    }
    return [];
  }

  static Future<bool> updateLogStatus(String logId, String status) async {
    final res = await http.put(
      Uri.parse("http://10.0.2.2:5000/api/activity-logs/status/$logId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> delete(String id) async {
    final res = await http.delete(Uri.parse("$baseUrl/$id"));
    return res.statusCode == 200;
  }
}
