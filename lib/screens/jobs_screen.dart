import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _firestore = FirebaseFirestore.instance;
  String _filterCategory = 'All';

  static const _categories = [
    'All', 'Construction', 'Driver', 'Security',
    'Housekeeping', 'Factory', 'Other'
  ];

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

  void _showApplyForm(String jobId, Map<String, dynamic> job) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final aadhaarCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Apply: ' + (job['title'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (job['company'] != null)
                    Text(
                      job['company'].toString(),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  const Divider(height: 20),
                  const Text(
                    'à¤à¤ªà¤¨à¥ details à¤­à¤°à¥à¤:',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'à¤ªà¥à¤°à¤¾ à¤¨à¤¾à¤® *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'à¤¨à¤¾à¤® à¤à¤°à¥à¤°à¥ à¤¹à¥' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().length < 10) ? 'à¤¸à¤¹à¥ à¤¨à¤à¤¬à¤° à¤¡à¤¾à¤²à¥à¤' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: aadhaarCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Aadhaar Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().length < 12) ? 'à¤¸à¤¹à¥ Aadhaar à¤¨à¤à¤¬à¤° à¤¡à¤¾à¤²à¥à¤ (12 digits)' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'à¤ªà¤¤à¤¾ (Address) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'à¤ªà¤¤à¤¾ à¤à¤°à¥à¤°à¥ à¤¹à¥' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModal(() => loading = true);
                              try {
                                final existing = await _firestore
                                    .collection('job_applications')
                                    .where('applicantPhone',
                                        isEqualTo: phoneCtrl.text.trim())
                                    .where('jobId', isEqualTo: jobId)
                                    .get();
                                if (existing.docs.isNotEmpty) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('à¤à¤ª à¤ªà¤¹à¤²à¥ à¤¸à¥ à¤à¤¸ job à¤à¥ à¤²à¤¿à¤ apply à¤à¤° à¤à¥à¤à¥ à¤¹à¥à¤!'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                  setModal(() => loading = false);
                                  return;
                                }
                                await _firestore
                                    .collection('job_applications')
                                    .add({
                                  'jobId': jobId,
                                  'jobTitle': (job['title'] ?? '').toString(),
                                  'employerUid': (job['employerUid'] ?? '').toString(),
                                  'applicantName': nameCtrl.text.trim(),
                                  'applicantPhone': phoneCtrl.text.trim(),
                                  'applicantAadhaar': aadhaarCtrl.text.trim(),
                                  'applicantAddress': addressCtrl.text.trim(),
                                  'status': 'Pending',
                                  'appliedAt': FieldValue.serverTimestamp(),
                                });
                                _firestore.collection('jobs').doc(jobId).update({
                                  'applicantCount': FieldValue.increment(1),
                                }).catchError((_) {});
                                if (mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Application à¤à¤®à¤¾ à¤¹à¥ à¤à¤! Admin approval à¤à¤¾ à¤à¤à¤¤à¤à¤¼à¤¾à¤° à¤à¤°à¥à¤à¥¤'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModal(() => loading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ' + e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text(
                        'Apply à¤à¤°à¥à¤',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Browse Jobs'),
            Tab(text: 'My Applications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_categories[i]),
                      selected: _filterCategory == _categories[i],
                      onSelected: (_) => setState(() => _filterCategory = _categories[i]),
                      selectedColor: const Color(0xFF1565C0),
                      labelStyle: TextStyle(
                        color: _filterCategory == _categories[i] ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _filterCategory == 'All'
                      ? _firestore
                          .collection('jobs')
                          .where('active', isEqualTo: true)
                          .orderBy('postedAt', descending: true)
                          .snapshots()
                      : _firestore
                          .collection('jobs')
                          .where('active', isEqualTo: true)
                          .where('category', isEqualTo: _filterCategory)
                          .orderBy('postedAt', descending: true)
                          .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_off, size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('à¤à¥à¤ job à¤¨à¤¹à¥à¤ à¤®à¤¿à¤²à¥',
                                style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (context, i) {
                        final doc = snap.data!.docs[i];
                        final d = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (d['title'] ?? '').toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    if (d['category'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          d['category'].toString(),
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.blue.shade800),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (d['company'] != null)
                                  Text(d['company'].toString(),
                                      style: TextStyle(color: Colors.grey.shade700)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (d['salary'] != null) ...[
                                      const Icon(Icons.currency_rupee,
                                          size: 16, color: Colors.green),
                                      Text(d['salary'].toString(),
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 12),
                                    ],
                                    if (d['location'] != null) ...[
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.grey),
                                      Text(d['location'].toString(),
                                          style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showApplyForm(doc.id, d),
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text('Apply à¤à¤°à¥à¤'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
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
          const _MyApplicationsTab(),
        ],
      ),
    );
  }
}

class _MyApplicationsTab extends StatefulWidget {
  const _MyApplicationsTab();

  @override
  State<_MyApplicationsTab> createState() => _MyApplicationsTabState();
}

class _MyApplicationsTabState extends State<_MyApplicationsTab> {
  final _phoneCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  List<Map<String, dynamic>> _applications = [];
  bool _searched = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('à¤¸à¤¹à¥ à¤®à¥à¤¬à¤¾à¤à¤² à¤¨à¤à¤¬à¤° à¤¡à¤¾à¤²à¥à¤'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _loading = true; _searched = false; _applications = []; });
    try {
      final snap = await _firestore
          .collection('job_applications')
          .where('applicantPhone', isEqualTo: phone)
          .orderBy('appliedAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _applications = snap.docs.map((d) => d.data()).toList();
          _loading = false;
          _searched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('à¤à¤ªà¤¨à¥ Applications à¤¦à¥à¤à¥à¤',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Registered Mobile Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: const Text('à¤¦à¥à¤à¥à¤'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_searched && _applications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('à¤à¤¸ à¤¨à¤à¤¬à¤° à¤ªà¤° à¤à¥à¤ application à¤¨à¤¹à¥à¤ à¤®à¤¿à¤²à¥à¥¤',
                style: TextStyle(color: Colors.grey)),
          ),
        if (_applications.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _applications.length,
              itemBuilder: (context, i) {
                final d = _applications[i];
                final status = (d['status'] ?? 'Pending').toString();
                Color chipColor;
                if (status == 'Approved' || status == 'Selected') {
                  chipColor = Colors.green.shade100;
                } else if (status == 'Rejected') {
                  chipColor = Colors.red.shade100;
                } else {
                  chipColor = Colors.orange.shade100;
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1565C0),
                      child: Icon(Icons.work, color: Colors.white, size: 20),
                    ),
                    title: Text((d['jobTitle'] ?? 'Job').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Status: ' + status),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                     ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
