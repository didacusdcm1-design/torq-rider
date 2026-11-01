import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text("My Account", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E)),
      body: const Center(
        child: Text("Account Profile\n(Coming soon)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}