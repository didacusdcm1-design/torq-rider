import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  final String apiUrl = 'https://torq-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenToRealTimeNotifications();
  }

  // Listen for WebSocket events to auto-update the UI
  void _listenToRealTimeNotifications() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.on('newNotification', (data) {
        debugPrint('Real-time notification received in Inbox!');
        _loadNotifications(); // Reload the list from DB when a new one arrives
      });
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      // Make sure 'userId' matches exactly what you saved in your login screen!
      final String? userId = prefs.getString('userId') ?? prefs.getString('user_id');

      if (userId == null) {
        debugPrint('No userId found in SharedPreferences.');
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(Uri.parse('$apiUrl/notifications/user/$userId'));

      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("Inbox", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFFFCD34D)), onPressed: _loadNotifications)
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
        : _notifications.isEmpty
          ? const Center(child: Text("No messages yet.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final alert = _notifications[index];
                final isRead = alert['isRead'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: isRead ? Colors.grey : const Color(0xFFFCD34D), width: 4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey : const Color(0xFFFCD34D),
                        size: 28
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['title'] ?? 'TORQ Update',
                              style: TextStyle(
                                color: isRead ? Colors.grey : const Color(0xFFFCD34D),
                                fontSize: 14,
                                fontWeight: FontWeight.bold
                              )
                            ),
                            const SizedBox(height: 6),
                            Text(
                              alert['message'] ?? 'Notification',
                              style: TextStyle(
                                color: isRead ? Colors.grey : Colors.white,
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w500
                              )
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateTime.parse(alert['createdAt']).toLocal().toString().substring(0, 16),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}