import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();

  // Store selected files
  File? _idImage;
  File? _licenseImage;
  File? _bikeImage;
  File? _passportImage;
  File? _insuranceImage;

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

  Future<void> _pickImage(String type) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (type == 'id') _idImage = File(pickedFile.path);
        if (type == 'license') _licenseImage = File(pickedFile.path);
        if (type == 'bike') _bikeImage = File(pickedFile.path);
        if (type == 'passport') _passportImage = File(pickedFile.path);
        if (type == 'insurance') _insuranceImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (_idImage == null || _licenseImage == null || _bikeImage == null || _passportImage == null || _insuranceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Send text data and images to the backend
      var request = http.MultipartRequest('POST', Uri.parse('\/riders/register'));
      
      request.fields['name'] = _nameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['plateNumber'] = _plateController.text.trim();
      request.fields['bikeModel'] = _modelController.text.trim();

      // 2. Attach images safely
      request.files.add(await http.MultipartFile.fromPath('nationalId', _idImage!.path));
      request.files.add(await http.MultipartFile.fromPath('driversLicense', _licenseImage!.path));
      request.files.add(await http.MultipartFile.fromPath('bikePicture', _bikeImage!.path));
      request.files.add(await http.MultipartFile.fromPath('passportPhoto', _passportImage!.path));
      request.files.add(await http.MultipartFile.fromPath('insurance', _insuranceImage!.path));

      // 3. Send with a timeout for Render free tier
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Server is waking up. Please try again.'),
      );
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = response.body;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
      } else {
        debugPrint('Server error: \');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed. Check console.")),
        );
      }
    } catch (e) {
      debugPrint('Registration error: \');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: \")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessScreen();

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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Documents", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Upload the required documents and photos.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              _buildUploadBox("National ID", Icons.badge, _idImage, () => _pickImage('id')),
              _buildUploadBox("Driver's License", Icons.drive_eta, _licenseImage, () => _pickImage('license')),
              _buildUploadBox("Bike Picture", Icons.motorcycle, _bikeImage, () => _pickImage('bike')),
              _buildUploadBox("Passport Photo", Icons.portrait, _passportImage, () => _pickImage('passport')),
              _buildUploadBox("Insurance", Icons.shield, _insuranceImage, () => _pickImage('insurance')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox(String label, IconData icon, File? imageFile, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageFile != null ? const Color(0xFF4ADE80) : Colors.grey.withOpacity(0.3),
            width: imageFile != null ? 2 : 1,
          ),
          image: imageFile != null 
              ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover, colorFilter: const ColorFilter.mode(Colors.black45, BlendMode.darken))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              imageFile != null ? Icons.check_circle : icon, 
              color: imageFile != null ? const Color(0xFF4ADE80) : const Color(0xFFFCD34D), 
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              imageFile != null ? "Uploaded" : label, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
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