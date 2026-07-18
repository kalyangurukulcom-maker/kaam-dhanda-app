import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployerJobManagementScreen extends StatefulWidget {
  const EmployerJobManagementScreen({super.key});
  @override
  State<EmployerJobManagementScreen> createState() => _EmployerJobManagementScreenState();
}

class _EmployerJobManagementScreenState extends State<EmployerJobManagementScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  String get _userPhone {
    final user = _auth.currentUser;
    return user?.phoneNumber ?? user?.uid ?? '';
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      // Fetch all jobs — NO where('active') filter, website never sets 'active' field
      final snap = await _db.collection('jobs').limit(100).get();
      final phone = _userPhone;
      final uid = _auth.currentUser?.uid ?? '';
      _jobs = snap.docs
          .map((d) => {...d.data(), 'id': d.id})
          .where((j) {
            // Show jobs posted by this user
            final jPhone = (j['phone'] ?? j['contact'] ?? j['employerPhone'] ?? '').toString();
            final jUid = (j['uid'] ?? j['userId'] ?? '').toString();
            if (uid.isNotEmpty && jUid == uid) return true;
            if (phone.isNotEmpty && jPhone.contains(phone.replaceAll('+91', ''))) return true;
            return false;
          })
          .toList();
      // Sort by date, newest first
      _jobs.sort((a, b) {
        final ta = a['createdAt'];
        final tb = b['createdAt'];
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return (tb as dynamic).compareTo(ta);
      });
    } catch (e) {
      _jobs = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _deleteJob(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('नौकरी हटाएं?'),
        content: const Text('क्या आप यह नौकरी हटाना चाहते हैं?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('नहीं')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हां', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('jobs').doc(id).delete();
      _loadJobs();
    }
  }

  Future<void> _viewApplications(Map<String, dynamic> job) async {
    try {
      final snap = await _db
          .collection('job_applications')
          .where('jobId', isEqualTo: job['id'])
          .get();
      final apps = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, ctrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${(job['title'] ?? 'नौकरी')} — ${apps.length} आवेदन',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: apps.isEmpty
                    ? const Center(child: Text('अभी कोई आवेदन नहीं आया'))
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: apps.length,
                        itemBuilder: (_, i) {
                          final a = apps[i];
                          final name = (a['name'] ?? a['workerName'] ?? 'आवेदक').toString();
                          final phone = (a['phone'] ?? a['workerPhone'] ?? '').toString();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                              child: Text(name.isNotEmpty ? name[0] : 'अ',
                                  style: const TextStyle(color: Color(0xFF1565C0))),
                            ),
                            title: Text(name),
                            subtitle: Text(phone),
                            trailing: phone.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                                    onPressed: () async {
                                      final ph = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                      final num = ph.startsWith('91') && ph.length > 10 ? ph : '91$ph';
                                      final uri = Uri.parse('https://wa.me/$num');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('आवेदन लोड नहीं हो पाए')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('📋 मेरी नौकरियां',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _jobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.work_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('आपने अभी कोई नौकरी पोस्ट नहीं की',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.add),
                        label: const Text('नौकरी पोस्ट करें'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _jobs.length,
                  itemBuilder: (_, i) {
                    final job = _jobs[i];
                    final title = (job['title'] ?? job['jobTitle'] ?? 'नौकरी').toString();
                    // Use jobType, not category
                    final jt = (job['jobType'] ?? job['category'] ?? job['type'] ?? '').toString();
                    final loc = (job['district'] ?? job['city'] ?? job['location'] ?? '').toString();
                    final salary = (job['salary'] ?? job['salaryRange'] ?? '').toString();
                    final isLocal = job['isLocal'] != false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(title,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isLocal
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isLocal ? '🏠 लोकल' : '✈️ बाहर',
                                    style: TextStyle(
                                            fontSize: 11,
                                      color: isLocal ? Colors.green : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (jt.isNotEmpty)
                              Text(jt,
                                  style: const TextStyle(
                                      color: Color(0xFF1565C0), fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (loc.isNotEmpty) ...[
                                  const Icon(Icons.location_on,
                                      size: 14, color: Colors.grey),
                                  Text(loc,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 12),
                                ],
                                if (salary.isNotEmpty) ...[
                                  const Icon(Icons.currency_rupee,
                                      size: 14, color: Colors.grey),
                                  Text(salary,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _viewApplications(job),
                                    icon: const Icon(Icons.people, size: 16),
                                    label: const Text('आवेदन देखें',
                                        style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1565C0),
                                      side: const BorderSide(
                                          color: Color(0xFF1565C0)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _deleteJob(job['id']),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'हटाएं',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
