import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = true;
  bool _isLoading = false;
  Map<String, dynamic>? _activeTrip;

  @override
  void initState() {
    super.initState();
    _checkForTrips();
  }

  Future<void> _checkForTrips() async {
    final trips = await ApiService.getActiveTrips();
    if (mounted) {
      if (trips.isNotEmpty) {
        setState(() {
          _activeTrip = trips.first;
          _isOnline = true;
        });
      } else {
        setState(() {
          _activeTrip = null;
        });
      }
    }
  }

  Future<void> _updateTripStatus(String newStatus) async {
    if (_activeTrip == null) return;
    
    setState(() => _isLoading = true);
    final success = await ApiService.updateTripStatus(_activeTrip!['id'], newStatus);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() => _activeTrip!['status'] = newStatus);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update status. Try again."), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    if (_activeTrip != null) return;
    setState(() => _isLoading = true);
    await ApiService.toggleOnlineStatus(value);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isOnline = value;
      });
    }
  }

  void _showCompleteDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Enter Customer PIN", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: "----", hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCD34D)),
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.completeTrip(_activeTrip!['id'], pinController.text);
              if (result['success']) {
                setState(() => _activeTrip = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Trip Completed Successfully!"), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed: ${result['message']}"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Complete", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
          : _buildCurrentState(),
      ),
    );
  }

  Widget _buildCurrentState() {
    if (_activeTrip == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isOnline ? Icons.check_circle : Icons.power_settings_new, size: 100, color: _isOnline ? const Color(0xFFFCD34D) : Colors.grey),
            const SizedBox(height: 24),
            Text(_isOnline ? "You are ONLINE" : "You are OFFLINE", style: TextStyle(color: _isOnline ? Colors.white : Colors.grey, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 64),
            GestureDetector(
              onTap: () => _toggleOnlineStatus(!_isOnline),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFFFCD34D) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: _isOnline ? const Color(0xFFFCD34D) : Colors.grey, width: 2),
                ),
                child: Center(child: Text(_isOnline ? "GO OFFLINE" : "GO ONLINE", style: TextStyle(color: _isOnline ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      );
    }

    final status = _activeTrip!['status'] as String;

    if (status == 'ACCEPTED') {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFCD34D), width: 2)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFFFCD34D), size: 48),
              const SizedBox(height: 16),
              const Text("NEW TRIP REQUEST", style: TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text("Fare: KES ${_activeTrip!['estimatedFare']}", style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ApiService.acceptTrip(_activeTrip!['id']);
                    _checkForTrips();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCD34D), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("ACCEPT TRIP", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'IN_PROGRESS') {
      return _buildTripScreen("Navigating to Pickup", Icons.navigation, "I HAVE ARRIVED", () => _updateTripStatus('ARRIVED_AT_PICKUP'));
    }

    if (status == 'ARRIVED_AT_PICKUP') {
      return _buildTripScreen("At Pickup Location", Icons.location_on, "START TRIP", () => _updateTripStatus('IN_PROGRESS_DEST'));
    }

    if (status == 'IN_PROGRESS_DEST') {
      return _buildTripScreen("Navigating to Destination", Icons.flag, "COMPLETE TRIP", _showCompleteDialog);
    }

    return const Center(child: Text("Trip Completed. Loading...", style: TextStyle(color: Colors.white)));
  }

  Widget _buildTripScreen(String title, IconData icon, String buttonText, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(icon, color: const Color(0xFFFCD34D), size: 80),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(height: 200, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(16))),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCD34D), padding: const EdgeInsets.symmetric(vertical: 20)),
              child: Text(buttonText, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}// Force rebuild 10/30/2026 00:52:29
