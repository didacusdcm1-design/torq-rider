import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://torq-backend.onrender.com';

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        final prefs = await SharedPreferences.getInstance();
        
        // 1. Save the JWT Token
        await prefs.setString('jwt_token', data['access_token']);
        
        // 2. Save the User ID (THE FIX FOR INBOX)
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setString('userId', data['user']['id'].toString());
        }
        
        return {'success': true, 'user': data['user']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  static Future<bool> toggleOnlineStatus(bool isOnline) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/riders/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isOnline': isOnline}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
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

  static Future<List<dynamic>> getRiderHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trips/rider/history'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> acceptTrip(String tripId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/trips/$tripId/accept'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateTripStatus(String tripId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/trips/$tripId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Fixed to return a Map (because home_screen.dart checks result['success'])
  static Future<Map<String, dynamic>> completeTrip(String tripId, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': response.statusCode == 200 ? 'Trip completed' : 'Failed to complete trip'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Fixed to take 4 arguments (matching home_screen.dart)
  static Future<Map<String, dynamic>> cancelTrip(String tripId, String cancelledBy, String reason, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/$tripId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cancelledBy': cancelledBy,
          'reason': reason,
          'description': description,
        }),
      );
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': response.statusCode == 200 ? 'Trip cancelled' : 'Failed to cancel trip'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Fixed to use named arguments (matching registration_screen.dart)
  static Future<Map<String, dynamic>> submitRegistration({
    required String fullName,
    required String phone,
    required String nationalId,
    // Add any other fields your registration screen passes (e.g., email, password)
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/rider'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'phone': phone,
          'nationalId': nationalId,
        }),
      );
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': response.statusCode == 200 ? 'Registration successful' : 'Registration failed'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}