import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine_dashboard_model.dart';

class TaskStats {
  final int pending;
  final int taken;
  final int skipped;
  final List<TaskStatsDay> breakdown;

  TaskStats({
    required this.pending,
    required this.taken,
    required this.skipped,
    required this.breakdown,
  });

  factory TaskStats.fromJson(Map<String, dynamic> json) {
    final totals = json["totals"] ?? {};
    final list = (json["breakdown"] as List? ?? [])
        .map((e) => TaskStatsDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return TaskStats(
      pending: totals["pending"] ?? 0,
      taken: totals["taken"] ?? 0,
      skipped: totals["skipped"] ?? 0,
      breakdown: list,
    );
  }
}

class TaskStatsDay {
  final String label;
  final int pending;
  final int taken;
  final int skipped;

  TaskStatsDay({
    required this.label,
    required this.pending,
    required this.taken,
    required this.skipped,
  });

  factory TaskStatsDay.fromJson(Map<String, dynamic> json) {
    return TaskStatsDay(
      label: json["label"]?.toString() ?? "",
      pending: json["pending"] ?? 0,
      taken: json["taken"] ?? 0,
      skipped: json["skipped"] ?? 0,
    );
  }
}

class StreakStats {
  final int current;
  final int max;

  StreakStats({required this.current, required this.max});

  factory StreakStats.fromJson(Map<String, dynamic> json) {
    return StreakStats(
      current: (json["currentStreak"] as num?)?.toInt() ?? 0,
      max: (json["maxStreak"] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardService {
  static const baseUrl = "http://10.0.2.2:5000/api/dashboard";
  static const logsBaseUrl = "http://10.0.2.2:5000/api/medication-logs";

  static Future<List<MedicineDashboardModel>> getTodayMedicines(
    String userId,
  ) async {
    final url = Uri.parse("$logsBaseUrl/today/$userId");
    final response = await http.get(url);

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    if (data["success"] != true) {
      return [];
    }

    final logs = List<dynamic>.from(data["logs"] ?? []);

    return logs.map((log) {
      final medicine = log["medicineId"] as Map<String, dynamic>?;

      return MedicineDashboardModel(
        logId: log["_id"]?.toString() ?? "",
        medicineName: medicine?["name"]?.toString() ?? "Unknown",
        dosage: medicine?["dose"]?.toString() ?? "",
        unit: medicine?["units"]?.toString() ?? "",
        time: log["scheduledTime"]?.toString() ?? "",
        status: log["status"]?.toString() ?? "pending",
      );
    }).toList();
  }

  static Future<TaskStats?> getTaskStats(
    String userId,
    String period,
  ) async {
    final url = Uri.parse("$baseUrl/task-stats/$userId?period=$period");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return TaskStats.fromJson(Map<String, dynamic>.from(data));
      }
    }

    return null;
  }

  static Future<StreakStats> getMedicineStreak(String userId) async {
    final url = Uri.parse("$baseUrl/streak/$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return StreakStats.fromJson(Map<String, dynamic>.from(data));
      }
    }

    return StreakStats(current: 0, max: 0);
  }
}
