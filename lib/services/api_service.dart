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
        await prefs.setString('jwt_token', data['access_token']);
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setString('userId', data['user']['id'].toString());
        }
        return {'success': true, 'user': data['user']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<bool> toggleOnlineStatus(bool isOnline) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/riders/status'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'isOnline': isOnline}));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getActiveTrips() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trips/rider/active'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getRiderHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trips/rider/history'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  static Future<bool> acceptTrip(String tripId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/trips/$tripId/accept'));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> updateTripStatus(String tripId, String status) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/trips/$tripId/status'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'status': status}));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> completeTrip(String tripId, String pin) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/trips/$tripId/complete'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'pin': pin}));
      return {'success': response.statusCode == 200, 'message': 'Done'};
    } catch (e) { return {'success': false, 'message': 'Error'}; }
  }

  static Future<Map<String, dynamic>> cancelTrip(String tripId, String cancelledBy, String reason, String description) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/trips/$tripId/cancel'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'cancelledBy': cancelledBy, 'reason': reason, 'description': description}));
      return {'success': response.statusCode == 200, 'message': 'Done'};
    } catch (e) { return {'success': false, 'message': 'Error'}; }
  }

  // DYNAMIC REGISTRATION: Accepts any fields the UI passes
  static Future<Map<String, dynamic>> submitRegistration(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/rider'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return {'success': response.statusCode == 200 || response.statusCode == 201, 'message': 'Done'};
    } catch (e) { return {'success': false, 'message': 'Error'}; }
  }
}