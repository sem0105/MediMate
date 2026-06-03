import 'package:flutter/material.dart';

/// Back control for screens that may not get an automatic AppBar back arrow.
class AppBackButton extends StatelessWidget {
  final Color? color;

  const AppBackButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color ?? Colors.white),
      tooltip: "Back",
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
