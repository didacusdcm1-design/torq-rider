import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _licenseController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _bikeMakeController = TextEditingController();
  final _bikeModelController = TextEditingController();
  final _bikeColorController = TextEditingController();
  final _bikeRegController = TextEditingController();

  bool _isLoading = false;

  void _nextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      setState(() => _isLoading = true);

      final result = await ApiService.submitRegistration(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        nationalId: _nationalIdController.text,
        licenseNumber: _licenseController.text,
        emergencyContact: _emergencyController.text,
        bikeMake: _bikeMakeController.text,
        bikeModel: _bikeModelController.text,
        bikeColor: _bikeColorController.text,
        bikeReg: _bikeRegController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Submitted! Waiting for Admin Approval."), backgroundColor: Colors.green),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${result['message']}"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("Rider Verification", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
        : Stepper(
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: _prevStep,
            steps: [
              Step(
                title: const Text("Identity", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    _buildTextField(_fullNameController, "Full Name"),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, "Phone Number"), // <-- ADDED HERE
                    const SizedBox(height: 16),
                    _buildTextField(_nationalIdController, "National ID Number"),
                    const SizedBox(height: 16),
                    _buildTextField(_licenseController, "Driver's License Number"),
                    const SizedBox(height: 16),
                    _buildTextField(_emergencyController, "Emergency Contact (Phone)"),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text("Documents", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    const Text("Upload Driver's License Photo", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildUploadButton("Take Photo of License"),
                  ],
                ),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text("Motorcycle Details", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    _buildTextField(_bikeMakeController, "Make (e.g., Boxer)"),
                    const SizedBox(height: 16),
                    _buildTextField(_bikeModelController, "Model (e.g., 150)"),
                    const SizedBox(height: 16),
                    _buildTextField(_bikeColorController, "Color"),
                    const SizedBox(height: 16),
                    _buildTextField(_bikeRegController, "Registration (e.g., KMDA 123A)"),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
              Step(
                title: const Text("Selfie Verification", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    const Text("Please take a clear selfie for customer safety.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildUploadButton("Take Selfie"),
                  ],
                ),
                isActive: _currentStep >= 3,
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFCD34D))),
      ),
    );
  }

  Widget _buildUploadButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Camera simulation: Image captured!"), backgroundColor: Colors.blue),
          );
        },
        icon: const Icon(Icons.camera_alt, color: Colors.black),
        label: Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFCD34D),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
