import 'package:flutter/material.dart';

class QuickCtaBar extends StatelessWidget {
  final VoidCallback onWorkerRegister, onJobSearch, onHireWorker;
  const QuickCtaBar({
    super.key,
    required this.onWorkerRegister,
    required this.onJobSearch,
    required this.onHireWorker,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: onWorkerRegister,
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Register', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(
          onPressed: onJobSearch,
          icon: const Icon(Icons.search, size: 16),
          label: const Text('Job Dhundo', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
      ]),
    );
  }
}