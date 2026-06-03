import 'package:flutter/material.dart';
import 'bmi_screen.dart';
import 'my_medicines_screen.dart';
import 'profile_measurements_screen.dart';
import 'profile_water_screen.dart';
import 'update_profile_setup.dart';

class ProfileHubScreen extends StatelessWidget {
  final String userName;

  const ProfileHubScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $userName",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 24),
          _ProfileOptionCard(
            icon: Icons.monitor_weight_outlined,
            title: "View BMI",
            subtitle: "See your body mass index and health category",
            color: const Color(0xFF0D47A1),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BmiScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _ProfileOptionCard(
            icon: Icons.medication_outlined,
            title: "Manage Medicines",
            subtitle: "Edit or delete medications in your treatment plan",
            color: const Color(0xFF1976D2),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyMedicinesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _ProfileOptionCard(
            icon: Icons.monitor_heart_outlined,
            title: "My Measurements",
            subtitle: "Blood pressure, weight, heart rate, and health vitals",
            color: Colors.red.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileMeasurementsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _ProfileOptionCard(
            icon: Icons.water_drop_outlined,
            title: "Water Intake",
            subtitle: "Track daily hydration — add, edit, or remove entries",
            color: const Color(0xFF0277BD),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileWaterScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _ProfileOptionCard(
            icon: Icons.edit_outlined,
            title: "Update Profile",
            subtitle: "Change your name, age, height, weight, and gender",
            color: const Color(0xFF1565C0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
