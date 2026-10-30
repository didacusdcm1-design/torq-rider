import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://torq-backend.onrender.com';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/riders/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
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
    String? licenseDocUrl,
    String? insuranceDocUrl,
    String? bikePhotoUrl,
    String? selfieUrl,
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
          'licenseDocUrl': licenseDocUrl,
          'insuranceDocUrl': insuranceDocUrl,
          'bikePhotoUrl': bikePhotoUrl,
          'selfieUrl': selfieUrl,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'temporaryPassword': data['temporaryPassword']};
      }
      return {'success': false, 'message': 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
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

  static Future<bool> cancelTrip(String tripId, String cancelledBy, String reason, String note) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/cancel/$tripId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cancelledBy': cancelledBy, 'reason': reason, 'note': note}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> rateTrip(String tripId, int rating) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/$tripId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rating': rating}),
      );
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': 'Failed to submit rating'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}