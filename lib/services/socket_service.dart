import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  void connect(String userId) {
    if (socket != null && socket!.connected) return;

    socket = IO.io('https://torq-backend.onrender.com', 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('? Connected to WebSocket');
      socket!.emit('joinUserRoom', userId);
    });

    socket!.on('newNotification', (data) {
      print('?? Real-time Notification: $data');
    });

    socket!.onDisconnect((_) => print('? Disconnected'));
  }

  void joinTripRoom(String tripId) {
    if (socket != null && socket!.connected) {
      socket!.emit('joinRoom', tripId);
    }
  }

  void sendChatMessage(String tripId, String message) {
    if (socket != null && socket!.connected) {
      socket!.emit('sendMessage', {
        'tripId': tripId,
        'message': message,
      });
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}