import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RiderChatScreen extends StatefulWidget {
  final String tripId;
  final String senderId;
  final String receiverId;
  final String customerName;

  const RiderChatScreen({
    Key? key,
    required this.tripId,
    required this.senderId,
    required this.receiverId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends State<RiderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  // FIXED: Using the correct backend URL
  final String apiUrl = 'https://torq-backend.onrender.com';
  
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _connectToSocket();
  }

  void _connectToSocket() {
    // Initialize WebSocket connection
    socket = IO.io(apiUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build()
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to Chat WebSocket');
      // Join the specific chat room for this trip
      socket.emit('joinRoom', widget.tripId);
    });

    // Listen for real-time incoming messages
    socket.on('newMessage', (data) {
      debugPrint('New message received: $data');
      if (mounted) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/notifications/chat/${widget.tripId}'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _messages = jsonDecode(response.body);
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final newMessage = {
      'tripId': widget.tripId,
      'senderId': widget.senderId,
      'receiverId': widget.receiverId,
      'content': text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 1. Emit the message to the WebSocket server so the other person gets it instantly
    socket.emit('sendMessage', {
      'tripId': widget.tripId,
      'message': newMessage,
    });

    // 2. Optimistically add it to the local UI
    if (mounted) {
      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();
    }

    // 3. Save to the database via HTTP (so history is preserved)
    try {
      await http.post(
        Uri.parse('$apiUrl/notifications/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tripId': widget.tripId,
          'senderId': widget.senderId,
          'receiverId': widget.receiverId,
          'content': text,
        }),
      );
    } catch (e) {
      debugPrint('Error saving message to DB: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(widget.customerName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Color(0xFFFCD34D)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == widget.senderId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFFCD34D) : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            msg['content'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.black : Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFFCD34D),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}