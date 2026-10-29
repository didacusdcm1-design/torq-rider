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
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to update status'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<List<dynamic>> getActiveTrips() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trips/rider/active'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitRegistration({
    required String fullName,
    required String phone,
    required String nationalId,
    required String licenseNumber,
    required String emergencyContact,
    required String bikeMake,
    required String bikeModel,
    required String bikeColor,
    required String bikeReg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/riders/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'phone': phone,
          'nationalId': nationalId,
          'licenseNumber': licenseNumber,
          'emergencyContact': emergencyContact,
          'bikeMake': bikeMake,
          'bikeModel': bikeModel,
          'bikeColor': bikeColor,
          'bikeReg': bikeReg,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
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
  static Future<Map<String, dynamic>> completeTrip(String tripId, String pin) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/complete/$tripId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Invalid PIN'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
    static Future<bool> updateTripStatus(String tripId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/status/$tripId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode != 200) {
        print("STATUS UPDATE FAILED: ${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("STATUS UPDATE ERROR: $e");
      return false;
    }
  }
}

