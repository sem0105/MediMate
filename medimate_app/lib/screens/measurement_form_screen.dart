import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/measurement_types.dart';
import '../services/measurement_service.dart';
import '../services/medication_log_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';

class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({super.key});

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  String selectedType = measurementTypes.first.id;
  final valueController = TextEditingController();
  final extraController = TextEditingController();
  final notesController = TextEditingController();
  bool saving = false;

  MeasurementTypeInfo get typeInfo =>
      findMeasurementType(selectedType)!;

  @override
  void dispose() {
    valueController.dispose();
    extraController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (valueController.text.trim().isEmpty) {
      AppSnackbar.error(context, "Please enter a value");
      return;
    }

    if (typeInfo.hasSecondary && extraController.text.trim().isEmpty) {
      AppSnackbar.error(context, "Please enter ${typeInfo.secondaryLabel}");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      AppSnackbar.error(context, "Please login again");
      return;
    }

    setState(() => saving = true);

    final now = DateTime.now();
    final ok = await MeasurementService.add({
      "userId": userId,
      "type": selectedType,
      "value": valueController.text.trim(),
      "extraValue": extraController.text.trim(),
      "unit": typeInfo.unit,
      "notes": notesController.text.trim(),
      "date": MedicationLogService.formatDate(now),
      "recordedAt": now.toIso8601String(),
    });

    if (!mounted) return;
    setState(() => saving = false);

    if (ok) {
      AppSnackbar.success(context, "Measurement saved successfully");
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, "Failed to save measurement");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Add Measurement"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: CenteredFormLayout(
        child: centeredFormCard(
          children: [
            const Text(
              "Record a health measurement",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
                value: selectedType,
                items: measurementTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
                decoration: const InputDecoration(
                  labelText: "Measurement type",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: typeInfo.hasSecondary
                      ? "Systolic (${typeInfo.unit})"
                      : "Value (${typeInfo.unit})",
                  border: const OutlineInputBorder(),
                ),
              ),
              if (typeInfo.hasSecondary) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: extraController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "${typeInfo.secondaryLabel} (${typeInfo.unit})",
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
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
                          "Save Measurement",
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
