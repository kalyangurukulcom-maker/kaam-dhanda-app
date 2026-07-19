import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployerJobManagementScreen extends StatefulWidget {
  const EmployerJobManagementScreen({super.key});

  @override
  State<EmployerJobManagementScreen> createState() =>
      _EmployerJobManagementScreenState();
}

class _EmployerJobManagementScreenState
    extends State<EmployerJobManagementScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final snap = await _db
          .collection('jobs')
          .where('employerId', isEqualTo: uid)
          .get();
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        list.add(data);
      }
      if (mounted) setState(() { _jobs = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नौकरी हटाएं?'),
        content: const Text('क्या आप वाकई इस नौकरी को हटाना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('नहीं'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('हाँ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('jobs').doc(jobId).delete();
      await _loadJobs();
    }
  }

  void _showPostJobDialog() {
    final titleCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नई नौकरी डालें'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'नौकरी का नाम *')),
              const SizedBox(height: 8),
              TextField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'जिला/शहर')),
              const SizedBox(height: 8),
              TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'सैलरी (₹/माह)')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'विवरण')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final uid = _auth.currentUser?.uid;
              await _db.collection('jobs').add({
                'title': titleCtrl.text.trim(),
                'jobType': titleCtrl.text.trim(),
                'district': districtCtrl.text.trim(),
                'salary': salaryCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'employerId': uid,
                'isLocal': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadJobs();
            },
            child: const Text('डालें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('मेरी नौकरियां', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _jobs.isEmpty
              ? const Center(child: Text('अभी कोई नौकरी नहीं\nनीचे + बटन दबाएं', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: _loadJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _jobs.length,
                    itemBuilder: (ctx, i) {
                      final job = _jobs[i];
                      final title = (job['title'] ?? job['jobType'] ?? 'नौकरी').toString();
                      final district = (job['district'] ?? '').toString();
                      final salary = (job['salary'] ?? '').toString();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: const CircleAvatar(backgroundColor: Color(0xFF1565C0), child: Icon(Icons.work, color: Colors.white)),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (district.isNotEmpty) Text('📍 $district'),
                            if (salary.isNotEmpty) Text('💰 ₹$salary/माह'),
                          ]),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteJob(job['id'].toString())),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        onPressed: _showPostJobDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('नौकरी डालें', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
