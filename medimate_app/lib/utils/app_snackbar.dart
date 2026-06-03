import 'package:flutter/material.dart';

class AppSnackbar {
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade700);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red.shade700);
  }

  static void _show(BuildContext context, String message, Color bg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
