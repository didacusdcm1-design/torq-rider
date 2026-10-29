import 'package:flutter/material.dart';
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("ACCOUNT PROFILE", style: TextStyle(color: Colors.white, fontSize: 20))),
    );
  }
}