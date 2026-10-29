import 'package:flutter/material.dart';
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("TRIPS HISTORY", style: TextStyle(color: Colors.white, fontSize: 20))),
    );
  }
}