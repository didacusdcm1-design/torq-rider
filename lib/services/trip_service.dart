import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TripService {
  final String baseUrl = 'https://torq-backend.onrender.com';
  late IO.Socket socket;

  void connectWebSocket(Function(dynamic) onTripUpdate) {
    socket = IO.io(baseUrl, IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build());
    socket.connect();
    socket.on('tripUpdate', (data) => onTripUpdate(data));
  }

  Future<List<dynamic>> getPendingTrips(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/trips/pending'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<String?> updateStatus(String token, String tripId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/trips/status/$tripId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) return null;
    final error = jsonDecode(response.body);
    return error['message'] ?? 'Failed to update status';
  }

  Future<String?> acceptTrip(String token, String tripId) async {
    final response = await http.patch(Uri.parse('$baseUrl/trips/accept/$tripId'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
    if (response.statusCode == 200) return null;
    final error = jsonDecode(response.body);
    return error['message'] ?? 'Failed to accept trip';
  }

  // NEW: Upload File to Backend
  Future<String?> uploadFile(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/trips/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseData)['url'];
      }
      return null;
    } catch (e) {
      return null;
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
