import 'package:flutter/material.dart';

class DailyCheckinScreen extends StatelessWidget {
  final String userId, userName, userType;
  const DailyCheckinScreen({super.key, required this.userId, required this.userName, required this.userType});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✅ Daily Check-in')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text('नमस्ते $userName!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('आज का Check-in हो गया ✅', style: TextStyle(fontSize: 16, color: Colors.green)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.thumb_up),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }
}