import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  bool loading = true;
  double? bmi;
  String? category;
  String? userName;

  @override
  void initState() {
    super.initState();
    loadBmi();
  }

  String bmiCategory(double value) {
    if (value < 18.5) return "Underweight";
    if (value < 25) return "Normal";
    if (value < 30) return "Overweight";
    return "Obese";
  }

  Color categoryColor(double value) {
    if (value < 18.5) return Colors.orange;
    if (value < 25) return Colors.green;
    if (value < 30) return Colors.orange;
    return Colors.red;
  }

  Future<void> loadBmi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/auth/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final user = data["user"];
          final height =
              double.tryParse(user["height"]?.toString() ?? "0") ?? 0;
          final weight =
              double.tryParse(user["weight"]?.toString() ?? "0") ?? 0;

          double? calculated;
          if (height > 0 && weight > 0) {
            calculated = weight / ((height / 100) * (height / 100));
          }

          setState(() {
            userName = user["name"]?.toString();
            bmi = calculated;
            category = calculated != null ? bmiCategory(calculated) : null;
            loading = false;
          });
          return;
        }
      }
    } catch (e) {
      print("BMI load error: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Your BMI"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CenteredPageLayout(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: bmi == null
                        ? Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "BMI not available",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Add your height and weight in Update Profile to calculate BMI.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              if (userName != null)
                                Text(
                                  userName!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                bmi!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor(bmi!),
                                ),
                              ),
                              const Text(
                                "Body Mass Index",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor(bmi!)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category!,
                                  style: TextStyle(
                                    color: categoryColor(bmi!),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (bmi != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "BMI ranges:\n• Under 18.5 — Underweight\n• 18.5–24.9 — Normal\n• 25–29.9 — Overweight\n• 30+ — Obese",
                        style: TextStyle(height: 1.6),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
