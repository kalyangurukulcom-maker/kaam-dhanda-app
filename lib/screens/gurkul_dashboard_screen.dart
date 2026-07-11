import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GurkulDashboardScreen extends StatelessWidget {
  const GurkulDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gurkul Dashboard')),
        body: const Center(child: Text('Please login first')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gurkul Dashboard'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gurkul_applications')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          // Also try to get by uid field if doc id doesn't match
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return _buildQueryFallback(user.uid);
          }
          final d = snap.data!.data() as Map<String, dynamic>;
          return _buildDashboard(d, context);
        },
      ),
    );
  }

  Widget _buildQueryFallback(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gurkul_applications')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('à¤à¥à¤ application à¤¨à¤¹à¥à¤ à¤®à¤¿à¤²à¥', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('à¤ªà¤¹à¤²à¥ Apply tab à¤¸à¥ application à¤à¤°à¥à¤', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        final d = snap.data!.docs.first.data() as Map<String, dynamic>;
        return _buildDashboard(d, context);
      },
    );
  }

  Widget _buildDashboard(Map<String, dynamic> d, BuildContext context) {
    final status = d['status'] ?? 'Pending';
    final statusColor = status == 'Selected'
        ? Colors.green
        : status == 'Rejected'
            ? Colors.red
            : status == 'Joined'
                ? Colors.blue
                : Colors.orange;

    final steps = ['Applied', 'Document Verified', 'Interview', 'Selected', 'Joining'];
    final currentStep = _getStepIndex(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Card(
            color: Colors.deepPurple[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.deepPurple[200],
                    child: Text(
                      (d['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(d['phone'] ?? '', style: TextStyle(color: Colors.grey[600])),
                        Text('Course: ${d['course'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Status: $status',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress Steps
          const Text('Application Progress:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final isDone = idx < currentStep;
            final isCurrent = idx == currentStep;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? Colors.green : isCurrent ? Colors.deepPurple : Colors.grey[300],
                    ),
                    child: Icon(
                      isDone ? Icons.check : isCurrent ? Icons.radio_button_checked : Icons.circle,
                      color: isDone || isCurrent ? Colors.white : Colors.grey,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    step,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.deepPurple : isDone ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Info Cards
          if (d['joiningDate'] != null)
            Card(
              color: Colors.green[50],
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: const Text('Joining Date'),
                subtitle: Text(d['joiningDate'].toString()),
              ),
            ),

          if (d['remarks'] != null && d['remarks'].toString().isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Remarks'),
                subtitle: Text(d['remarks'].toString()),
              ),
            ),
        ],
      ),
    );
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'Pending': return 0;
      case 'Document Verified': return 1;
      case 'Interview Scheduled': return 2;
      case 'Selected': return 3;
      case 'Joined': return 4;
      case 'Rejected': return 0;
      default: return 0;
    }
  }
}
