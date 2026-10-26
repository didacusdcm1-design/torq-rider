import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TripService {
  final String baseUrl = 'https://torq-backend.onrender.com';
  late IO.Socket socket;

  void connectWebSocket(Function onNewTrip) {
    socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());
      
    socket.connect();
    
    socket.on('newTrip', (data) {
      print('New Trip Request Received!');
      onNewTrip();
    });
  }

  Future<List<dynamic>> getPendingTrips(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/trips/pending'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<bool> updateStatus(String token, String tripId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/trips/status/$tripId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateRiderProfile(String token, String fullName, String motorcycleReg, String emergencyContact) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/rider/profile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'motorcycleReg': motorcycleReg,
        'emergencyContact': emergencyContact,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}