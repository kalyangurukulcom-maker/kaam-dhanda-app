import 'package:flutter/material.dart';

class GurkulDashboardScreen extends StatelessWidget {
  const GurkulDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FB),
    appBar: AppBar(
      title: const Text('Gurkul Dashboard'),
      backgroundColor: const Color(0xFF1A237E),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1A237E)),
          SizedBox(height: 16),
          Text('Dashboard Loading...'),
        ],
      ),
    ),
  );
}
