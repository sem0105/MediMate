import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../models/medicine_dashboard_model.dart';
import '../../widgets/dashboard/today_medicines_card.dart';
import '../../widgets/app_back_button.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<MedicineDashboardModel>> medicines;

  @override
  void initState() {
    super.initState();
    medicines = DashboardService.getTodayMedicines(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: medicines,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return TodayMedicinesCard(
              medicines: snapshot.data!,
            );
          },
        ),
      ),
    );
  }
}
