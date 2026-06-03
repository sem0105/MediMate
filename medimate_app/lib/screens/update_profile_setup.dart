import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_back_button.dart';
import '../widgets/centered_form_layout.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  bool loading = false;
  bool fetchingProfile = true;

  String selectedGender = "Male";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/auth/profile"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        final user = data["user"];

        setState(() {
          nameController.text = user["name"] ?? "";
          ageController.text = user["age"]?.toString() ?? "";
          heightController.text = user["height"]?.toString() ?? "";
          weightController.text = user["weight"]?.toString() ?? "";
          selectedGender = user["gender"] ?? "Male";

          fetchingProfile = false;
        });
      } else {
        setState(() {
          fetchingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        fetchingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateProfile() async {
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse(
          "http://10.0.2.2:5000/api/auth/update-profile",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "age": int.tryParse(ageController.text) ?? 0,
          "gender": selectedGender,
          "height": double.tryParse(heightController.text) ?? 0,
          "weight": double.tryParse(weightController.text) ?? 0,
        }),
      );

      setState(() {
        loading = false;
      });

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // After updating profile, navigate to home but keep the
        // profile screens in the back stack so the user can go back.
        Navigator.pushNamed(
          context,
          "/home",
          arguments: nameController.text.trim().isEmpty
              ? "User"
              : nameController.text.trim(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Failed to update profile",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget textField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF3F6FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fetchingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Update Profile",
          style: TextStyle(
            color: Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const AppBackButton(color: Color(0xFF0D47A1)),
      ),
      body: CenteredFormLayout(
        child: centeredFormCard(
          children: [
            const Text(
              "💊 Update Your Profile",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            textField(nameController, "Name"),
            textField(ageController, "Age"),
            const SizedBox(height: 10),
            const Text(
              "Gender",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Radio(
                      value: "Male",
                      groupValue: selectedGender,
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value.toString();
                        });
                      },
                    ),
                    const Text("Male"),
                  ],
                ),
                Row(
                  children: [
                    Radio(
                      value: "Female",
                      groupValue: selectedGender,
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value.toString();
                        });
                      },
                    ),
                    const Text("Female"),
                  ],
                ),
                Row(
                  children: [
                    Radio(
                      value: "Other",
                      groupValue: selectedGender,
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value.toString();
                        });
                      },
                    ),
                    const Text("Other"),
                  ],
                ),
              ],
            ),
            textField(heightController, "Height (cm)"),
            textField(weightController, "Weight (kg)"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                ),
                onPressed: loading ? null : updateProfile,
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Update Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
