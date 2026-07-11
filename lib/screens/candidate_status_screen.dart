import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CandidateStatusScreen extends StatefulWidget {
  const CandidateStatusScreen({super.key});
  @override
  State<CandidateStatusScreen> createState() => _CandidateStatusScreenState();
}

class _CandidateStatusScreenState extends State<CandidateStatusScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _selectedCollection = 'field_staff_candidates';

  final Map<String, String> _collections = {
    'field_staff_candidates': 'Field Staff Candidates',
    'gurkul_candidates': 'Gurkul Candidates',
  };

  final List<String> _statuses = ['Pending', 'Interviewed', 'Selected', 'Rejected', 'Joined'];

  Color _statusColor(String status) {
    switch (status) {
      case 'Selected': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Joined': return Colors.blue;
      case 'Interviewed': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await _firestore.collection(_selectedCollection).doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated: $newStatus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Status'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedCollection,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
              items: _collections.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCollection = v);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(_selectedCollection)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('कोई candidate नहीं मिला'));
                }
                return ListView.builder(
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    final doc = snap.data!.docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'] ?? 'Pending';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(d['name'] ?? d['fullName'] ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['phone'] ?? d['mobile'] ?? ''),
                            if (d['skill'] != null) Text('Skill: ${d['skill']}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          child: Chip(
                            label: Text(status, style: const TextStyle(color: Colors.white)),
                            backgroundColor: _statusColor(status),
                          ),
                          itemBuilder: (ctx) => _statuses
                              .map((s) => PopupMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onSelected: (s) => _updateStatus(doc.id, s),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
