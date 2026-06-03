import 'package:flutter/material.dart';
import '../../../models/medicine_dashboard_model.dart';

class TodayMedicinesCard extends StatelessWidget {
  final List<MedicineDashboardModel> medicines;

  const TodayMedicinesCard({super.key, required this.medicines});

  Color _statusColor(String status) {
    switch (status) {
      case "taken":
        return Colors.green;
      case "skipped":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "taken":
        return Icons.check_circle;
      case "skipped":
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "💊 Today Medicines",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...medicines.map((med) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _statusIcon(med.status),
                color: _statusColor(med.status),
              ),
              title: Text(
                med.medicineName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "${med.dosage} ${med.unit} • ${med.time}",
              ),
              trailing: Text(
                med.status.toUpperCase(),
                style: TextStyle(
                  color: _statusColor(med.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}