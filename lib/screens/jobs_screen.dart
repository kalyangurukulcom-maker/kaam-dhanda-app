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
  final Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _toggleSave(String jobId) {
    setState(() {
      if (_savedJobIds.contains(jobId)) {
        _savedJobIds.remove(jobId);
      } else {
        _savedJobIds.add(jobId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.work), text: 'Browse Jobs'),
            Tab(icon: Icon(Icons.favorite), text: 'Saved'),
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'My Applied'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BrowseJobsTab(
            savedJobIds: _savedJobIds,
            onToggleSave: _toggleSave,
          ),
          _SavedJobsTab(
            savedJobIds: _savedJobIds,
            onToggleSave: _toggleSave,
          ),
          const _MyApplicationsTab(),
        ],
      ),
    );
  }
}

// ─── BROWSE JOBS TAB ────────────────────────────────────────────────────────

class _BrowseJobsTab extends StatefulWidget {
  final Set<String> savedJobIds;
  final void Function(String jobId) onToggleSave;

  const _BrowseJobsTab(
      {required this.savedJobIds, required this.onToggleSave});

  @override
  State<_BrowseJobsTab> createState() => _BrowseJobsTabState();
}

class _BrowseJobsTabState extends State<_BrowseJobsTab> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Construction', 'Driver', 'Security',
    'Housekeeping', 'Factory', 'Farming', 'Other'
  ];

  Query get _jobsQuery {
    if (_selectedCategory != 'All') {
      return _firestore
          .collection('jobs')
          .where('active', isEqualTo: true)
          .where('category', isEqualTo: _selectedCategory)
          .orderBy('postedAt', descending: true);
    }
    return _firestore
        .collection('jobs')
        .where('active', isEqualTo: true)
        .orderBy('postedAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category filter chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: const Color(0xFF1565C0),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: Colors.grey.shade100,
                ),
              );
            },
          ),
        ),
        // Jobs list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _jobsQuery.snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.work_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        _selectedCategory == 'All'
                            ? 'No jobs available right now'
                            : 'No $_selectedCategory jobs available',
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }
              final docs = snap.data!.docs;
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final job = docs[i].data() as Map<String, dynamic>;
                  final jobId = docs[i].id;
                  return _JobCard(
                    jobId: jobId,
                    job: job,
                    isSaved: widget.savedJobIds.contains(jobId),
                    onToggleSave: () => widget.onToggleSave(jobId),
                    onApply: () => _showApplyForm(context, jobId, job),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── SAVED JOBS TAB ─────────────────────────────────────────────────────────

class _SavedJobsTab extends StatefulWidget {
  final Set<String> savedJobIds;
  final void Function(String jobId) onToggleSave;

  const _SavedJobsTab({required this.savedJobIds, required this.onToggleSave});

  @override
  State<_SavedJobsTab> createState() => _SavedJobsTabState();
}

class _SavedJobsTabState extends State<_SavedJobsTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.savedJobIds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 70, color: Colors.grey),
            SizedBox(height: 16),
            Text('No saved jobs yet',
                style: TextStyle(fontSize: 17, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Job card पर ❤️ tap करके save करें',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    final firestore = FirebaseFirestore.instance;
    return FutureBuilder<List<DocumentSnapshot>>(
      key: ValueKey(widget.savedJobIds.length),
      future: Future.wait(
        widget.savedJobIds
            .map((id) => firestore.collection('jobs').doc(id).get())
            .toList(),
      ),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs =
            snap.data?.where((d) => d.exists).toList() ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('Saved jobs could not be loaded.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final job = docs[i].data() as Map<String, dynamic>;
            final jobId = docs[i].id;
            return _JobCard(
              jobId: jobId,
              job: job,
              isSaved: true,
              onToggleSave: () {
                widget.onToggleSave(jobId);
                setState(() {});
              },
              onApply: () => _showApplyForm(context, jobId, job),
            );
          },
        );
      },
    );
  }
}

// ─── JOB CARD ───────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onApply;

  const _JobCard({
    required this.jobId,
    required this.job,
    required this.isSaved,
    required this.onToggleSave,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? job['jobTitle'] ?? 'Job Opening';
    final company = job['company'] ?? job['employer'] ?? '';
    final location = job['location'] ?? job['jila'] ?? '';
    final salary = job['salary'] ?? job['salaryRange'] ?? '';
    final category = job['category'] ?? '';
    final count = job['applicantCount'] ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work,
                      color: Color(0xFF1565C0), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      if (company.isNotEmpty)
                        Text(company,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                // Bookmark / Favorite icon
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? Colors.red : Colors.grey,
                    size: 26,
                  ),
                  onPressed: onToggleSave,
                  tooltip: isSaved ? 'Remove from saved' : 'Save job',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (location.isNotEmpty) _chip(Icons.location_on, location, Colors.blue),
                if (salary.isNotEmpty) _chip(Icons.currency_rupee, salary, Colors.green),
                if (category.isNotEmpty) _chip(Icons.category, category, Colors.orange),
                _chip(Icons.people, '$count Applied', Colors.purple),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Apply Now',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── APPLY FORM (bottom sheet) ───────────────────────────────────────────────

void _showApplyForm(
    BuildContext context, String jobId, Map<String, dynamic> job) {
  final naam = TextEditingController();
  final mobile = TextEditingController();
  final aadhaar = TextEditingController();
  final address = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final firestore = FirebaseFirestore.instance;
  final title = job['title'] ?? job['jobTitle'] ?? 'Job';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setModalState) {
        bool loading = false;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Apply: $title',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: naam,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Name required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mobile,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mobile required';
                    if (v.length != 10) return '10 digits required';
                    return null;
                  },
                ),
                TextFormField(
                  controller: aadhaar,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  decoration: const InputDecoration(
                      labelText: 'Aadhaar Number *',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Aadhaar required';
                    if (v.length != 12) return '12 digits required';
                    return null;
                  },
                ),
                TextFormField(
                  controller: address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Address / Village',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (_, setSub) => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSub(() => loading = true);

                              final dup = await firestore
                                  .collection('job_applications')
                                  .where('jobId', isEqualTo: jobId)
                                  .where('applicantPhone',
                                      isEqualTo: mobile.text.trim())
                                  .limit(1)
                                  .get();

                              if (dup.docs.isNotEmpty) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'आपने पहले ही इस job के लिए apply किया है।'),
                                        backgroundColor: Colors.orange));
                                return;
                              }

                              await firestore
                                  .collection('job_applications')
                                  .add({
                                'jobId': jobId,
                                'jobTitle': title,
                                'applicantName': naam.text.trim(),
                                'applicantPhone': mobile.text.trim(),
                                'aadhaar': aadhaar.text.trim(),
                                'address': address.text.trim(),
                                'status': 'Pending',
                                'appliedAt': FieldValue.serverTimestamp(),
                              });

                              await firestore
                                  .collection('jobs')
                                  .doc(jobId)
                                  .update(
                                      {'applicantCount': FieldValue.increment(1)});

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Application submitted!'),
                                      backgroundColor: Colors.green));
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Application',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ─── MY APPLICATIONS TAB ────────────────────────────────────────────────────

class _MyApplicationsTab extends StatefulWidget {
  const _MyApplicationsTab();

  @override
  State<_MyApplicationsTab> createState() => _MyApplicationsTabState();
}

class _MyApplicationsTabState extends State<_MyApplicationsTab> {
  final _phoneCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  String? _searchPhone;

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Interview':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number डालें',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (_phoneCtrl.text.length == 10) {
                    setState(() => _searchPhone = _phoneCtrl.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        if (_searchPhone == null)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Mobile number डालें\nअपनी applications देखें',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('job_applications')
                  .where('applicantPhone', isEqualTo: _searchPhone)
                  .orderBy('appliedAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 50, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No applications found for this number',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final app = docs[i].data() as Map<String, dynamic>;
                    final status = app['status'] ?? 'Pending';
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(status).withOpacity(0.15),
                          child: Icon(Icons.work,
                              color: _statusColor(status)),
                        ),
                        title: Text(app['jobTitle'] ?? 'Job Application',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Applied: ${_formatDate(app['appliedAt'])}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(status).withOpacity(0.3)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return 'Just now';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    return 'Recent';
  }
}
