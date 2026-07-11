import 'package:flutter/material.dart';
import 'gurkul_dashboard_screen.dart';

class GurkulScreen extends StatelessWidget {
  const GurkulScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FB),
    appBar: AppBar(
      title: const Text('Gurkul Sathi Program'),
      backgroundColor: const Color(0xFF1A237E),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎓 Gurkul Sathi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('Screen Loading...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}
