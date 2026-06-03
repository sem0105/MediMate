import 'package:flutter/material.dart';
import 'update_profile_setup.dart';
import '../widgets/centered_form_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  double? bmi;

  void calculateBMI() {
    final h = double.tryParse(heightController.text) ?? 0;
    final w = double.tryParse(weightController.text) ?? 0;

    if (h == 0 || w == 0) return;

    final result = w / ((h / 100) * (h / 100));

    setState(() {
      bmi = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: CenteredFormLayout(
        child: centeredFormCard(
          children: [
            // 🔹 UPDATE PROFILE ENTRY POINT
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Update Profile"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpdateProfileScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "BMI Calculator",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Height (cm)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Weight (kg)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: calculateBMI,
              child: const Text("Calculate BMI"),
            ),

            const SizedBox(height: 10),

            if (bmi != null)
              Text(
                "Your BMI: ${bmi!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
