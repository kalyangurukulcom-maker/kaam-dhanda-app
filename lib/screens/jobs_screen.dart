import 'package:flutter/material.dart';

class JobsScreen extends StatelessWidget {
  final String currentUserId;
  const JobsScreen({super.key, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💼 Jobs')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.work_outline, size: 80, color: Color(0xFF1565C0)),
          const SizedBox(height: 16),
          const Text('Job Board', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('नौकरी खोजें — Coming Soon', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ]),
      ),
    );
  }
}