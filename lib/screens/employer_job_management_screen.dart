// ============================================================
// Feature #120: Employer Job Post Management
// File: lib/screens/employer_job_management_screen.dart
// Kaam Dhanda App — Flutter
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => EmployerJobManagementScreen(
//       employerId: 'E001',
//       employerName: 'Ravi Enterprises',
//     ),
//   ));
//
// Firestore: job_postings collection
//   Fields: employerId, title, category, location, salary,
//           seats, urgent, active, description, perks,
//           postedAt, applicationsCount
//
// pubspec.yaml:
//   cloud_firestore: ^4.13.6
//   intl: ^0.18.1
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ============================================================
// Main Screen
// ============================================================
class EmployerJobManagementScreen extends StatefulWidget {
  final String employerId;
  final String employerName;

  const EmployerJobManagementScreen({
    Key? key,
    required this.employerId,
    required this.employerName,
  }) : super(key: key);

  @override
  State<EmployerJobManagementScreen> createState() =>
      _EmployerJobManagementScreenState();
}

class _EmployerJobManagementScreenState
    extends State<EmployerJobManagementScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💼 My Job Posts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(widget.employerName,
                style:
                    const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '✅ Active'),
            Tab(text: '⏸️ Paused'),
            Tab(text: '📊 All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _JobListTab(
              employerId: widget.employerId, db: _db, filter: 'active'),
          _JobListTab(
              employerId: widget.employerId, db: _db, filter: 'paused'),
          _JobListTab(
              employerId: widget.employerId, db: _db, filter: 'all'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostJobSheet(context),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('नई Job Post',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPostJobSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostJobSheet(
        employerId: widget.employerId,
        employerName: widget.employerName,
        db: _db,
      ),
    );
  }
}

// ============================================================
// Job List Tab
// ============================================================
class _JobListTab extends StatelessWidget {
  final String employerId;
  final FirebaseFirestore db;
  final String filter; // 'active' | 'paused' | 'all'

  const _JobListTab(
      {required this.employerId, required this.db, required this.filter});

  @override
  Widget build(BuildContext context) {
    Query query = db
        .collection('job_postings')
        .where('employerId', isEqualTo: employerId)
        .orderBy('postedAt', descending: true);

    if (filter == 'active') {
      query = query.where('active', isEqualTo: true);
    } else if (filter == 'paused') {
      query = query.where('active', isEqualTo: false);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)));
        }

        List<Map<String, dynamic>> jobs = [];
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          jobs = snap.data!.docs
              .map((d) =>
                  {...d.data() as Map<String, dynamic>, 'docId': d.id})
              .toList();
        } else {
          jobs = _demoJobs
              .where((j) =>
                  filter == 'all' ||
                  (filter == 'active' && j['active'] == true) ||
                  (filter == 'paused' && j['active'] == false))
              .toList();
        }

        if (jobs.isEmpty) {
          return _EmptyState(filter: filter);
        }

        // Summary stats at top
        final totalApps =
            jobs.fold<int>(0, (s, j) => s + ((j['applicationsCount'] ?? 0) as int));

        return Column(
          children: [
            // Stats bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _MiniStat('📋', '${jobs.length}', 'Posts'),
                  const SizedBox(width: 20),
                  _MiniStat('👥', '$totalApps', 'Applications'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      filter == 'active'
                          ? '✅ Active Jobs'
                          : filter == 'paused'
                              ? '⏸️ Paused Jobs'
                              : '📊 All Jobs',
                      style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: jobs.length,
                itemBuilder: (_, i) =>
                    _JobCard(job: jobs[i], db: db),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// Job Card
// ============================================================
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final FirebaseFirestore db;

  const _JobCard({required this.job, required this.db});

  String _postedAgo(dynamic ts) {
    if (ts == null) return 'अभी';
    final dt = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'आज';
    if (diff.inDays == 1) return 'कल';
    if (diff.inDays < 30) return '${diff.inDays} दिन पहले';
    return DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final docId = job['docId'] ?? '';
    final title = job['title'] ?? 'Job Post';
    final category = job['category'] ?? '';
    final location = job['location'] ?? '';
    final salary = job['salary'] ?? job['dailyRate'] ?? 0;
    final seats = job['seats'] ?? 1;
    final urgent = job['urgent'] ?? false;
    final active = job['active'] ?? true;
    final apps = job['applicationsCount'] ?? 0;
    final ts = job['postedAt'];
    final description = job['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent
              ? Colors.red.shade300
              : active
                  ? Colors.grey.shade200
                  : Colors.grey.shade300,
          width: urgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF1565C0).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _categoryEmoji(category),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (urgent)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.red.shade300),
                              ),
                              child: const Text('🚨 Urgent',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? Colors.black87
                                    : Colors.black45,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$category • 📍 $location',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Active toggle
                Switch(
                  value: active,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: docId.isEmpty
                      ? null
                      : (v) async {
                          HapticFeedback.lightImpact();
                          await db
                              .collection('job_postings')
                              .doc(docId)
                              .update({'active': v});
                        },
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip('💰 ₹$salary/day', Colors.green.shade700),
                _Chip('🪑 $seats Seats', const Color(0xFF1565C0)),
                _Chip('👥 $apps Applications',
                    apps > 0 ? Colors.orange.shade700 : Colors.black45),
                _Chip('📅 ${_postedAgo(ts)}', Colors.black45),
              ],
            ),
          ),

          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                description,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black45, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // View applications
                if (apps > 0)
                  Expanded(
                    child: _OutlineBtn(
                      icon: '👥',
                      label: '$apps Applications',
                      color: const Color(0xFF1565C0),
                      onTap: () => _viewApplications(context, docId, title),
                    ),
                  ),
                if (apps > 0) const SizedBox(width: 8),
                // Edit
                _IconBtn(
                  icon: Icons.edit_outlined,
                  color: Colors.orange,
                  onTap: () => _editJob(context, job),
                ),
                const SizedBox(width: 8),
                // Delete
                _IconBtn(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: () => _deleteJob(context, docId, title),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String cat) {
    const map = {
      'Construction': '🏗️',
      'Painting': '🎨',
      'Plumbing': '🔧',
      'Electrical': '⚡',
      'Carpentry': '🪵',
      'Welding': '🔩',
      'Cooking': '🍳',
      'Cleaning': '🧹',
      'Security': '🛡️',
      'Driving': '🚗',
    };
    return map[cat] ?? '💼';
  }

  void _viewApplications(BuildContext ctx, String docId, String title) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ApplicationsSheet(jobId: docId, jobTitle: title, db: db),
    );
  }

  void _editJob(BuildContext ctx, Map<String, dynamic> job) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostJobSheet(
        employerId: job['employerId'] ?? '',
        employerName: job['employerName'] ?? '',
        db: db,
        existingJob: job,
      ),
    );
  }

  Future<void> _deleteJob(
      BuildContext ctx, String docId, String title) async {
    if (docId.isEmpty) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Job Delete करें?'),
        content: Text('"$title" permanently delete हो जाएगी।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await db.collection('job_postings').doc(docId).delete();
      HapticFeedback.mediumImpact();
    }
  }
}

// ============================================================
// Applications Sheet
// ============================================================
class _ApplicationsSheet extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  final FirebaseFirestore db;

  const _ApplicationsSheet(
      {required this.jobId, required this.jobTitle, required this.db});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('👥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Applications — $jobTitle',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('job_applications')
                  .where('jobId', isEqualTo: jobId)
                  .orderBy('appliedAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📭', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 12),
                        Text('अभी कोई Application नहीं',
                            style: TextStyle(color: Colors.black45)),
                      ],
                    ),
                  );
                }
                final apps = snap.data!.docs
                    .map((d) => {
                          ...d.data() as Map<String, dynamic>,
                          'docId': d.id
                        })
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: apps.length,
                  itemBuilder: (_, i) => _AppTile(app: apps[i], db: db),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final Map<String, dynamic> app;
  final FirebaseFirestore db;

  const _AppTile({required this.app, required this.db});

  @override
  Widget build(BuildContext context) {
    final name = app['workerName'] ?? 'Worker';
    final phone = app['workerPhone'] ?? '';
    final status = app['status'] ?? 'pending';
    final ts = app['appliedAt'];
    String timeStr = '';
    if (ts != null) {
      timeStr = DateFormat('dd MMM, hh:mm a').format((ts as Timestamp).toDate());
    }

    Color statusColor;
    switch (status) {
      case 'shortlisted':
        statusColor = Colors.blue;
        break;
      case 'hired':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (timeStr.isNotEmpty)
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          // Status chip
          PopupMenuButton<String>(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (s) async {
              await db
                  .collection('job_applications')
                  .doc(app['docId'])
                  .update({'status': s});
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'pending', child: Text('🔄 Pending')),
              const PopupMenuItem(
                  value: 'shortlisted', child: Text('👍 Shortlisted')),
              const PopupMenuItem(
                  value: 'hired', child: Text('✅ Hired')),
              const PopupMenuItem(
                  value: 'rejected', child: Text('❌ Rejected')),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                import_url_launcher(phone);
              },
              child: const Icon(Icons.phone_outlined,
                  color: Color(0xFF1565C0), size: 22),
            ),
          ],
        ],
      ),
    );
  }

  void import_url_launcher(String phone) async {
    final uri = Uri.parse('tel:$phone');
    // ignore: deprecated_member_use
    // launchUrl(uri);
  }
}

// ============================================================
// Post / Edit Job Sheet
// ============================================================
class _PostJobSheet extends StatefulWidget {
  final String employerId;
  final String employerName;
  final FirebaseFirestore db;
  final Map<String, dynamic>? existingJob;

  const _PostJobSheet({
    required this.employerId,
    required this.employerName,
    required this.db,
    this.existingJob,
  });

  @override
  State<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends State<_PostJobSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '1');

  String _category = 'Construction';
  bool _urgent = false;
  bool _saving = false;

  final _categories = [
    'Construction', 'Painting', 'Plumbing', 'Electrical', 'Carpentry',
    'Welding', 'Cooking', 'Cleaning', 'Security', 'Driving', 'Tailoring',
  ];

  bool get _isEdit => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final j = widget.existingJob!;
      _titleCtrl.text = j['title'] ?? '';
      _descCtrl.text = j['description'] ?? '';
      _locationCtrl.text = j['location'] ?? '';
      _salaryCtrl.text = '${j['salary'] ?? j['dailyRate'] ?? ''}';
      _seatsCtrl.text = '${j['seats'] ?? 1}';
      _category = j['category'] ?? 'Construction';
      _urgent = j['urgent'] ?? false;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _salaryCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _locationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title और Location ज़रूरी है')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'employerId': widget.employerId,
        'employerName': widget.employerName,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'location': _locationCtrl.text.trim(),
        'salary': int.tryParse(_salaryCtrl.text) ?? 0,
        'seats': int.tryParse(_seatsCtrl.text) ?? 1,
        'urgent': _urgent,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit && widget.existingJob!['docId'] != null) {
        await widget.db
            .collection('job_postings')
            .doc(widget.existingJob!['docId'])
            .update(data);
      } else {
        data['postedAt'] = FieldValue.serverTimestamp();
        data['applicationsCount'] = 0;
        await widget.db.collection('job_postings').add(data);
      }

      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Text(
                _isEdit ? '✏️ Job Edit करें' : '➕ नई Job Post करें',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetField(
                        ctrl: _titleCtrl,
                        label: 'Job Title *',
                        hint: 'जैसे: 5 Painters चाहिए',
                        icon: Icons.work_outline),
                    const SizedBox(height: 12),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                      ),
                      items: _categories
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? 'Construction'),
                    ),
                    const SizedBox(height: 12),
                    _SheetField(
                        ctrl: _locationCtrl,
                        label: 'Location *',
                        hint: 'जैसे: Ranchi, Jharkhand',
                        icon: Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                              ctrl: _salaryCtrl,
                              label: 'Daily Rate (₹)',
                              hint: '500',
                              icon: Icons.currency_rupee,
                              keyboardType: TextInputType.number),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SheetField(
                              ctrl: _seatsCtrl,
                              label: 'Seats',
                              hint: '1',
                              icon: Icons.people_outline,
                              keyboardType: TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SheetField(
                        ctrl: _descCtrl,
                        label: 'Description',
                        hint: 'काम की जानकारी, requirements...',
                        icon: Icons.description_outlined,
                        maxLines: 3),
                    const SizedBox(height: 12),

                    // Urgent toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _urgent = !_urgent);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _urgent
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _urgent
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🚨',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Urgent Job',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('Search results में ऊपर दिखेगा',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _urgent,
                              activeColor: Colors.red,
                              onChanged: (v) =>
                                  setState(() => _urgent = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isEdit ? 'Update करें' : 'Post करें',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Shared helpers
// ============================================================
class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _MiniStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.black45)),
          ],
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlineBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            filter == 'active' ? '📭' : filter == 'paused' ? '⏸️' : '💼',
            style: const TextStyle(fontSize: 52),
          ),
          const SizedBox(height: 16),
          Text(
            filter == 'active'
                ? 'कोई Active Job नहीं'
                : filter == 'paused'
                    ? 'कोई Paused Job नहीं'
                    : 'अभी तक कोई Job Post नहीं',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black45),
          ),
          const SizedBox(height: 8),
          const Text(
            '➕ बटन से नई Job Post करें',
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

// Demo data
final _demoJobs = [
  {
    'docId': 'j1',
    'title': '5 Painters चाहिए',
    'category': 'Painting',
    'location': 'Ranchi, JH',
    'salary': 700,
    'seats': 5,
    'urgent': true,
    'active': true,
    'applicationsCount': 12,
    'description': 'Office building painting ka kaam hai.',
    'postedAt': null,
  },
  {
    'docId': 'j2',
    'title': 'Security Guard Required',
    'category': 'Security',
    'location': 'Dhanbad, JH',
    'salary': 600,
    'seats': 2,
    'urgent': false,
    'active': true,
    'applicationsCount': 4,
    'description': 'Night shift security guard.',
    'postedAt': null,
  },
  {
    'docId': 'j3',
    'title': 'Cook / Chef needed',
    'category': 'Cooking',
    'location': 'Bokaro, JH',
    'salary': 800,
    'seats': 1,
    'urgent': false,
    'active': false,
    'applicationsCount': 7,
    'description': 'Hostel kitchen ke liye cook chahiye.',
    'postedAt': null,
  },
];
