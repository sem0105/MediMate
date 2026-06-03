import 'dart:convert';
import 'package:http/http.dart' as http;
import 'medication_log_service.dart';

class WaterService {
  static const baseUrl = "http://10.0.2.2:5000/api/water";

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
      return List<dynamic>.from(data["entries"] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>> getForDate(
    String userId,
    DateTime date,
  ) async {
    final d = MedicationLogService.formatDate(date);
    final res = await http.get(Uri.parse("$baseUrl/date/$userId/$d"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return {"entries": [], "totalMl": 0};
  }

  static Future<double?> getGoalLiters(String userId) async {
    final res = await http.get(Uri.parse("$baseUrl/goal/$userId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final goal = data["goalLiters"];
      if (goal is num) return goal.toDouble();
    }
    return null;
  }

  static Future<bool> updateGoalLiters(String userId, double goalLiters) async {
    final res = await http.put(
      Uri.parse("$baseUrl/goal/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"goalLiters": goalLiters}),
    );
    return res.statusCode == 200;
  }

  static Future<Map<String, int>> getStreak(String userId) async {
    final res = await http.get(Uri.parse("$baseUrl/streak/$userId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return {
        "current": (data["currentStreak"] as num?)?.toInt() ?? 0,
        "max": (data["maxStreak"] as num?)?.toInt() ?? 0,
      };
    }
    return {"current": 0, "max": 0};
  }

  static Future<bool> update(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  static Future<bool> delete(String id) async {
    final res = await http.delete(Uri.parse("$baseUrl/$id"));
    return res.statusCode == 200;
  }
}
