import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/medication_log_service.dart';
import '../services/water_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';

class WaterFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const WaterFormScreen({super.key, this.existing});

  @override
  State<WaterFormScreen> createState() => _WaterFormScreenState();
}

class _WaterFormScreenState extends State<WaterFormScreen> {
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool saving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      final amountMl = (e["amountMl"] as num?)?.toDouble() ?? 0;
      amountController.text =
          amountMl > 0 ? (amountMl / 1000).toStringAsFixed(2) : "";
      notesController.text = e["notes"]?.toString() ?? "";
      final d = e["date"]?.toString();
      if (d != null && d.contains("-")) {
        final parts = d.split("-");
        if (parts.length == 3) {
          selectedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> save() async {
    final liters = double.tryParse(amountController.text.trim());
    if (liters == null || liters <= 0) {
      AppSnackbar.error(context, "Enter a valid amount in liters");
      return;
    }
    final ml = (liters * 1000).round();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      AppSnackbar.error(context, "Please login again");
      return;
    }

    setState(() => saving = true);

    final dateStr = MedicationLogService.formatDate(selectedDate);
    final payload = {
      "userId": userId,
      "amountMl": ml,
      "date": dateStr,
      "notes": notesController.text.trim(),
      "recordedAt": DateTime.now().toIso8601String(),
    };

    bool ok;
    if (isEdit) {
      ok = await WaterService.update(widget.existing!["_id"], payload);
    } else {
      ok = await WaterService.add(payload);
    }

    if (!mounted) return;
    setState(() => saving = false);

    if (ok) {
      AppSnackbar.success(
        context,
        isEdit ? "Water entry updated" : "Water intake saved",
      );
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, "Failed to save");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isEdit ? "Edit Water" : "Add Water"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: CenteredFormLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Amount completed (liters)",
                hintText: "Example: 0.25",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text("Date"),
              subtitle: Text(MedicationLogService.formatDate(selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: pickDate,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: "Notes (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saving ? null : save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? "Update" : "Save"),
            ),
          ],
        ),
      ),
    );
  }
}
