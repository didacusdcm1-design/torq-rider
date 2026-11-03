import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _idDoc;
  XFile? _licenseDoc;
  XFile? _insuranceDoc;
  XFile? _selfieDoc;

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() {
        if (type == 'id') _idDoc = image;
        if (type == 'license') _licenseDoc = image;
        if (type == 'insurance') _insuranceDoc = image;
        if (type == 'selfie') _selfieDoc = image;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final result = await ApiService.submitRegistration({
      'fullName': _fullNameController.text,
      'phone': _phoneController.text,
      'nationalId': _nationalIdController.text,
      'licenseNumber': _licenseController.text,
      'plateNumber': _plateController.text,
      'model': _modelController.text,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Registration Successful!", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Your temporary login password is:", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Text(result['temporaryPassword'] ?? 'N/A', style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text("Go to Login", style: TextStyle(color: Color(0xFFFCD34D))),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildUploadButton(String label, XFile? image, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(image != null ? Icons.check_circle : Icons.upload_file, color: image != null ? Colors.green : const Color(0xFFFCD34D)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () => _pickImage(type),
              child: Text(image != null ? "Change" : "Select", style: const TextStyle(color: Color(0xFFFCD34D))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text("Rider Verification", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E)),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
        : Stepper(
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: () => setState(() => _currentStep -= 1),
            steps: [
              Step(
                title: const Text("Identity", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    _buildTextField("Full Name", _fullNameController),
                    _buildTextField("Phone Number", _phoneController),
                    _buildTextField("National ID", _nationalIdController),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text("Documents", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    _buildUploadButton("Upload ID Document", _idDoc, 'id'),
                    _buildUploadButton("Upload Driver License", _licenseDoc, 'license'),
                    _buildUploadButton("Upload Insurance", _insuranceDoc, 'insurance'),
                  ],
                ),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text("Motorcycle Details", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    _buildTextField("License Plate", _plateController),
                    _buildTextField("Motorcycle Model", _modelController),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
              Step(
                title: const Text("Selfie Verification", style: TextStyle(color: Colors.white)),
                content: Column(
                  children: [
                    const Text("Please upload a clear selfie.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    _buildUploadButton("Upload Selfie", _selfieDoc, 'selfie'),
                  ],
                ),
                isActive: _currentStep >= 3,
              ),
            ],
          ),
    );
  }
}