import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/appointment_service.dart';
import '../services/medication_log_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';

class AppointmentFormScreen extends StatefulWidget {
  const AppointmentFormScreen({super.key});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final doctorController = TextEditingController();
  final hospitalController = TextEditingController();
  final notesController = TextEditingController();
  DateTime? appointmentDate;
  TimeOfDay? appointmentTime;
  bool saving = false;

  @override
  void dispose() {
    doctorController.dispose();
    hospitalController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: appointmentDate ?? DateTime.now(),
    );
    if (date != null) setState(() => appointmentDate = date);
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: appointmentTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => appointmentTime = time);
  }

  Future<void> save() async {
    if (doctorController.text.trim().isEmpty ||
        appointmentDate == null ||
        appointmentTime == null) {
      AppSnackbar.error(context, "Doctor name, date and time are required");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      AppSnackbar.error(context, "Please login again");
      return;
    }

    setState(() => saving = true);

    final timeStr =
        "${appointmentTime!.hour.toString().padLeft(2, '0')}:${appointmentTime!.minute.toString().padLeft(2, '0')}";

    final ok = await AppointmentService.add({
      "userId": userId,
      "doctorName": doctorController.text.trim(),
      "hospital": hospitalController.text.trim(),
      "appointmentDate": appointmentDate!.toIso8601String(),
      "appointmentTime": timeStr,
      "notes": notesController.text.trim(),
    });

    if (!mounted) return;
    setState(() => saving = false);

    if (ok) {
      AppSnackbar.success(context, "Appointment saved successfully");
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, "Failed to save appointment");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Doctor Appointment"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: CenteredFormLayout(
        child: centeredFormCard(
          children: [
            const Text(
              "Schedule a doctor visit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: doctorController,
              decoration: const InputDecoration(
                labelText: "Doctor name *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: hospitalController,
              decoration: const InputDecoration(
                labelText: "Hospital / Clinic (optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      appointmentDate == null
                          ? "Date *"
                          : MedicationLogService.formatDate(appointmentDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      appointmentTime == null
                          ? "Time *"
                          : appointmentTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Notes",
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
                        "Save Appointment",
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
