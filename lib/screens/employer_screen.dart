import 'package:flutter/material.dart';

class EmployerScreen extends StatelessWidget {
  const EmployerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FB),
    appBar: AppBar(
      title: const Text('Employer Panel'),
      backgroundColor: const Color(0xFF0369A1),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: Color(0xFF0369A1)),
          SizedBox(height: 16),
          Text('Employer Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}
