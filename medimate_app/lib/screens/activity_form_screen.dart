import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/activity_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/frequency_utils.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';
import '../widgets/reminder_times_section.dart';

class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final nameController = TextEditingController();
  final notesController = TextEditingController();
  String frequency = "Once Daily";
  List<TimeOfDay?> reminderTimes = [null];
  final Set<String> selectedDays = {};
  bool saving = false;

  final weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  void _onFrequencyChanged(String? value) {
    if (value == null) return;
    setState(() {
      frequency = value;
      if (!isWeeklyFrequency(value)) {
        resizeReminderTimes(reminderTimes, requiredReminderCount(value));
      } else {
        resizeReminderTimes(reminderTimes, 1);
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      AppSnackbar.error(context, "Activity name is required");
      return;
    }

    if (isWeeklyFrequency(frequency) && selectedDays.isEmpty) {
      AppSnackbar.error(context, "Select at least one day for weekly activity");
      return;
    }

    final count = requiredReminderCount(frequency);
    final timeError = validateReminderTimes(reminderTimes, count);
    if (timeError != null) {
      AppSnackbar.error(context, timeError);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      AppSnackbar.error(context, "Please login again");
      return;
    }

    setState(() => saving = true);

    final timeStrings = timesToStrings(reminderTimes.take(count).toList());

    final ok = await ActivityService.add({
      "userId": userId,
      "activityName": nameController.text.trim(),
      "frequency": frequency,
      "reminderTimes": timeStrings,
      "reminderTime": timeStrings.first,
      "days": isWeeklyFrequency(frequency) ? selectedDays.toList() : [],
      "notes": notesController.text.trim(),
    });

    if (!mounted) return;
    setState(() => saving = false);

    if (ok) {
      AppSnackbar.success(context, "Activity saved successfully");
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, "Failed to save activity");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Add Activity"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: CenteredFormLayout(
        child: centeredFormCard(
            children: [
              const Text(
                "Add a daily or weekly activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Activity name *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: frequency,
                items: activityFrequencyOptions
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: _onFrequencyChanged,
                decoration: const InputDecoration(
                  labelText: "How often?",
                  border: OutlineInputBorder(),
                ),
              ),
              if (isWeeklyFrequency(frequency)) ...[
                const SizedBox(height: 12),
                const Text(
                  "Select days",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 6,
                  children: weekDays.map((day) {
                    final selected = selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
              ReminderTimesSection(
                times: reminderTimes,
                frequency: frequency,
                onTimesChanged: (updated) {
                  setState(() => reminderTimes = updated);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Notes (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Activity",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
