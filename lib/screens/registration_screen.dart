import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSuccess = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();

  final String apiUrl = 'https://torq-backend.onrender.com';

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);
    
    // NOTE: In a real app, you would upload the ID/License images here first.
    // For now, we are just sending the text data.
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/riders/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'plateNumber': _plateController.text.trim(),
          'bikeModel': _modelController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed. Please try again.")),
        );
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error. Check your connection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: _currentStep > 0 
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _prevStep)
            : null,
        title: const Text("Rider Onboarding", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: const Color(0xFF1E1E1E),
                  color: const Color(0xFFFCD34D),
                  minHeight: 8,
                ),
                const SizedBox(height: 32),
                
                Expanded(
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),

                // Bottom Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCD34D),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == 2 ? "Submit Application" : "Continue",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Personal Info", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Let's start with the basics.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        _buildTextField(_nameController, "Full Name", Icons.person),
        const SizedBox(height: 16),
        _buildTextField(_phoneController, "Phone Number (e.g., 0712345678)", Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildTextField(_emailController, "Email Address", Icons.email, keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Vehicle Details", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Tell us about your motorcycle.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        _buildTextField(_plateController, "License Plate Number", Icons.directions_bike),
        const SizedBox(height: 16),
        _buildTextField(_modelController, "Bike Model (e.g., Bajaj Boxer)", Icons.motorcycle),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Documents", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Upload your ID and Driver's License.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        
        // Placeholder for Image Uploads
        GestureDetector(
          onTap: () { /* Image Picker Logic */ },
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: Color(0xFFFCD34D), size: 40),
                SizedBox(height: 8),
                Text("Upload National ID", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () { /* Image Picker Logic */ },
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: Color(0xFFFCD34D), size: 40),
                SizedBox(height: 8),
                Text("Upload Driver's License", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFFCD34D)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFCD34D)),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFFCD34D), size: 100),
              const SizedBox(height: 24),
              const Text(
                "Application Submitted!",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Our team is reviewing your documents. You will receive a notification once you are approved to start driving.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Navigate to Login Screen
                  },
                  child: const Text("Back to Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}