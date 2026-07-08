import 'package:flutter/material.dart';

class LiveStatsWidget extends StatelessWidget {
  const LiveStatsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('1,200+', 'Workers', '👷'),
          _StatItem('500+', 'Employers', '🏢'),
          _StatItem('8,000+', 'Jobs Done', '✅'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label, icon;
  const _StatItem(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}

class PlatformStatsScreen extends StatelessWidget {
  const PlatformStatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📈 Platform Stats')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: LiveStatsWidget(),
      ),
    );
  }
}