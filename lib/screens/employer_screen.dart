import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployerScreen extends StatefulWidget {
  const EmployerScreen({super.key});
  @override
  State<EmployerScreen> createState() => _EmployerScreenState();
}

class _EmployerScreenState extends State<EmployerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'Construction';
  bool _loading = false;

  final List<String> _categories = ['Construction', 'Driver', 'Security', 'Housekeeping', 'Factory', 'Cook', 'Office', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _salaryCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _postJob() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_titleCtrl.text.trim().isEmpty || _companyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job title and company required'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _firestore.collection('jobs').add({
        'title': _titleCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'salary': _salaryCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'employerUid': user.uid,
        'employerPhone': user.phoneNumber ?? '',
        'active': true,
        'applicantCount': 0,
        'postedAt': FieldValue.serverTimestamp(),
      });
      _titleCtrl.clear();
      _companyCtrl.clear();
      _salaryCtrl.clear();
      _locationCtrl.clear();
      _descCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job post à¤¹à¥ à¤à¤ â'), backgroundColor: Colors.green),
        );
        _tabs.animateTo(1);
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

  Future<void> _toggleJobStatus(String docId, bool currentActive) async {
    try {
      await _firestore.collection('jobs').doc(docId).update({'active': !currentActive});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteJob(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job?'),
        content: const Text('à¤à¥à¤¯à¤¾ à¤à¤ª à¤à¤¸ job à¤à¥ delete à¤à¤°à¤¨à¤¾ à¤à¤¾à¤¹à¤¤à¥ à¤¹à¥à¤?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('jobs').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Panel'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Post Job'), Tab(text: 'My Jobs')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Tab 1: Post Job Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('à¤¨à¤ Job Post à¤à¤°à¥à¤', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Job Title *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(labelText: 'Company Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _salaryCtrl,
                  decoration: const InputDecoration(labelText: 'Salary (e.g. â¹15000/month)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location / City', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Job Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _postJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Post Job', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          // Tab 2: My Jobs Live Stream
          user == null
              ? const Center(child: Text('Please login first'))
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('jobs')
                      .where('employerUid', isEqualTo: user.uid)
                      .orderBy('postedAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(child: Text('à¤à¤ªà¤¨à¥ à¤à¥à¤ job post à¤¨à¤¹à¥à¤ à¤à¥'));
                    }
                    return ListView.builder(
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (context, i) {
                        final doc = snap.data!.docs[i];
                        final d = doc.data() as Map<String, dynamic>;
                        final isActive = d['active'] == true;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(d['title'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    Switch(
                                      value: isActive,
                                      onChanged: (_) => _toggleJobStatus(doc.id, isActive),
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                                Text(d['company'] ?? '', style: TextStyle(color: Colors.grey[600])),
                                Text('${d['category']} â¢ ${d['location'] ?? ''}'),
                                Text('ð° ${d['salary'] ?? 'Not specified'}', style: const TextStyle(color: Colors.green)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('${d['applicantCount'] ?? 0} Applications',
                                          style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600)),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      onPressed: () => _deleteJob(doc.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
