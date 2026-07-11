import 'package:flutter/material.dart';

class FieldStaffScreen extends StatelessWidget {
  const FieldStaffScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FB),
    appBar: AppBar(
      title: const Text('Field Staff'),
      backgroundColor: const Color(0xFF0D47A1),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Color(0xFF0D47A1)),
          SizedBox(height: 16),
          Text('Field Staff Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}
