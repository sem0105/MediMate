import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicineService {
  static const baseUrl = "http://10.0.2.2:5000/api/medicine";

  static Future<bool> addMedicine(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) return true;
    print("ADD MEDICINE ERROR: ${response.body}");
    return false;
  }

  static Future<bool> updateMedicine(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) return true;
    print("UPDATE MEDICINE ERROR: ${response.body}");
    return false;
  }

  static Future<bool> deleteMedicine(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));

    if (response.statusCode == 200) return true;
    print("DELETE MEDICINE ERROR: ${response.body}");
    return false;
  }

  static Future<List<dynamic>> getMedicines(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/user/$userId"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data["medicines"] ?? []);
    }

    return [];
  }

  static Future<Map<String, dynamic>?> getMedicineById(String id) async {
    final response = await http.get(Uri.parse("$baseUrl/detail/$id"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return Map<String, dynamic>.from(data["medicine"]);
      }
    }

    return null;
  }
}
