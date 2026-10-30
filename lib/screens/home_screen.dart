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
          const SnackBar(content: Text("Failed to update status."), backgroundColor: Colors.red),
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
              if (result['success'] == true) {
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

  void _showCancellationDialog() {
    String? selectedReason;
    final noteController = TextEditingController();
    final riderReasons = [
      "Customer is not at the pickup location.",
      "Customer is not responding to calls or messages.",
      "Customer requested cancellation.",
      "Incorrect pickup location.",
      "Incorrect destination.",
      "Motorcycle mechanical problem.",
      "Motorcycle accident or safety concern.",
      "Rider emergency or personal reason.",
      "Excessive waiting time.",
      "Unable to reach the customer.",
      "Other reason."
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Cancel This Trip?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Please select a reason for cancelling this trip. Your cancellation will be recorded in the TORQ system.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ...riderReasons.map((reason) => RadioListTile<String>(
                    title: Text(reason, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFFCD34D),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) => setDialogState(() => selectedReason = val),
                  )),
                  if (selectedReason == "Other reason.") ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Please explain...",
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Keep Trip", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  if (selectedReason == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a reason."), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  final result = await ApiService.cancelTrip(
                    _activeTrip!['id'], 
                    'RIDER', 
                    selectedReason!, 
                    noteController.text
                  );
                  if (mounted) {
                    setState(() => _isLoading = false);
                    if (result['success'] == true) {
                      setState(() => _activeTrip = null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Trip Cancelled successfully."), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to cancel trip."), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text("Confirm Cancellation", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.electric_bolt, color: Color(0xFFFCD34D), size: 24),
              SizedBox(width: 8),
              Text("TORQ", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _activeTrip != null ? const Color(0xFFFCD34D) : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _activeTrip != null ? "ON TRIP" : "ONLINE",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(_isOnline ? Icons.check_circle : Icons.power_settings_new, size: 100, color: _isOnline ? const Color(0xFFFCD34D) : Colors.grey),
          const SizedBox(height: 24),
          Text(_isOnline ? "You are ONLINE" : "You are OFFLINE", textAlign: TextAlign.center, style: TextStyle(color: _isOnline ? Colors.white : Colors.grey, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_isOnline ? "Waiting for trip requests..." : "Go online to start accepting trips.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
              child: Center(child: Text(_isOnline ? "GO OFFLINE" : "GO ONLINE", style: TextStyle(color: _isOnline ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripState() {
    final status = _activeTrip!['status'] as String;
    String buttonText = "";
    VoidCallback? onPressed;
    IconData icon = Icons.navigation;
    String title = "";

    if (status == 'ACCEPTED') {
      title = "New Trip Request";
      buttonText = "ACCEPT TRIP";
      onPressed = () async {
        await ApiService.acceptTrip(_activeTrip!['id']);
        _checkForTrips();
      };
    } else if (status == 'IN_PROGRESS') {
      title = "Navigating to Pickup";
      buttonText = "I HAVE ARRIVED";
      icon = Icons.navigation;
      onPressed = () => _updateTripStatus('ARRIVED_AT_PICKUP');
    } else if (status == 'ARRIVED_AT_PICKUP') {
      title = "At Pickup Location";
      buttonText = "START TRIP";
      icon = Icons.location_on;
      onPressed = () => _updateTripStatus('IN_PROGRESS_DEST');
    } else if (status == 'IN_PROGRESS_DEST') {
      title = "Navigating to Destination";
      buttonText = "COMPLETE TRIP";
      icon = Icons.flag;
      onPressed = _showCompleteDialog;
    } else {
       title = "Trip Status Unknown";
       buttonText = "RETURN";
       onPressed = () => _checkForTrips();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFFFCD34D), size: 28),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: Colors.grey, height: 30),
                const Text("Customer:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(_activeTrip!['customer']?['firstName'] ?? "Customer", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                const Text("Pickup Location:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Lat: ${_activeTrip!['pickupLat']}, Lng: ${_activeTrip!['pickupLng']}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 12),
                const Text("Destination:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Lat: ${_activeTrip!['dropoffLat']}, Lng: ${_activeTrip!['dropoffLng']}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Fare: KES ${_activeTrip!['estimatedFare']}", style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("PIN: ${_activeTrip!['pickupPin'] ?? "----"}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ]
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.black),
              label: Text(buttonText, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCD34D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (status == 'ACCEPTED' || status == 'IN_PROGRESS' || status == 'ARRIVED_AT_PICKUP')
            TextButton(
              onPressed: _showCancellationDialog,
              child: const Text("Cancel Trip", style: TextStyle(color: Colors.redAccent, fontSize: 14)),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
                : _activeTrip != null 
                  ? _buildActiveTripState() 
                  : _buildIdleState(),
            ),
          ],
        ),
      ),
    );
  }
}// Force rebuild 10/30/2026 14:03:34
