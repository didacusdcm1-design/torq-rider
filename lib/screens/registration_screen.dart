import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
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
  final _emergencyController = TextEditingController();
  final _bikeMakeController = TextEditingController();
  final _bikeModelController = TextEditingController();
  final _bikeColorController = TextEditingController();
  final _bikeRegController = TextEditingController();

  File? _licenseImage;
  File? _insuranceImage;
  File? _bikeImage;
  File? _selfieImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() {
        if (type == 'license') _licenseImage = File(image.path);
        if (type == 'insurance') _insuranceImage = File(image.path);
        if (type == 'bike') _bikeImage = File(image.path);
        if (type == 'selfie') _selfieImage = File(image.path);
      });
    }
  }

  // Helper to convert File to Base64 String
  Future<String?> _convertToBase64(File? file) async {
    if (file == null) return null;
    try {
      final bytes = await file.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      return null;
    }
  }

  void _nextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      setState(() => _isLoading = true);

      // Convert images to Base64
      String? licenseB64 = await _convertToBase64(_licenseImage);
      String? insuranceB64 = await _convertToBase64(_insuranceImage);
      String? bikeB64 = await _convertToBase64(_bikeImage);
      String? selfieB64 = await _convertToBase64(_selfieImage);

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
        licenseDocUrl: licenseB64,
        insuranceDocUrl: insuranceB64,
        bikePhotoUrl: bikeB64,
        selfieUrl: selfieB64,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
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
                  onPressed: () { Navigator.pop(context); Navigator.pushReplacementNamed(context, '/login'); },
                  child: const Text("Go to Login", style: TextStyle(color: Color(0xFFFCD34D))),
                )
              ],
            )
          );
        }
      }
    }
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
                content: Column(children: [
                  _buildTextField(_fullNameController, "Full Name"),
                  _buildTextField(_phoneController, "Phone Number"),
                  _buildTextField(_nationalIdController, "National ID"),
                  _buildTextField(_licenseController, "Driver's License"),
                  _buildTextField(_emergencyController, "Emergency Contact"),
                ]),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text("Documents", style: TextStyle(color: Colors.white)),
                content: Column(children: [
                  _buildUploadButton("Upload Driver's License", 'license', _licenseImage),
                  _buildUploadButton("Upload Insurance Document", 'insurance', _insuranceImage),
                ]),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text("Motorcycle Details", style: TextStyle(color: Colors.white)),
                content: Column(children: [
                  _buildTextField(_bikeMakeController, "Make"),
                  _buildTextField(_bikeModelController, "Model"),
                  _buildTextField(_bikeColorController, "Color"),
                  _buildTextField(_bikeRegController, "Registration"),
                  _buildUploadButton("Upload Bike Photo", 'bike', _bikeImage),
                ]),
                isActive: _currentStep >= 2,
              ),
              Step(
                title: const Text("Selfie Verification", style: TextStyle(color: Colors.white)),
                content: Column(children: [
                  const Text("Please upload a clear selfie.", style: TextStyle(color: Colors.grey)),
                  _buildUploadButton("Upload Selfie", 'selfie', _selfieImage),
                ]),
                isActive: _currentStep >= 3,
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
      ),
    );
  }

  Widget _buildUploadButton(String text, String type, File? image) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(image != null ? Icons.check_circle : Icons.upload_file, color: image != null ? Colors.green : const Color(0xFFFCD34D)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () => _pickImage(type),
              child: Text(image != null ? "Change" : "Select", style: const TextStyle(color: Color(0xFFFCD34D))),
            ),
          ],
        ),
      ),
    );
  }
}