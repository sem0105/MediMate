import 'package:flutter/material.dart';
import '../utils/app_snackbar.dart';
import '../utils/frequency_utils.dart';

class ReminderTimesSection extends StatelessWidget {
  final List<TimeOfDay?> times;
  final String frequency;
  final ValueChanged<List<TimeOfDay?>> onTimesChanged;

  const ReminderTimesSection({
    super.key,
    required this.times,
    required this.frequency,
    required this.onTimesChanged,
  });

  Future<void> pickTime(BuildContext context, int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: times[index] ?? TimeOfDay.now(),
    );
    if (picked != null) {
      final updated = List<TimeOfDay?>.from(times);
      updated[index] = picked;

      final count = requiredReminderCount(frequency);
      if (hasDuplicateReminderTimes(updated, count)) {
        if (context.mounted) {
          AppSnackbar.error(
            context,
            "This time is already selected — pick a different time",
          );
        }
        return;
      }

      onTimesChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = requiredReminderCount(frequency);
    final onDemand = isOnDemand(frequency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onDemand)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              "Shown every day — you can skip when not needed.",
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          )
        else if (count > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "Pick $count reminder times for each day",
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ...List.generate(count, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => pickTime(context, index),
                icon: const Icon(Icons.access_time),
                label: Text(
                  times.length > index && times[index] != null
                      ? "${reminderTimeLabel(index, count)}: ${times[index]!.format(context)}"
                      : reminderTimeLabel(index, count),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
