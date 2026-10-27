import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TripService {
  final String baseUrl = 'https://torq-backend.onrender.com';
  late IO.Socket socket;

  void connectWebSocket(Function(dynamic) onTripUpdate) {
    socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());
    socket.connect();
    socket.on('tripUpdate', (data) => onTripUpdate(data));
  }

  Future<List<dynamic>> getPendingTrips(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/trips/pending'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  // This now returns the exact error message from the backend
  Future<String?> updateStatus(String token, String tripId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/trips/status/$tripId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return null; // Success
    } else {
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Failed to update status';
    }
  }

  // We need to add this specific method just for accepting rides to catch the 403
  Future<String?> acceptTrip(String token, String tripId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/trips/accept/$tripId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return null; // Success
    } else {
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Failed to accept trip';
    }
  }

  Future<bool> updateFullProfile(String token, String fullName, String dob, String idNumber, String emergencyContact, String reg, String make, String model, String insurance, String idDoc, String licenseDoc, String insuranceDoc, String selfieDoc) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/rider/full-profile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName, 'dateOfBirth': dob, 'nationalIdNumber': idNumber, 'emergencyContact': emergencyContact,
        'motorcycleReg': reg, 'motorcycleMake': make, 'motorcycleModel': model, 'insuranceExpiry': insurance,
        'idDocumentUrl': idDoc, 'licenseDocumentUrl': licenseDoc, 'insuranceDocumentUrl': insuranceDoc, 'selfieUrl': selfieDoc,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}