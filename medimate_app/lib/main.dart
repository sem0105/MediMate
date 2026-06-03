import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'screens/profile_setup.dart';
import 'screens/update_profile_setup.dart';

void main() {
  print("APP STARTED");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌿 Theme applied globally
      theme: AppTheme.lightTheme,

      // 🚀 Start screen
      initialRoute: "/login",

      // 📍 Routes
      routes: {
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/home": (context) {
          final name = ModalRoute.of(context)!.settings.arguments as String;

          return HomeScreen(userName: name);
        },
        "/profileSetup": (context) => const ProfileScreen(),
        "/updateProfile": (context) => const UpdateProfileScreen(),
      },
    );
  }
}
