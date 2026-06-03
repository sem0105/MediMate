import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_hub_screen.dart';
import 'profile_hub_screen.dart';
import '../services/activity_service.dart';
import '../services/appointment_service.dart';
import '../services/dashboard_service.dart';
import '../services/medication_log_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/confirm_delete_dialog.dart';
import '../utils/frequency_utils.dart';
import '../widgets/charts_tab.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({
    super.key,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  List medicines = [];
  List appointments = [];
  List activities = [];
  bool isLoading = true;
  String? userId;
  int medicineStreak = 0;
  int bestMedicineStreak = 0;

  DateTime selectedDate = DateTime.now();
  DateTime focusedDay = DateTime.now();
  Set<String> markedDates = {};
  bool openedFromCalendar = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    await refreshAllData();
  }

  Future<void> refreshAllData() async {
    await fetchMedicines();
    await fetchAppointments();
    await fetchActivities();
    await fetchMedicineStreak();
    await loadCalendarMarkers();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String formatDisplayDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  bool get isSelectedToday => isSameDay(selectedDate, DateTime.now());

  /// Tasks can only be completed on their scheduled date (when that date is today).
  bool canCompleteForLog(dynamic med) {
    if (!isSelectedToday) return false;
    final logDate = med["date"]?.toString();
    if (logDate == null) return true;
    return logDate == MedicationLogService.formatDate(selectedDate);
  }

  Future<void> goToToday() async {
    setState(() {
      selectedDate = DateTime.now();
      focusedDay = DateTime.now();
      openedFromCalendar = false;
    });
    await refreshAllData();
  }

  void handleAppBarBack() {
    if (openedFromCalendar && currentIndex == 0) {
      setState(() {
        currentIndex = 2;
        openedFromCalendar = false;
      });
      return;
    }
    if (!isSelectedToday && currentIndex == 0) {
      goToToday();
    }
  }

  Widget? buildAppBarLeading() {
    final needsBack = currentIndex == 0 &&
        (openedFromCalendar || !isSelectedToday);

    if (!needsBack) return null;

    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Color(0xFF0D47A1)),
      tooltip: openedFromCalendar ? "Back to calendar" : "Back to today",
      onPressed: handleAppBarBack,
    );
  }

  void showStatusDialog(dynamic med) {
    if (!canCompleteForLog(med)) return;

    final medicine = med["medicineId"];
    final name = medicine?["name"]?.toString() ?? "this medicine";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Medicine Status"),
          content: Text("Have you taken $name?"),
          actions: [
            TextButton(
              onPressed: () {
                updateStatus(med, "skipped");
                Navigator.pop(context);
              },
              child: const Text("Skip"),
            ),
            TextButton(
              onPressed: () {
                updateStatus(med, "taken");
                Navigator.pop(context);
              },
              child: const Text("Taken"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateStatus(dynamic med, String status) async {
    if (userId == null) return;

    final success =
        await MedicationLogService.updateStatus(med["_id"], status);

    if (success) {
      AppSnackbar.success(context, "Status updated successfully");
      await refreshAllData();
    } else {
      AppSnackbar.error(context, "Failed to update status");
    }
  }

  void showAppointmentStatusDialog(dynamic apt) {
    if (!isSelectedToday) return;
    if ((apt["status"] ?? "pending") != "pending") return;

    final name = apt["doctorName"]?.toString() ?? "this appointment";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Appointment"),
        content: Text("Did you attend the appointment with $name?"),
        actions: [
          TextButton(
            onPressed: () {
              updateAppointmentStatus(apt, "not_done");
              Navigator.pop(context);
            },
            child: const Text("Not done"),
          ),
          TextButton(
            onPressed: () {
              updateAppointmentStatus(apt, "done");
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> updateAppointmentStatus(dynamic apt, String status) async {
    final success = await AppointmentService.updateStatus(apt["_id"], status);
    if (!mounted) return;
    if (success) {
      AppSnackbar.success(context, "Appointment updated");
      await refreshAllData();
    } else {
      AppSnackbar.error(context, "Failed to update appointment");
    }
  }

  void showActivityStatusDialog(dynamic log) {
    if (!isSelectedToday) return;
    if ((log["status"] ?? "pending") != "pending") return;

    final act = log["activityId"];
    final name = act?["activityName"]?.toString() ?? "this activity";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Activity"),
        content: Text("Did you complete $name?"),
        actions: [
          TextButton(
            onPressed: () {
              updateActivityStatus(log, "not_done");
              Navigator.pop(context);
            },
            child: const Text("Not done"),
          ),
          TextButton(
            onPressed: () {
              updateActivityStatus(log, "done");
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> updateActivityStatus(dynamic log, String status) async {
    final success = await ActivityService.updateLogStatus(log["_id"], status);
    if (!mounted) return;
    if (success) {
      AppSnackbar.success(context, "Activity updated");
      await refreshAllData();
    } else {
      AppSnackbar.error(context, "Failed to update activity");
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "done":
      case "taken":
        return Colors.green;
      case "not_done":
      case "skipped":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> fetchAppointments() async {
    if (userId == null) return;
    final list =
        await AppointmentService.getForDate(userId!, selectedDate);
    setState(() => appointments = list);
  }

  Future<void> fetchActivities() async {
    if (userId == null) return;
    final list = await ActivityService.getForDate(userId!, selectedDate);
    list.sort((a, b) {
      final aTime =
          getTimeValue(a["scheduledTime"]?.toString() ?? "00:00");
      final bTime =
          getTimeValue(b["scheduledTime"]?.toString() ?? "00:00");
      return aTime.compareTo(bTime);
    });
    setState(() => activities = list);
  }

  int getTimeValue(String time) {
    try {
      final parts = time.split(":");
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  String formatTime(String time) {
    try {
      final parts = time.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final period = hour >= 12 ? "PM" : "AM";
      hour = hour % 12;
      if (hour == 0) hour = 12;

      final minStr = minute.toString().padLeft(2, '0');
      return "$hour:$minStr $period";
    } catch (e) {
      return time;
    }
  }

  Future<void> fetchMedicines() async {
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final logs =
          await MedicationLogService.getLogsForDate(userId!, selectedDate);

      logs.sort((a, b) {
        final aTime = getTimeValue(a["scheduledTime"]?.toString() ?? "00:00");
        final bTime = getTimeValue(b["scheduledTime"]?.toString() ?? "00:00");
        return aTime.compareTo(bTime);
      });

      setState(() {
        medicines = logs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Fetch error: $e");
    }
  }

  Future<void> fetchMedicineStreak() async {
    if (userId == null) return;

    final streak = await DashboardService.getMedicineStreak(userId!);
    if (!mounted) return;

    setState(() {
      medicineStreak = streak.current;
      bestMedicineStreak = streak.max;
    });
  }

  Future<void> loadCalendarMarkers() async {
    if (userId == null) return;

    final dates = await MedicationLogService.getCalendarDates(
      userId!,
      focusedDay.year,
      focusedDay.month,
    );

    setState(() {
      markedDates = dates;
    });
  }

  String getInitials(String name) {
    if (name.trim().isEmpty) return "U";

    final parts =
        name.trim().split(" ").where((e) => e.isNotEmpty).toList();

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("userId");
    await prefs.remove("email");

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }

  void openAddHub() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHubScreen()),
    ).then((added) {
      if (added == true && mounted) refreshAllData();
    });
  }

  Widget buildMedicineCard(dynamic med, {required bool canInteract}) {
    final status = med["status"] ?? "pending";
    final medicine = med["medicineId"];
    final isPending = status == "pending";

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: canInteract && isPending && canCompleteForLog(med)
            ? () => showStatusDialog(med)
            : null,
        leading: Icon(
          Icons.medication,
          color: status == "taken"
              ? Colors.green
              : status == "skipped"
                  ? Colors.red
                  : const Color(0xFF0D47A1),
        ),
        title: Text(medicine?["name"]?.toString() ?? "Unknown Medicine"),
        subtitle: Text(
          "${medicine?["dose"] ?? ""} ${medicine?["units"] ?? ""} • "
          "${medicine?["frequency"] ?? ""}"
          "${isOnDemand(medicine?["frequency"]?.toString() ?? "") ? " (optional — skip if not needed)" : ""}\n"
          "Scheduled: ${formatDisplayDate(selectedDate)}",
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              med["scheduledTime"] != null
                  ? formatTime(med["scheduledTime"].toString())
                  : "--:--",
            ),
            const SizedBox(height: 4),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: status == "taken"
                    ? Colors.green
                    : status == "skipped"
                        ? Colors.red
                        : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTasksBody() {
    final upcoming = medicines
        .where((m) => (m["status"] ?? "pending") == "pending")
        .toList();

    final resolved = medicines
        .where((m) => m["status"] == "taken" || m["status"] == "skipped")
        .toList();

    final pendingAppointments = appointments
        .where((a) => (a["status"] ?? "pending") == "pending")
        .toList();
    final resolvedAppointments = appointments
        .where((a) {
          final s = a["status"]?.toString() ?? "";
          return s == "done" || s == "not_done";
        })
        .toList();

    final pendingActivities = activities
        .where((a) => (a["status"] ?? "pending") == "pending")
        .toList();
    final resolvedActivities = activities
        .where((a) {
          final s = a["status"]?.toString() ?? "";
          return s == "done" || s == "not_done";
        })
        .toList();

    final canInteract = isSelectedToday;

    final taskList = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, ${widget.userName} 👋",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  setState(() {
                    selectedDate =
                        selectedDate.subtract(const Duration(days: 1));
                  });
                  await refreshAllData();
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  canInteract
                      ? "Today • ${formatDisplayDate(selectedDate)}"
                      : formatDisplayDate(selectedDate),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: canInteract
                        ? const Color(0xFF0D47A1)
                        : Colors.grey[600],
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  setState(() {
                    selectedDate = selectedDate.add(const Duration(days: 1));
                  });
                  await refreshAllData();
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (!canInteract) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You can view tasks for ${formatDisplayDate(selectedDate)}, but you can only mark them complete on their scheduled date.",
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canInteract) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MedicineStreakCard(
                    label: "Medicine streak",
                    value: "$medicineStreak days",
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MedicineStreakCard(
                    label: "Best streak",
                    value: "$bestMedicineStreak days",
                    icon: Icons.emoji_events,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (pendingAppointments.isNotEmpty) ...[
            buildSectionTitle(
              isSelectedToday
                  ? "Appointments — pending"
                  : "Appointments — pending",
              Icons.local_hospital,
            ),
            ...pendingAppointments.map(
              (a) => buildAppointmentCard(a, canInteract: canInteract),
            ),
            const SizedBox(height: 16),
          ],
          if (resolvedAppointments.isNotEmpty) ...[
            buildSectionTitle("Appointments — done", Icons.event_available),
            ...resolvedAppointments.map(
              (a) => buildAppointmentCard(a, canInteract: false),
            ),
            const SizedBox(height: 16),
          ],
          if (pendingActivities.isNotEmpty) ...[
            buildSectionTitle(
              isSelectedToday ? "Activities — pending" : "Activities — pending",
              Icons.fitness_center,
            ),
            ...pendingActivities.map(
              (log) => buildActivityLogCard(log, canInteract: canInteract),
            ),
            const SizedBox(height: 16),
          ],
          if (resolvedActivities.isNotEmpty) ...[
            buildSectionTitle("Activities — done", Icons.check_circle_outline),
            ...resolvedActivities.map(
              (log) => buildActivityLogCard(log, canInteract: false),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            "Upcoming Tasks",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: canInteract ? Colors.black : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No pending medicines for this day.",
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...upcoming.map(
              (m) => buildMedicineCard(m, canInteract: canInteract),
            ),
          const SizedBox(height: 20),
          Text(
            "Resolved Tasks",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: canInteract ? Colors.black : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          if (resolved.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No taken or skipped medicines yet.",
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...resolved.map(
              (m) => buildMedicineCard(m, canInteract: canInteract),
            ),
        ],
      ),
    );

    return taskList;
  }

  Widget buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D47A1), size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWithConfirm({
    required String title,
    required String message,
    required Future<bool> Function() onDelete,
    required String successMessage,
  }) async {
    final confirmed = await confirmDeleteDialog(
      context,
      title: title,
      message: message,
    );
    if (!confirmed || !mounted) return;

    final ok = await onDelete();
    if (!mounted) return;

    if (ok) {
      AppSnackbar.success(context, successMessage);
      refreshAllData();
    } else {
      AppSnackbar.error(context, "Failed to delete");
    }
  }

  Widget buildAppointmentCard(
    dynamic apt, {
    required bool canInteract,
  }) {
    final time = apt["appointmentTime"]?.toString() ?? "";
    final name = apt["doctorName"]?.toString() ?? "Doctor";
    final status = apt["status"]?.toString() ?? "pending";
    final isPending = status == "pending";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: canInteract && isPending
            ? () => showAppointmentStatusDialog(apt)
            : null,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F2FD),
          child: Icon(
            Icons.local_hospital,
            color: statusColor(status),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${(apt["hospital"]?.toString() ?? "").isNotEmpty ? "${apt["hospital"]} • " : ""}"
          "${time.isNotEmpty ? formatTime(time) : ""}"
          "${(apt["notes"]?.toString() ?? "").isNotEmpty ? "\n${apt["notes"]}" : ""}",
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelectedToday && isPending)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteWithConfirm(
                  title: "Delete appointment?",
                  message:
                      "Do you want to delete the appointment with $name?",
                  onDelete: () => AppointmentService.delete(apt["_id"]),
                  successMessage: "Appointment deleted successfully",
                ),
              )
            else
              Text(
                status.replaceAll("_", " ").toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor(status),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildActivityLogCard(
    dynamic log, {
    required bool canInteract,
  }) {
    final act = log["activityId"];
    final name = act?["activityName"]?.toString() ?? "Activity";
    final freq = act?["frequency"]?.toString() ?? "Once Daily";
    final time = log["scheduledTime"]?.toString() ?? "";
    final status = log["status"]?.toString() ?? "pending";
    final isPending = status == "pending";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: canInteract && isPending
            ? () => showActivityStatusDialog(log)
            : null,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Icon(Icons.fitness_center, color: statusColor(status)),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "$freq • ${time.isNotEmpty ? formatTime(time) : ""}"
          "${isOnDemand(freq) ? " (optional)" : ""}"
          "${(act?["notes"]?.toString() ?? "").isNotEmpty ? "\n${act["notes"]}" : ""}",
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time.isNotEmpty ? formatTime(time) : "",
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              status.replaceAll("_", " ").toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor(status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCalendarBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await goToToday();
                setState(() => currentIndex = 0);
              },
              icon: const Icon(Icons.today, size: 18),
              label: const Text("Go to Today"),
            ),
            const Spacer(),
            if (!isSelectedToday)
              TextButton(
                onPressed: () {
                  setState(() => currentIndex = 0);
                },
                child: Text("Tasks: ${formatDisplayDate(selectedDate)}"),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          calendarFormat: CalendarFormat.month,
          onDaySelected: (selected, focused) async {
            setState(() {
              selectedDate = selected;
              focusedDay = focused;
              openedFromCalendar = true;
              currentIndex = 0;
            });
            await refreshAllData();
          },
          onPageChanged: (focused) async {
            setState(() => focusedDay = focused);
            await loadCalendarMarkers();
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Color(0xFF90CAF9),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Color(0xFF0D47A1),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Color(0xFF0D47A1),
              shape: BoxShape.circle,
            ),
          ),
          eventLoader: (day) {
            final key = MedicationLogService.formatDate(day);
            return markedDates.contains(key) ? [key] : [];
          },
        ),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Dates with a dot have scheduled medicines. Tap a date to view tasks.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading && currentIndex == 0) {
      body = const Center(child: CircularProgressIndicator());
    } else if (currentIndex == 2) {
      body = buildCalendarBody();
    } else if (currentIndex == 1) {
      body = ChartsTab(userId: userId);
    } else if (currentIndex == 3) {
      body = ProfileHubScreen(userName: widget.userName);
    } else {
      body = buildTasksBody();
    }

    return PopScope(
      canPop: !(currentIndex == 0 &&
          (openedFromCalendar || !isSelectedToday)),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        handleAppBarBack();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: buildAppBarLeading(),
        title: Row(
          children: const [
            Text("💊", style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              "Medimate",
              style: TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: openAddHub,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Add",
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF0D47A1),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "logout") logout();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "logout",
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text("Logout"),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                backgroundColor: const Color(0xFF0D47A1),
                child: Text(
                  getInitials(widget.userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: body,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          setState(() => currentIndex = index);

          if (index == 0) {
            await refreshAllData();
          } else if (index == 2) {
            await loadCalendarMarkers();
          }
        },
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: "Today"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Charts"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Calendar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    ),
    );
  }
}

class _MedicineStreakCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MedicineStreakCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D47A1), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
