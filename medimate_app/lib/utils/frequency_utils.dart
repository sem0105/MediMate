import 'package:flutter/material.dart';

/// Shared frequency options for medicine and activity forms.
const List<String> dailyFrequencyOptions = [
  "Once Daily",
  "Twice Daily",
  "Thrice Daily",
  "On Demand",
];

const List<String> activityFrequencyOptions = [
  "Once Daily",
  "Twice Daily",
  "Thrice Daily",
  "On Demand",
  "Weekly",
];

int requiredReminderCount(String frequency) {
  if (isWeeklyFrequency(frequency)) {
    return requiredReminderCount("Once Daily");
  }
  switch (frequency) {
    case "Twice Daily":
      return 2;
    case "Thrice Daily":
      return 3;
    case "Once Daily":
    case "On Demand":
    default:
      return 1;
  }
}

bool isOnDemand(String frequency) => frequency == "On Demand";

bool isWeeklyFrequency(String frequency) =>
    frequency.toLowerCase().contains("weekly");

String reminderTimeLabel(int index, int total) {
  if (total == 1) return "Reminder time";
  return "Time ${index + 1} of $total";
}

List<String> timesToStrings(List<TimeOfDay?> times) {
  return times
      .where((t) => t != null)
      .map(
        (t) =>
            "${t!.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
      )
      .toList();
}

List<TimeOfDay?> parseReminderTimes(List? raw, int requiredCount) {
  final result = <TimeOfDay?>[];
  if (raw != null) {
    for (final item in raw) {
      final parts = item.toString().split(":");
      if (parts.length >= 2) {
        result.add(
          TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          ),
        );
      }
    }
  }
  while (result.length < requiredCount) {
    result.add(null);
  }
  if (result.length > requiredCount) {
    return result.sublist(0, requiredCount);
  }
  return result;
}

void resizeReminderTimes(List<TimeOfDay?> list, int newCount) {
  while (list.length < newCount) {
    list.add(null);
  }
  while (list.length > newCount) {
    list.removeLast();
  }
}

String timeToKey(TimeOfDay time) =>
    "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

bool hasDuplicateReminderTimes(List<TimeOfDay?> times, int count) {
  final seen = <String>{};
  for (var i = 0; i < count; i++) {
    if (i >= times.length || times[i] == null) continue;
    final key = timeToKey(times[i]!);
    if (seen.contains(key)) return true;
    seen.add(key);
  }
  return false;
}

/// Returns error message or null if valid.
String? validateReminderTimes(List<TimeOfDay?> times, int count) {
  if (times.length < count || times.take(count).any((t) => t == null)) {
    return "Please set all $count reminder time${count > 1 ? 's' : ''}";
  }
  if (hasDuplicateReminderTimes(times, count)) {
    return "Each reminder time must be different — no duplicate times";
  }
  return null;
}

List<String> activityTimesFromMap(Map<String, dynamic> act) {
  final raw = act["reminderTimes"];
  if (raw is List && raw.isNotEmpty) {
    return raw.map((e) => e.toString()).toList();
  }
  final single = act["reminderTime"]?.toString();
  if (single != null && single.isNotEmpty) return [single];
  return [];
}
