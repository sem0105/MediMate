import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/measurement_types.dart';
import '../services/measurement_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/confirm_delete_dialog.dart';
import '../widgets/app_back_button.dart';
import 'measurement_form_screen.dart';

class ProfileMeasurementsScreen extends StatefulWidget {
  const ProfileMeasurementsScreen({super.key});

  @override
  State<ProfileMeasurementsScreen> createState() =>
      _ProfileMeasurementsScreenState();
}

class _ProfileMeasurementsScreenState extends State<ProfileMeasurementsScreen> {
  List<dynamic> measurements = [];
  bool loading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    final list = await MeasurementService.getForUser(userId!);
    if (!mounted) return;
    setState(() {
      measurements = list;
      loading = false;
    });
  }

  Future<void> _openAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const MeasurementFormScreen()),
    );
    if (added == true) await _load();
  }

  Future<void> _delete(dynamic m) async {
    final label = measurementDisplayLabel(m["type"]?.toString() ?? "");
    final confirmed = await confirmDeleteDialog(
      context,
      title: "Delete measurement?",
      message: "Do you want to delete this $label record?",
    );
    if (!confirmed || !mounted) return;

    final ok = await MeasurementService.delete(m["_id"]);
    if (!mounted) return;

    if (ok) {
      AppSnackbar.success(context, "Measurement deleted");
      await _load();
    } else {
      AppSnackbar.error(context, "Failed to delete");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Measurements"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : measurements.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "No measurements yet.\nTap Add to record blood pressure, weight, and more.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: measurements.length,
                  itemBuilder: (context, index) {
                    final m = measurements[index];
                    final label =
                        measurementDisplayLabel(m["type"]?.toString() ?? "");
                    final date = m["date"]?.toString() ?? "";
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFCE4EC),
                          child: Icon(Icons.favorite, color: Colors.red),
                        ),
                        title: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${measurementDisplayValue(m)}"
                          "${date.isNotEmpty ? "\n$date" : ""}"
                          "${(m["notes"]?.toString() ?? "").isNotEmpty ? "\n${m["notes"]}" : ""}",
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _delete(m),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
