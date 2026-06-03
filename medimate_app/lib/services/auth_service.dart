import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 💾 Save login data
  static Future<void> saveLoginData(String token, String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("token", token);
    await prefs.setString("userId", userId);
    await prefs.setString("email", email);
  }

  // 🔑 Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // 👤 Get userId
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  // 🚪 Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}