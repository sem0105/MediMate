import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicationLogService {
  static const baseUrl = "http://10.0.2.2:5000/api/medication-logs";

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  static Future<List<dynamic>> getLogsForDate(
    String userId,
    DateTime date,
  ) async {
    final dateStr = formatDate(date);
    final url = Uri.parse("$baseUrl/date/$userId/$dateStr");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data["logs"] ?? []);
    }

    return [];
  }

  static Future<Set<String>> getCalendarDates(
    String userId,
    int year,
    int month,
  ) async {
    final url = Uri.parse(
      "$baseUrl/calendar/$userId?year=$year&month=$month",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final dates = List<String>.from(data["dates"] ?? []);
      return dates.toSet();
    }

    return {};
  }

  static Future<bool> updateStatus(String logId, String status) async {
    final endpoint = status == "taken" ? "taken" : "skipped";
    final url = Uri.parse("$baseUrl/$endpoint/$logId");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        if (status == "taken") "takenAt": DateTime.now().toIso8601String(),
      }),
    );

    return response.statusCode == 200;
  }
}
