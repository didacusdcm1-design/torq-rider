import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/trip_service.dart';

void main() {
  runApp(const TorqRiderApp());
}

class TorqRiderApp extends StatelessWidget {
  const TorqRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TORQ Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B121B),
          primary: const Color(0xFF0B121B),
          secondary: const Color(0xFFFFBD19),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleSubmit() async {
    setState(() => _isLoading = true);
    String? token;

    if (_isLogin) {
      token = await _authService.login(_emailController.text, _passwordController.text);
    } else {
      token = await _authService.register(_emailController.text, _passwordController.text);
    }

    setState(() => _isLoading = false);

    if (token != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigation(token: token!)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Login Failed' : 'Registration Failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.two_wheeler, size: 80, color: Color(0xFFFFBD19)),
              const SizedBox(height: 10),
              const Text('TORQ Rider', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0B121B))),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 30),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFBD19), foregroundColor: Colors.black),
                    onPressed: _handleSubmit, 
                    child: Text(_isLogin ? 'Go Online' : 'Register as Rider', style: const TextStyle(fontWeight: FontWeight.bold))
                  ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? "Don't have an account? Register here" : "Already have an account? Login here", style: const TextStyle(color: Color(0xFF0B121B))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String token;
  const MainNavigation({super.key, required this.token});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(token: widget.token),
      const TripsTab(),
      const EarningsTab(),
      const InboxTab(),
      AccountTab(token: widget.token),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0B121B),
        indicatorColor: const Color(0xFFFFBD19),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard, color: Colors.white), selectedIcon: Icon(Icons.dashboard, color: Color(0xFF0B121B)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route, color: Colors.white), selectedIcon: Icon(Icons.route, color: Color(0xFF0B121B)), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet, color: Colors.white), selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF0B121B)), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline, color: Colors.white), selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF0B121B)), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person_outline, color: Colors.white), selectedIcon: Icon(Icons.person, color: Color(0xFF0B121B)), label: 'Account'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final String token;
  const HomeTab({super.key, required this.token});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _tripService = TripService();
  List<dynamic> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

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
        title: const Text('TORQ Driver', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0B121B),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTrips)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(child: Text('Waiting for ride requests...'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    final status = trip['status'];
                    final fare = double.tryParse(trip['estimatedFare']?.toString() ?? '0.0') ?? 0.0;
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trip #${trip['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Pickup: ${trip['pickupLat']}, ${trip['pickupLng']}'),
                            Text('Dropoff: ${trip['dropoffLat']}, ${trip['dropoffLng']}'),
                            const SizedBox(height: 16),
                            Text('Earnings: KSh ${fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                            const SizedBox(height: 16),
                            
                            if (status == 'REQUESTED')
                              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B121B), foregroundColor: Colors.white), onPressed: () => _updateStatus(trip['id'], 'ACCEPTED'), child: const Text('Accept Ride'))),
                            if (status == 'ACCEPTED')
                              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), onPressed: () => _updateStatus(trip['id'], 'ARRIVED'), child: const Text('Arrived at Pickup'))),
                            if (status == 'ARRIVED')
                              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _updateStatus(trip['id'], 'IN_PROGRESS'), child: const Text('Start Trip'))),
                            if (status == 'IN_PROGRESS')
                              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B121B), foregroundColor: Colors.white), onPressed: () => _updateStatus(trip['id'], 'COMPLETED'), child: const Text('Complete Trip'))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class TripsTab extends StatelessWidget { const TripsTab({super.key}); @override Widget build(BuildContext context) { return const Scaffold(body: Center(child: Text('Trip History'))); } }
class EarningsTab extends StatelessWidget { const EarningsTab({super.key}); @override Widget build(BuildContext context) { return const Scaffold(body: Center(child: Text('Earnings & Wallet'))); } }
class InboxTab extends StatelessWidget { const InboxTab({super.key}); @override Widget build(BuildContext context) { return const Scaffold(body: Center(child: Text('Messages & Alerts'))); } }

class AccountTab extends StatefulWidget {
  final String token;
  const AccountTab({super.key, required this.token});
  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final _nameController = TextEditingController();
  final _bikeController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _tripService = TripService();
  bool _isSaving = false;

  void _saveProfile() async {
    setState(() => _isSaving = true);
    final success = await _tripService.updateRiderProfile(
      widget.token,
      _nameController.text,
      _bikeController.text,
      _emergencyController.text,
    );
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile'), backgroundColor: const Color(0xFF0B121B), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 50, backgroundColor: Color(0xFF0B121B), child: Icon(Icons.person, size: 50, color: Color(0xFFFFBD19))),
          const SizedBox(height: 16),
          const Text('Complete your profile to start accepting rides.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 16),
          TextField(controller: _bikeController, decoration: const InputDecoration(labelText: 'Motorcycle Registration', prefixIcon: Icon(Icons.two_wheeler))),
          const SizedBox(height: 16),
          TextField(controller: _emergencyController, decoration: const InputDecoration(labelText: 'Emergency Contact', prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 32),
          _isSaving ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFBD19), foregroundColor: Colors.black), onPressed: _saveProfile, child: const Text('Save Profile')),
        ],
      ),
    );
  }
}

