import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _isLoading = true;
  double _netEarnings = 0.0;
  double _totalGross = 0.0;
  double _totalCommission = 0.0;
  int _totalTrips = 0;
  List<dynamic> _recentTrips = [];

  final String apiUrl = 'https://torq-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('userId') ?? prefs.getString('user_id');

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(Uri.parse('$apiUrl/riders/$userId/earnings'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _netEarnings = (data['netEarnings'] ?? 0).toDouble();
          _totalGross = (data['totalGross'] ?? 0).toDouble();
          _totalCommission = (data['totalCommission'] ?? 0).toDouble();
          _totalTrips = data['totalTrips'] ?? 0;
          _recentTrips = data['recentTrips'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("Earnings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFCD34D)),
            onPressed: _fetchEarnings,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
          : RefreshIndicator(
              onRefresh: _fetchEarnings,
              color: const Color(0xFFFCD34D),
              backgroundColor: const Color(0xFF1E1E1E),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total Net Earnings",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "KES ${_netEarnings.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Color(0xFFFCD34D),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn("Gross", "KES ${_totalGross.toStringAsFixed(0)}"),
                            _buildStatColumn("Commission", "KES ${_totalCommission.toStringAsFixed(0)}"),
                            _buildStatColumn("Trips", "$_totalTrips"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Recent Completed Trips",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_recentTrips.isEmpty)
                    const Center(
                      child: Text("No completed trips yet.", style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._recentTrips.map((trip) => _buildTripCard(trip)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTripCard(dynamic trip) {
    final String dropoff = trip['dropoffLocation'] ?? 'Unknown Dropoff';
    final double price = (trip['price'] ?? 0).toDouble();
    final String date = DateTime.parse(trip['createdAt']).toLocal().toString().substring(0, 16);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("To: $dropoff", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            "+ KES ${price.toStringAsFixed(0)}",
            style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}