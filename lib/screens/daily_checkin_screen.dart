import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});
  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _loading = false;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _checkIn(String type) async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await _firestore.collection('checkins').add({
        'uid': user.uid,
        'phone': user.phoneNumber ?? '',
        'type': type,
        'date': _todayKey,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type दर्ज हो गया ✓'), backgroundColor: Colors.green),
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
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Check-in')),
        body: const Center(child: Text('Please login first')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-in'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Text(
              'आज: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _checkIn('Check-In'),
                    icon: const Icon(Icons.login),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _checkIn('Check-Out'),
                    icon: const Icon(Icons.logout),
                    label: const Text('Check Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('पिछले Check-ins:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('checkins')
                  .where('uid', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('कोई check-in नहीं मिला'));
                }
                return ListView.builder(
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                    final ts = d['timestamp'] as Timestamp?;
                    final dt = ts?.toDate();
                    return ListTile(
                      leading: Icon(
                        d['type'] == 'Check-In' ? Icons.login : Icons.logout,
                        color: d['type'] == 'Check-In' ? Colors.green : Colors.red,
                      ),
                      title: Text(d['type'] ?? ''),
                      subtitle: Text(d['date'] ?? ''),
                      trailing: Text(
                        dt != null ? DateFormat('HH:mm').format(dt) : '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
