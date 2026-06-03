import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/medicine_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/frequency_utils.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';
import '../widgets/reminder_times_section.dart';

class MedicineFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingMedicine;

  const MedicineFormScreen({super.key, this.existingMedicine});

  bool get isEditing => existingMedicine != null;

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();

  String selectedUnit = "Pills";
  String selectedFrequency = "Once Daily";
  DateTime? startDate;
  DateTime? endDate;
  List<TimeOfDay?> reminderTimes = [null];
  bool saving = false;

  final List<String> units = [
    "IU",
    "Ampoules",
    "Capsules",
    "Drops",
    "Grams",
    "Injections",
    "Milligrams",
    "Millilitres",
    "Pills",
    "Spray",
    "Tablets",
    "Sachets",
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final med = widget.existingMedicine;
    if (med == null) return;

    nameController.text = med["name"]?.toString() ?? "";
    doseController.text = med["dose"]?.toString() ?? "";
    selectedUnit = med["units"]?.toString() ?? "Pills";
    selectedFrequency = med["frequency"]?.toString() ?? "Once Daily";

    if (med["startDate"] != null) {
      startDate = DateTime.tryParse(med["startDate"].toString());
    }
    if (med["endDate"] != null) {
      endDate = DateTime.tryParse(med["endDate"].toString());
    }

    reminderTimes = parseReminderTimes(
      med["reminderTimes"] as List?,
      requiredReminderCount(selectedFrequency),
    );
  }

  void _onFrequencyChanged(String? value) {
    if (value == null) return;
    setState(() {
      selectedFrequency = value;
      resizeReminderTimes(reminderTimes, requiredReminderCount(value));
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          startDate = date;
        } else {
          endDate = date;
        }
      });
    }
  }

  Map<String, dynamic>? buildPayload(String userId) {
    if (nameController.text.trim().isEmpty ||
        doseController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      AppSnackbar.error(context, "Please fill name, dose, and dates");
      return null;
    }

    if (endDate!.isBefore(startDate!)) {
      AppSnackbar.error(context, "End date must be on or after start date");
      return null;
    }

    final count = requiredReminderCount(selectedFrequency);
    final timeError = validateReminderTimes(reminderTimes, count);
    if (timeError != null) {
      AppSnackbar.error(context, timeError);
      return null;
    }

    final timeStrings = timesToStrings(reminderTimes.take(count).toList());

    return {
      "userId": userId,
      "name": nameController.text.trim(),
      "units": selectedUnit,
      "dose": doseController.text.trim(),
      "frequency": selectedFrequency,
      "startDate": startDate!.toIso8601String(),
      "endDate": endDate!.toIso8601String(),
      "reminderTimes": timeStrings,
      "reminderEnabled": true,
    };
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId == null) {
      AppSnackbar.error(context, "Please login again");
      return;
    }

    final data = buildPayload(userId);
    if (data == null) return;

    setState(() => saving = true);

    bool success;
    if (widget.isEditing) {
      final id = widget.existingMedicine!["_id"]?.toString();
      success = await MedicineService.updateMedicine(id!, data);
    } else {
      success = await MedicineService.addMedicine(data);
    }

    if (!mounted) return;
    setState(() => saving = false);

    if (success) {
      AppSnackbar.success(
        context,
        widget.isEditing
            ? "Medicine updated successfully"
            : "Medicine saved successfully",
      );
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, "Failed to save medicine");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Medicine" : "Add Medicine"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: CenteredFormLayout(
        child: centeredFormCard(
          children: [
              Text(
                widget.isEditing
                    ? "Update your medication details"
                    : "Add a new medication to your treatment",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Medicine Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                items: units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) => setState(() => selectedUnit = val!),
                decoration: const InputDecoration(
                  labelText: "Unit",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedFrequency,
                items: dailyFrequencyOptions
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: _onFrequencyChanged,
                decoration: const InputDecoration(
                  labelText: "How often?",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pickDate(true),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        startDate == null ? "Start" : formatDate(startDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pickDate(false),
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        endDate == null ? "End" : formatDate(endDate!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ReminderTimesSection(
                times: reminderTimes,
                frequency: selectedFrequency,
                onTimesChanged: (updated) {
                  setState(() => reminderTimes = updated);
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: doseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Dose",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.all(15),
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
                      : Text(
                          widget.isEditing ? "Update Medicine" : "Save Medicine",
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
