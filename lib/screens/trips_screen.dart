import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<dynamic> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final trips = await ApiService.getRiderHistory();
    if (mounted) {
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("Trip History", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFCD34D)),
            onPressed: _loadHistory,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFCD34D)))
        : _trips.isEmpty 
          ? const Center(child: Text("No trips yet.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                final status = trip['status'];
                final isCompleted = status == 'COMPLETED';
                final isCancelled = status == 'CANCELLED';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Trip #${trip['id'].substring(0, 6)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted ? Colors.green.withOpacity(0.2) : isCancelled ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isCompleted ? Colors.green : isCancelled ? Colors.red : Colors.blue,
                                fontSize: 10, fontWeight: FontWeight.bold
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Customer: ${trip['customer']?['phone'] ?? 'Unknown'}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Fare: KES ${trip['estimatedFare']}", style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 16, fontWeight: FontWeight.bold)),
                      if (isCancelled && trip['cancellationReason'] != null) ...[
                        const SizedBox(height: 4),
                        Text("Reason: ${trip['cancellationReason']}", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ]
                    ],
                  ),
                );
              },
            ),
    );
  }
}