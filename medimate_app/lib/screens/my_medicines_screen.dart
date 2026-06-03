import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/medicine_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/confirm_delete_dialog.dart';
import '../widgets/app_back_button.dart';
import 'medicine_form_screen.dart';

class MyMedicinesScreen extends StatefulWidget {
  const MyMedicinesScreen({super.key});

  @override
  State<MyMedicinesScreen> createState() => _MyMedicinesScreenState();
}

class _MyMedicinesScreenState extends State<MyMedicinesScreen> {
  List<dynamic> medicines = [];
  bool loading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");

    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    setState(() => loading = true);
    final list = await MedicineService.getMedicines(userId!);
    setState(() {
      medicines = list;
      loading = false;
    });
  }

  String formatDate(String? iso) {
    if (iso == null) return "—";
    final d = DateTime.tryParse(iso);
    if (d == null) return "—";
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "${months[d.month - 1]} ${d.day}, ${d.year}";
  }

  String formatTime(List? times) {
    if (times == null || times.isEmpty) return "—";
    return times.first.toString();
  }

  Future<void> confirmDelete(Map<String, dynamic> med) async {
    final name = med["name"]?.toString() ?? "this medicine";

    final ok = await confirmDeleteDialog(
      context,
      title: "Delete medicine?",
      message:
          "Do you want to delete \"$name\" and all its scheduled tasks? This cannot be undone.",
    );

    if (!ok) return;

    final success =
        await MedicineService.deleteMedicine(med["_id"].toString());

    if (!mounted) return;

    if (success) {
      AppSnackbar.success(context, "Medicine deleted successfully");
      loadMedicines();
    } else {
      AppSnackbar.error(context, "Failed to delete medicine");
    }
  }

  Future<void> openEdit(Map<String, dynamic> med) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineFormScreen(existingMedicine: med),
      ),
    );

    if (updated == true) {
      loadMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Medicines"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
        actions: [
          IconButton(
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicineFormScreen(),
                ),
              );
              if (added == true) loadMedicines();
            },
            icon: const Icon(Icons.add),
            tooltip: "Add medicine",
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : medicines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          "No medicines yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap + to add your first medicine",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadMedicines,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final med = medicines[index] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.medication,
                                    color: Color(0xFF0D47A1),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      med["name"]?.toString() ?? "Unknown",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => openEdit(med),
                                    icon: const Icon(Icons.edit_outlined),
                                    color: const Color(0xFF0D47A1),
                                    tooltip: "Edit",
                                  ),
                                  IconButton(
                                    onPressed: () => confirmDelete(med),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    tooltip: "Delete",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${med["dose"]} ${med["units"]} • ${med["frequency"]}",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${formatDate(med["startDate"]?.toString())} → "
                                "${formatDate(med["endDate"]?.toString())}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                "Reminder: ${formatTime(med["reminderTimes"] as List?)}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
