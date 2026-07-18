import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All','Construction','Driver','Security','Housekeeping','Factory','Agriculture','Helper','Other'];
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Query<Map<String,dynamic>> get _jobsQuery {
    Query<Map<String,dynamic>> q = FirebaseFirestore.instance.collection('jobs')
        .where('status', isEqualTo: 'active')
        .orderBy('postedAt', descending: true);
    if (_selectedCategory != 'All') q = q.where('category', isEqualTo: _selectedCategory);
    return q;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Jobs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Browse Jobs'), Tab(text: 'My Applications')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_browseTab(), _myAppsTab()],
      ),
    );
  }

  Widget _browseTab() {
    return Column(
      children: [
        _categoryChips(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _jobsQuery.snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
              }
              if (snap.hasError) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error loading jobs', style: TextStyle(color: Colors.grey[600])),
                    TextButton(onPressed: () => setState(() {}), child: const Text('Retry')),
                  ],
                ));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.work_off_outlined, size: 64, color: Color(0xFF90CAF9)),
                    const SizedBox(height: 16),
                    Text('Koi job nahi mili', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    Text('Check back later or change filter', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  ],
                ));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (ctx, i) => _jobCard(docs[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryChips() {
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final sel = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(cat, style: TextStyle(fontSize: 12, color: sel ? Colors.white : const Color(0xFF1565C0), fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              selected: sel,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1565C0),
              checkmarkColor: Colors.white,
              side: BorderSide(color: const Color(0xFF1565C0).withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _jobCard(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String,dynamic>;
    final title = d['title'] ?? 'Job Opening';
    final company = d['employerName'] ?? d['company'] ?? 'Company';
    final salary = d['salary'] ?? d['salaryRange'] ?? 'Negotiable';
    final location = d['location'] ?? d['city'] ?? 'India';
    final category = d['category'] ?? 'General';
    final posted = d['postedAt'] as Timestamp?;
    final isUrgent = posted != null && DateTime.now().difference(posted.toDate()).inHours < 24;
    final phone = d['phone'] ?? d['whatsapp'] ?? '';

    final colors = {'Construction': Colors.orange, 'Driver': Colors.blue, 'Security': Colors.red,
      'Housekeeping': Colors.teal, 'Factory': Colors.purple, 'Agriculture': Colors.green};
    final catColor = colors[category] ?? const Color(0xFF1565C0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22, backgroundColor: catColor.withOpacity(0.12),
                  child: Text(company.isNotEmpty ? company[0].toUpperCase() : 'J',
                      style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      if (isUrgent) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                        child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    Text(company, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              _infoChip(Icons.currency_rupee, salary, Colors.green),
              const SizedBox(width: 8),
              _infoChip(Icons.location_on, location, Colors.blue),
              const SizedBox(width: 8),
              _infoChip(Icons.work, category, catColor),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: phone.isNotEmpty ? () => launchUrl(Uri.parse('https://wa.me/91${phone.replaceAll(RegExp(r"[^0-9]"), "")}?text=Hi, I saw your job posting for $title on KaamDhanda app.')) : null,
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('WhatsApp', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF25D366), side: const BorderSide(color: Color(0xFF25D366))),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _applyJob(doc.id, title, company),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Apply Now', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Future<void> _applyJob(String jobId, String title, String company) async {
    if (_uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to apply'), backgroundColor: Colors.red));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('job_applications').add({
        'jobId': jobId, 'jobTitle': title, 'company': company,
        'applicantUid': _uid, 'status': 'pending', 'appliedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied for $title!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _myAppsTab() {
    if (_uid.isEmpty) return const Center(child: Text('Please login to view applications'));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('job_applications')
          .where('applicantUid', isEqualTo: _uid).orderBy('appliedAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF90CAF9)),
            const SizedBox(height: 12),
            Text('No applications yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String,dynamic>;
            final status = d['status'] ?? 'pending';
            final statusColor = status == 'accepted' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: const Icon(Icons.work, color: Color(0xFF1565C0))),
                title: Text(d['jobTitle'] ?? 'Job', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(d['company'] ?? ''),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
