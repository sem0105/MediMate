import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/water_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/confirm_delete_dialog.dart';
import '../widgets/app_back_button.dart';
import 'water_form_screen.dart';

class ProfileWaterScreen extends StatefulWidget {
  const ProfileWaterScreen({super.key});

  @override
  State<ProfileWaterScreen> createState() => _ProfileWaterScreenState();
}

class _ProfileWaterScreenState extends State<ProfileWaterScreen> {
  List<dynamic> entries = [];
  int todayTotalMl = 0;
  int currentStreak = 0;
  int bestStreak = 0;
  double? dailyGoalLiters;
  bool loading = true;
  bool goalDialogOpen = false;
  String? userId;

  int get dailyGoalMl => ((dailyGoalLiters ?? 0) * 1000).round();
  double get progress {
    if (dailyGoalMl <= 0) return 0;
    return (todayTotalMl / dailyGoalMl).clamp(0, 1).toDouble();
  }

  bool get isComplete => dailyGoalMl > 0 && todayTotalMl >= dailyGoalMl;
  String get statusText {
    if (dailyGoalMl <= 0) return "Set a daily goal to track completion";
    return isComplete ? "Daily intake complete" : "Daily intake not complete";
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _litersText(num ml) {
    final liters = ml / 1000;
    return "${liters.toStringAsFixed(liters >= 1 ? 1 : 2)} L";
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    final list = await WaterService.getForUser(userId!);
    final today = await WaterService.getForDate(userId!, DateTime.now());
    final goal = await WaterService.getGoalLiters(userId!);
    final streak = await WaterService.getStreak(userId!);
    if (!mounted) return;

    setState(() {
      entries = list;
      todayTotalMl = (today["totalMl"] as num?)?.toInt() ?? 0;
      dailyGoalLiters = goal;
      currentStreak = streak["current"] ?? 0;
      bestStreak = streak["max"] ?? 0;
      loading = false;
    });
  }

  Future<void> _showGoalDialog() async {
    if (goalDialogOpen || userId == null) return;

    goalDialogOpen = true;
    final controller = TextEditingController(
      text: dailyGoalLiters == null ? "" : dailyGoalLiters!.toStringAsFixed(1),
    );

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Daily water goal"),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Target intake (liters)",
                hintText: "Example: 2.5",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final value = double.tryParse(controller.text.trim());
                  if (value == null || value <= 0) {
                    AppSnackbar.error(
                      dialogContext,
                      "Enter a valid goal in liters",
                    );
                    return;
                  }

                  final ok = await WaterService.updateGoalLiters(
                    userId!,
                    value,
                  );
                  if (!dialogContext.mounted) return;

                  if (ok) {
                    Navigator.pop(dialogContext, true);
                  } else {
                    AppSnackbar.error(dialogContext, "Failed to save goal");
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );

      if (saved == true && mounted) await _load();
    } finally {
      controller.dispose();
      goalDialogOpen = false;
    }
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WaterFormScreen(existing: existing),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(dynamic entry) async {
    final confirmed = await confirmDeleteDialog(
      context,
      title: "Delete water entry?",
      message: "Remove ${_litersText(entry["amountMl"] ?? 0)} from ${entry["date"]}?",
    );
    if (!confirmed || !mounted) return;

    final ok = await WaterService.delete(entry["_id"]);
    if (!mounted) return;

    if (ok) {
      AppSnackbar.success(context, "Entry deleted");
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
        title: const Text("Water Intake"),
        backgroundColor: const Color(0xFF0277BD),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF0277BD),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0277BD), Color(0xFF4FC3F7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "${_litersText(todayTotalMl)} of ${_litersText(dailyGoalMl)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: "Edit goal",
                            onPressed: _showGoalDialog,
                            icon: const Icon(Icons.edit, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? const Color(0xFF66BB6A) : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (dailyGoalMl <= 0) ...[
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _showGoalDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0277BD),
                          ),
                          child: const Text("Set daily goal"),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StreakChip(
                              label: "Water streak",
                              value: "$currentStreak days",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StreakChip(
                              label: "Best",
                              value: "$bestStreak days",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            "No water entries yet.",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final e = entries[index];
                            final ml = e["amountMl"] ?? 0;
                            final date = e["date"]?.toString() ?? "";
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE1F5FE),
                                  child: Icon(
                                    Icons.water_drop,
                                    color: Color(0xFF0277BD),
                                  ),
                                ),
                                title: Text(
                                  _litersText(ml),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "$date"
                                  "${(e["notes"]?.toString() ?? "").isNotEmpty ? "\n${e["notes"]}" : ""}",
                                ),
                                isThreeLine: true,
                                onTap: () => _openForm(existing: e),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _delete(e),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final String label;
  final String value;

  const _StreakChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
