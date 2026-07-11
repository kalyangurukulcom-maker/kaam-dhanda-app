import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _filterCategory = 'All';
  final List<String> _categories = ['All', 'Construction', 'Driver', 'Security', 'Housekeeping', 'Factory', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _applyJob(String jobId, Map<String, dynamic> job) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      final existing = await _firestore
          .collection('job_applications')
          .where('applicantUid', isEqualTo: user.uid)
          .where('jobId', isEqualTo: jobId)
          .get();
      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already applied!'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      await _firestore.collection('job_applications').add({
        'jobId': jobId,
        'jobTitle': job['title'] ?? '',
        'employerUid': job['employerUid'] ?? '',
        'applicantUid': user.uid,
        'applicantPhone': user.phoneNumber ?? '',
        'status': 'Applied',
        'appliedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('jobs').doc(jobId).update({
        'applicantCount': FieldValue.increment(1),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted â'), backgroundColor: Colors.green),
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
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Browse Jobs'), Tab(text: 'My Applications')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Column(
            children: [
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_categories[i]),
                      selected: _filterCategory == _categories[i],
                      onSelected: (v) => setState(() => _filterCategory = _categories[i]),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _filterCategory == 'All'
                      ? _firestore.collection('jobs').where('active', isEqualTo: true).orderBy('postedAt', descending: true).snapshots()
                      : _firestore.collection('jobs').where('active', isEqualTo: true).where('category', isEqualTo: _filterCategory).orderBy('postedAt', descending: true).snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('à¤à¥à¤ job à¤¨à¤¹à¥à¤ à¤®à¤¿à¤²à¥'));
                    return ListView.builder(
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (context, i) {
                        final doc = snap.data!.docs[i];
                        final d = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Expanded(child: Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Chip(label: Text(d['category'] ?? ''), backgroundColor: Colors.blue[100])]),
                                Text(d['company'] ?? '', style: TextStyle(color: Colors.grey[700])),
                                if (d['salary'] != null) Text('ð° ${d['salary']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                if (d['location'] != null) Text('ð ${d['location']}'),
                                const SizedBox(height: 8),
                                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _applyJob(doc.id, d), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white), child: const Text('Apply '))),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          user == null ? const Center(child: Text('Please login first')) : StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('job_applications').where('applicantUid', isEqualTo: user.uid).orderBy('appliedAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('à¤à¤ªà¤¨à¥ à¤à¥à¤ job apply  à¤¨à¤¹à¥à¤ à¤à¥'));
              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                  final status = d['status'] ?? 'Applied';
                  return ListTile(title: Text(d['jobTitle'] ?? ''), trailing: Chip(label: Text(status), backgroundColor: status == 'Selected' ? Colors.green[100] : status == 'Rejected' ? Colors.red[100] : Colors.blue[100]));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
