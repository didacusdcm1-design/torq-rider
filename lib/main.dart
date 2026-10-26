import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/trip_service.dart';

void main() { runApp(const TorqRiderApp()); }

class TorqRiderApp extends StatelessWidget {
  const TorqRiderApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TORQ Rider', debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)), useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'rider@torq.com');
  final _passwordController = TextEditingController(text: 'Test@123');
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final token = await _authService.login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);
    if (token != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(token: token)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Failed'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.drive_eta, size: 80, color: Color(0xFF059669)),
            const SizedBox(height: 20),
            const Text('Rider Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 30),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _handleLogin, child: const Text('Go Online')),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({super.key, required this.token});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _tripService = TripService();
  List<dynamic> _trips = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchTrips(); }

  void _fetchTrips() async {
    setState(() => _isLoading = true);
    final trips = await _tripService.getPendingTrips(widget.token);
    setState(() { _trips = trips; _isLoading = false; });
  }

  void _updateStatus(String tripId, String status) async {
    final success = await _tripService.updateStatus(widget.token, tripId, status);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status'), backgroundColor: Colors.green));
      _fetchTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride Requests'), backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTrips)],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _trips.isEmpty ? const Center(child: Text('No trips.')) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          final status = trip['status'];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Trip #${trip['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)), Chip(label: Text(status))]),
                  const SizedBox(height: 8),
                  Text('Pickup: ${trip['pickupLat']}, ${trip['pickupLng']}'),
                  Text('Dropoff: ${trip['dropoffLat']}, ${trip['dropoffLng']}'),
                  const SizedBox(height: 16),
                  if (status == 'REQUESTED') SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _updateStatus(trip['id'], 'ACCEPTED'), child: const Text('Accept Ride'))),
                  if (status == 'ACCEPTED') SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => _updateStatus(trip['id'], 'ARRIVED'), child: const Text('Arrived at Pickup'))),
                  if (status == 'ARRIVED') SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: () => _updateStatus(trip['id'], 'IN_PROGRESS'), child: const Text('Start Trip'))),
                  if (status == 'IN_PROGRESS') SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _updateStatus(trip['id'], 'COMPLETED'), child: const Text('Complete Trip'))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
