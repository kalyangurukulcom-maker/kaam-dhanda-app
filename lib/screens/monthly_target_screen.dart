import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonthlyTargetScreen extends StatefulWidget {
  const MonthlyTargetScreen({super.key});
  @override
  State<MonthlyTargetScreen> createState() => _MonthlyTargetScreenState();
}

class _MonthlyTargetScreenState extends State<MonthlyTargetScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _targetCtrl = TextEditingController();
  final _achievedCtrl = TextEditingController();
  bool _loading = false;

  String get _monthKey => DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> _saveTarget() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
    final achieved = int.tryParse(_achievedCtrl.text.trim()) ?? 0;
    setState(() => _loading = true);
    try {
      await _firestore.collection('targets').doc('${user.uid}_$_monthKey').set({
        'uid': user.uid,
        'phone': user.phoneNumber ?? '',
        'month': _monthKey,
        'target': target,
        'achieved': achieved,
        'percentage': target > 0 ? (achieved / target * 100).round() : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target saved ✓'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _achievedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monthly Target')),
        body: const Center(child: Text('Please login first')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Target'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('targets')
                  .doc('${user.uid}_$_monthKey')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('इस महीने कोई target set नहीं है'),
                    ),
                  );
                }
                final d = snap.data!.data() as Map<String, dynamic>;
                final pct = d['percentage'] ?? 0;
                return Card(
                  color: Colors.teal[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${DateFormat('MMMM yyyy').format(DateTime.now())} का Target',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statCard('Target', '${d['target']}', Colors.blue),
                            _statCard('Achieved', '${d['achieved']}', Colors.green),
                            _statCard('Progress', '$pct%',
                                pct >= 100 ? Colors.green : pct >= 50 ? Colors.orange : Colors.red),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: pct > 100 ? 1.0 : pct / 100.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 100 ? Colors.green : pct >= 50 ? Colors.orange : Colors.red,
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Target Update करें:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Target (संख्या)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _achievedCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Achieved so far',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveTarget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Target', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
