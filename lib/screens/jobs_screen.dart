// ══════════════════════════════════════════════════════════════
//  Jobs Screen — Admin panel से post हुई jobs यहाँ दिखेंगी
//  Website + App same Firebase jobs collection से पढ़ते हैं
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../widgets/ad_banner.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String _selectedCategory = 'All';
  final _categories = ['All', 'Local', 'Bahar', 'Dubai', 'Construction', 'Factory', 'Security', 'Driver'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('💼 Jobs', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.amber : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? const Color(0xFF1A237E) : Colors.white,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Ad Banner
          const AdBannerWidget(zone: 'card'),

          // Jobs List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.getActiveJobs(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                }

                if (snap.hasError) {
                  return _buildEmpty('कोई error आई: ${snap.error}');
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmpty('अभी कोई job नहीं है\nजल्द ही नई jobs आएंगी!');
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final job = docs[i].data() as Map<String, dynamic>;
                    return _JobCard(
                      jobId: docs[i].id,
                      job: job,
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

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_off, size: 64, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Job Card Widget ──────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> job;
  const _JobCard({required this.jobId, required this.job});

  @override
  Widget build(BuildContext context) {
    final category = job['category'] ?? 'Job';
    final Color catColor = _catColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showJobDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(category, style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  if (job['urgent'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: const Text('🔥 URGENT', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                job['title'] ?? 'Job Title',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
              ),
              if (job['company'] != null) ...[
                const SizedBox(height: 4),
                Text(job['company'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: [
                  if (job['salary'] != null) _chip('💰 ${job['salary']}', Colors.green),
                  if (job['location'] != null) _chip('📍 ${job['location']}', Colors.blue),
                  if (job['seats'] != null) _chip('🪑 ${job['seats']} सीट', Colors.orange),
                ],
              ),
              if (job['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  job['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showJobDetail(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A237E),
                        side: const BorderSide(color: Color(0xFF1A237E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Details देखें', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _applyDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Apply करें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'dubai': return Colors.orange;
      case 'bahar': return Colors.purple;
      case 'construction': return Colors.brown;
      case 'factory': return Colors.teal;
      default: return const Color(0xFF1A237E);
    }
  }

  void _showJobDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobDetailSheet(jobId: jobId, job: job),
    );
  }

  void _applyDialog(BuildContext context) {
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    final distCtrl  = TextEditingController();
    final formKey   = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Apply: ${job['title'] ?? 'Job'}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameCtrl,  decoration: const InputDecoration(labelText: 'आपका नाम *'), validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile *'), keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Valid number' : null),
                TextFormField(controller: distCtrl,  decoration: const InputDecoration(labelText: 'जिला')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => loading = true);
                await FirebaseService.applyForJob(
                  jobId: jobId,
                  jobTitle: job['title'] ?? '',
                  applicantName: nameCtrl.text,
                  phone: phoneCtrl.text,
                  district: distCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Application submit हो गई!'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
              child: loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Job Detail Bottom Sheet ──────────────────────────────────
class _JobDetailSheet extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> job;
  const _JobDetailSheet({required this.jobId, required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
                  if (job['company'] != null) ...[
                    const SizedBox(height: 4),
                    Text(job['company'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                  const Divider(height: 24),
                  _row('💰', 'Salary', job['salary']),
                  _row('📍', 'Location', job['location']),
                  _row('🏷️', 'Category', job['category']),
                  _row('🪑', 'Seats', job['seats']?.toString()),
                  _row('🕐', 'Timing', job['timing']),
                  if (job['description'] != null) ...[
                    const Divider(height: 24),
                    const Text('📋 Description', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(job['description'], style: const TextStyle(color: Colors.grey, height: 1.5)),
                  ],
                  if (job['requirements'] != null) ...[
                    const Divider(height: 24),
                    const Text('✅ Requirements', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(job['requirements'], style: const TextStyle(color: Colors.grey, height: 1.5)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply करें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String icon, String key, String? val) {
    if (val == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(key, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
              Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
