import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register as Rider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 10),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number (e.g., 0712345678)')),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFBD19), foregroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                String? token = await _authService.register(_emailController.text, _phoneController.text, _passwordController.text);
                setState(() => _isLoading = false);

                if (token != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please complete your profile to get approved.'), backgroundColor: Colors.green));
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigation(token: token!)));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Failed'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        );
      },
    );
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    String? token = await _authService.login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (token != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigation(token: token!)));
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
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 30),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFBD19), foregroundColor: Colors.black),
                    onPressed: _handleLogin, 
                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold))
                  ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _showRegisterDialog,
                child: const Text("Don't have an account? Register here", style: TextStyle(color: Color(0xFF0B121B))),
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
      TripsTab(token: widget.token),
      EarningsTab(token: widget.token),
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
    String? errorMessage;
    
    if (status == 'ACCEPTED') {
      errorMessage = await _tripService.acceptTrip(widget.token, tripId);
    } else {
      errorMessage = await _tripService.updateStatus(widget.token, tripId, status);
    }

    if (errorMessage == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status'), backgroundColor: Colors.green));
      _fetchTrips();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage ?? 'Error'), backgroundColor: Colors.red));
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

class TripsTab extends StatefulWidget {
  final String token;
  const TripsTab({super.key, required this.token});
  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> {
  final _tripService = TripService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _tripService.getRiderHistory(widget.token);
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: const Color(0xFF0B121B),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No completed trips yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final trip = _history[index];
                    final fare = double.tryParse(trip['estimatedFare']?.toString() ?? '0.0') ?? 0.0;
                    final date = DateTime.parse(trip['createdAt']).toLocal();
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Colors.green),
                        ),
                        title: Text('Trip #${trip['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Customer: ${trip['customer']?.email ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                            Text('${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: Text('KSh ${fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      ),
                    );
                  },
                ),
    );
  }
}

class EarningsTab extends StatefulWidget {
  final String token;
  const EarningsTab({super.key, required this.token});
  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  final _tripService = TripService();
  Map<String, dynamic>? _wallet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  void _loadWallet() async {
    setState(() => _isLoading = true);
    final wallet = await _tripService.getWallet(widget.token);
    setState(() {
      _wallet = wallet;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Wallet'),
        backgroundColor: const Color(0xFF0B121B),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWallet)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: const Color(0xFF0B121B),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text('Available Balance', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 10),
                          Text(
                            'KSh ${(_wallet?['balance'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFFFFBD19), fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions, color: Colors.blue),
                      title: const Text('Pending Earnings'),
                      trailing: Text(
                        'KSh ${(_wallet?['pendingEarnings'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class InboxTab extends StatelessWidget { const InboxTab({super.key}); @override Widget build(BuildContext context) { return const Scaffold(body: Center(child: Text('Messages & Alerts'))); } }

class AccountTab extends StatefulWidget {
  final String token;
  const AccountTab({super.key, required this.token});
  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  int _currentStep = 0;
  final _tripService = TripService();
  bool _isSaving = false;
  String _verificationStatus = "";
  String _rejectionReason = "";

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _idController = TextEditingController();
  final _emergencyController = TextEditingController();

  final _regController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _insuranceController = TextEditingController();

  String _idDoc = "";
  String _licenseDoc = "";
  String _insuranceDoc = "";
  String _selfieDoc = "";

  @override
  void initState() {
    super.initState();
    _loadProfileStatus();
  }

  void _loadProfileStatus() async {
    final profile = await _tripService.getRiderProfile(widget.token);
    if (profile != null && mounted) {
      setState(() {
        _verificationStatus = profile['verificationStatus'] ?? "";
        _rejectionReason = profile['rejectionReason'] ?? "";
      });
    }
  }

  bool _validateStep() {
    if (_currentStep == 0) {
      return _nameController.text.isNotEmpty && _dobController.text.isNotEmpty && _idController.text.isNotEmpty && _emergencyController.text.isNotEmpty;
    } else if (_currentStep == 1) {
      return _regController.text.isNotEmpty && _makeController.text.isNotEmpty && _modelController.text.isNotEmpty && _insuranceController.text.isNotEmpty;
    } else if (_currentStep == 2) {
      return _idDoc.isNotEmpty && _licenseDoc.isNotEmpty && _insuranceDoc.isNotEmpty && _selfieDoc.isNotEmpty;
    }
    return true;
  }

  void _submitProfile() async {
    setState(() => _isSaving = true);
    final success = await _tripService.updateFullProfile(
      widget.token,
      _nameController.text, _dobController.text, _idController.text, _emergencyController.text,
      _regController.text, _makeController.text, _modelController.text, _insuranceController.text,
      _idDoc, _licenseDoc, _insuranceDoc, _selfieDoc
    );
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted for review!'), backgroundColor: Colors.green));
      setState(() {
        _currentStep = 0;
        _verificationStatus = "PENDING";
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickFile(String label, Function(String) onChanged) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result != null && result.files.single.bytes != null) {
        setState(() => _isSaving = true);
        String? url = await _tripService.uploadFile(result.files.single.bytes!, result.files.single.name);
        setState(() => _isSaving = false);
        
        if (url != null) {
          onChanged(url);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded $label successfully!'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Verification'), backgroundColor: const Color(0xFF0B121B), foregroundColor: Colors.white),
      body: Column(
        children: [
          if (_verificationStatus == 'REJECTED')
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("APPLICATION REJECTED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Reason: $_rejectionReason", style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 5),
                  const Text("Please update your details and resubmit.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_validateStep()) {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submitProfile();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields on this step'), backgroundColor: Colors.red));
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep -= 1);
              },
              steps: [
                Step(
                  title: const Text('Personal Details'),
                  isActive: _currentStep >= 0,
                  content: Column(
                    children: [
                      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name *')),
                      const SizedBox(height: 10),
                      TextField(controller: _dobController, decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD) *')),
                      const SizedBox(height: 10),
                      TextField(controller: _idController, decoration: const InputDecoration(labelText: 'National ID Number *')),
                      const SizedBox(height: 10),
                      TextField(controller: _emergencyController, decoration: const InputDecoration(labelText: 'Emergency Contact *')),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Motorcycle Details'),
                  isActive: _currentStep >= 1,
                  content: Column(
                    children: [
                      TextField(controller: _regController, decoration: const InputDecoration(labelText: 'Registration Number *')),
                      const SizedBox(height: 10),
                      TextField(controller: _makeController, decoration: const InputDecoration(labelText: 'Make *')),
                      const SizedBox(height: 10),
                      TextField(controller: _modelController, decoration: const InputDecoration(labelText: 'Model *')),
                      const SizedBox(height: 10),
                      TextField(controller: _insuranceController, decoration: const InputDecoration(labelText: 'Insurance Expiry *')),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Documents & Review'),
                  isActive: _currentStep >= 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upload Documents *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      _buildUploadTile('National ID', _idDoc, (val) => setState(() => _idDoc = val)),
                      _buildUploadTile('Driver License', _licenseDoc, (val) => setState(() => _licenseDoc = val)),
                      _buildUploadTile('Insurance Certificate', _insuranceDoc, (val) => setState(() => _insuranceDoc = val)),
                      _buildUploadTile('Selfie', _selfieDoc, (val) => setState(() => _selfieDoc = val)),
                      const SizedBox(height: 20),
                      const Text('By submitting, you agree to TORQ\'s terms of service.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      _isSaving ? const Center(child: CircularProgressIndicator()) : const Text('Ready to submit.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTile(String label, String value, Function(String) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.upload_file, color: Color(0xFFFFBD19)),
        title: Text(label),
        subtitle: Text(value.isEmpty ? 'Not uploaded' : 'Uploaded successfully', style: TextStyle(color: value.isEmpty ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B121B), foregroundColor: Colors.white),
          onPressed: () => _pickFile(label, onChanged),
          child: const Text('Upload'),
        ),
      ),
    );
  }
}