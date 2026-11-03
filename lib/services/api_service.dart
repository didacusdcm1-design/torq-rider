import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Replace with your actual backend URL if it changes
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
        
        // 2. Save the User ID (THE FIX)
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
}