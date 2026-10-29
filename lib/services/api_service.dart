import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://torq-backend.onrender.com';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, dynamic>> toggleOnlineStatus(bool isOnline) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/riders/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isOnline': isOnline}),
      );
      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<List<dynamic>> getActiveTrips() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trips/rider/active'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> acceptTrip(String tripId) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/trips/accept/$tripId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateTripStatus(String tripId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/status/$tripId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> completeTrip(String tripId, String pin) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/complete/$tripId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid PIN'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}