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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFBD19),
            foregroundColor: const Color(0xFF0B121B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFBD19), width: 2)),
        ),
      ),
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigation(token: token)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Failed'), backgroundColor: Colors.red));
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
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 30),
              _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _handleLogin, child: const Text('Go Online')),
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
      const AccountTab(),
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
    _tripService.connectWebSocket(() { _fetchTrips(); });
  }

  @override
  void dispose() {
    _tripService.socket.disconnect();
    super.dispose();
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
              ? const Center(child: Text('Waiting for ride requests...', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    final status = trip['status'];
                    final fare = double.tryParse(trip['estimatedFare']?.toString() ?? '0.0') ?? 0.0;
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ride Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFFFBD19).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                  child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(children: [const Icon(Icons.circle, color: Colors.blue, size: 12), const SizedBox(width: 8), Text('Pickup: ${trip['pickupLat']}, ${trip['pickupLng']}')]),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.location_on, color: Colors.red, size: 16), const SizedBox(width: 8), Text('Dropoff: ${trip['dropoffLat']}, ${trip['dropoffLng']}')]),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Earnings:', style: TextStyle(color: Colors.grey.shade600)),
                                Text('KSh ${fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            if (status == 'REQUESTED')
                              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _updateStatus(trip['id'], 'ACCEPTED'), child: const Text('Accept Ride'))),
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
class AccountTab extends StatelessWidget { const AccountTab({super.key}); @override Widget build(BuildContext context) { return const Scaffold(body: Center(child: Text('Driver Profile'))); } }