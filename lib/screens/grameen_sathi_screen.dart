import 'package:flutter/material.dart';

class GrameenSathiScreen extends StatelessWidget {
  final String? staffId;
  const GrameenSathiScreen({super.key, this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grameen Sathi'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 64, color: Color(0xFF1A237E)),
            SizedBox(height: 16),
            Text('Grameen Sathi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Coming Soon', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
