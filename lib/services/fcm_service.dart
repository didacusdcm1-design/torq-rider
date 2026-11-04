import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // 2. Get the Token
    String? token = await _fcm.getToken();
    debugPrint("FCM Token: $token");

    if (token != null) {
      _saveTokenToBackend(token);
    }

    // 3. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToBackend(newToken);
    });

    // 4. Handle messages when app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message in the foreground!');
      debugPrint('Message data: ${message.data}');
      
      if (message.notification != null) {
        debugPrint('Notification: ${message.notification!.title}');
      }
    });
  }

  Future<void> _saveTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId') ?? prefs.getString('user_id');

    if (userId == null) {
      debugPrint("No userId found, cannot save FCM token.");
      return;
    }

    try {
      await http.post(
        Uri.parse('https://torq-backend.onrender.com/notifications/save-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'token': token,
        }),
      );
      debugPrint('? Token saved to backend');
    } catch (e) {
      debugPrint('? Failed to save token: $e');
    }
  }
}