import 'package:flutter/material.dart';
import 'activity_form_screen.dart';
import 'add_medicine_screen.dart';
import 'appointment_form_screen.dart';
import 'my_medicines_screen.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';

class AddHubScreen extends StatelessWidget {
  const AddHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Add New"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: CenteredPageLayout(
        maxWidth: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Text(
            "What would you like to add?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Choose a category below",
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _AddOptionCard(
            icon: Icons.medication,
            title: "Medication",
            subtitle: "Add medicine with daily reminder times",
            color: const Color(0xFF0D47A1),
            onTap: () => _open(context, const AddMedicineScreen()),
          ),
          _AddOptionCard(
            icon: Icons.medical_services_outlined,
            title: "Manage Medicines",
            subtitle: "Edit or delete existing medications",
            color: const Color(0xFF1565C0),
            onTap: () => _open(context, const MyMedicinesScreen()),
          ),
          _AddOptionCard(
            icon: Icons.local_hospital,
            title: "Doctor Appointment",
            subtitle: "Doctor name, date, time, and notes",
            color: const Color(0xFF00838F),
            onTap: () => _open(context, const AppointmentFormScreen()),
          ),
          _AddOptionCard(
            icon: Icons.fitness_center,
            title: "Activity",
            subtitle: "Exercise or routine with frequency and time",
            color: Colors.green.shade700,
            onTap: () => _open(context, const ActivityFormScreen()),
          ),
        ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((added) {
      if (added == true) {
        Navigator.pop(context, true);
      }
    });
  }
}

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
