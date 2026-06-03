import 'package:flutter/material.dart';
import 'medicine_form_screen.dart';

/// Legacy route wrapper — use [MedicineFormScreen] directly.
class AddMedicineScreen extends StatelessWidget {
  const AddMedicineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MedicineFormScreen();
  }
}
