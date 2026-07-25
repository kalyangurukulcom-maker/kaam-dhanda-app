import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'employer_job_management_screen.dart';

class EmployerScreen extends StatefulWidget {
  const EmployerScreen({super.key});

  @override
  State<EmployerScreen> createState() => _EmployerScreenState();
}

class _EmployerScreenState extends State<EmployerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text(
          'Employer Portal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmployerJobManagementScreen(),
              ),
            ),
            icon: const Icon(Icons.work_outline, color: Colors.white, size: 20),
            label: const Text(
              'मेरी Jobs',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'कारीगर ढूंढें'),
            Tab(icon: Icon(Icons.handshake), text: 'Hire Request'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _WorkersTab(),
          _HireRequestTab(),
        ],
      ),
    );
  }
}

// ─── WORKERS TAB (unchanged from original) ──────────────────────────────────

class _WorkersTab extends StatefulWidget {
  const _WorkersTab();

  @override
  State<_WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<_WorkersTab> {
  final _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;
  String _selectedType = 'सभी';

  final List<String> _jobTypes = [
    'सभी', 'राजमिस्त्री', 'प्लंबर', 'इलेक्ट्रिशियन',
    'पेंटर', 'कारपेंटर', 'दर्जी', 'रसोइया',
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final snap = await _db.collection('workers').limit(100).get();
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        list.add(data);
      }
      if (mounted) setState(() { _workers = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final avail = _workers.where((w) => w['available'] == true).toList();
    if (_selectedType == 'सभी') return avail;
    return avail.where((w) {
      final jt = (w['jobType'] ?? w['category'] ?? '').toString();
      return jt.contains(_selectedType);
    }).toList();
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final num = digits.length == 10 ? '91$digits' : digits;
    final uri = Uri.parse('https://wa.me/$num');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)))
              : _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'कोई उपलब्ध कारीगर नहीं मिला',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ))
                  : RefreshIndicator(
                      onRefresh: _loadWorkers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) =>
                            _buildWorkerCard(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _jobTypes.length,
        itemBuilder: (ctx, i) {
          final isSel = _jobTypes[i] == _selectedType;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = _jobTypes[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF1565C0) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                _jobTypes[i],
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> w) {
    final name = (w['name'] ?? w['workerName'] ?? 'कारीगर').toString();
    final jobType = (w['jobType'] ?? w['category'] ?? 'अन्य').toString();
    final district = (w['district'] ?? w['city'] ?? '').toString();
    final phone = (w['whatsapp'] ?? w['phone'] ?? '').toString();
    final exp = (w['experience'] ?? '').toString();
    final rating =
        (w['rating'] ?? w['avgRating'] ?? 0.0) as num;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'क',
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(jobType,
                      style: const TextStyle(
                          color: Color(0xFF1565C0), fontSize: 14)),
                  if (district.isNotEmpty)
                    Text('📍 $district',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                  if (exp.isNotEmpty)
                    Text('⏱ $exp अनुभव',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  if (rating > 0)
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                              i < rating.floor()
                                  ? Icons.star
                                  : i < rating
                                      ? Icons.star_half
                                      : Icons.star_border,
                              size: 14,
                              color: Colors.orange,
                            )),
                        Text(' ${rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange)),
                      ],
                    ),
                ],
              ),
            ),
            if (phone.isNotEmpty)
              ElevatedButton(
                onPressed: () => _openWhatsApp(phone),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat, size: 18),
                    Text('WA', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── HIRE REQUEST TAB ────────────────────────────────────────────────────────

class _HireRequestTab extends StatefulWidget {
  const _HireRequestTab();

  @override
  State<_HireRequestTab> createState() => _HireRequestTabState();
}

class _HireRequestTabState extends State<_HireRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  bool _showMyRequests = false;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _message = TextEditingController();
  String _jobType = 'Construction';
  int _workerCount = 1;

  final List<String> _jobTypes = [
    'Construction', 'Driver', 'Security Guard', 'Housekeeping',
    'Factory Worker', 'Farming', 'Cook', 'Plumber', 'Electrician',
    'Carpenter', 'Painter', 'Tailor', 'Other'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _firestore.collection('hire_requests').add({
        'employerName': _name.text.trim(),
        'phone': _phone.text.trim(),
        'jobType': _jobType,
        'location': _location.text.trim(),
        'workerCount': _workerCount,
        'message': _message.text.trim(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hire Request submitted! We will contact you soon.'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _jobType = 'Construction';
        _workerCount = 1;
        _showMyRequests = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF1565C0).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'हमें बताएं आपको किस तरह के Worker चाहिए — हम जल्द से जल्द connect करेंगे।',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF1565C0)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hire Request Form',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),
                    const Divider(height: 20),

                    // Name
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Your Name *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mobile required';
                        if (v.length != 10) return '10 digits required';
                        return null;
                      },
                    ),

                    // Job Type
                    DropdownButtonFormField<String>(
                      value: _jobType,
                      decoration: const InputDecoration(
                        labelText: 'Job Type *',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      items: _jobTypes
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _jobType = v!),
                    ),
                    const SizedBox(height: 12),

                    // Location
                    TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(
                        labelText: 'Location / Village *',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Location required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Worker Count
                    Row(
                      children: [
                        const Text('Workers needed:',
                            style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            if (_workerCount > 1) {
                              setState(() => _workerCount--);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$_workerCount',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _workerCount++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Message
                    TextFormField(
                      controller: _message,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Additional Requirements (optional)',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                        hintText:
                            'e.g. Experience needed, timing, salary range...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: Text(_loading
                            ? 'Submitting...'
                            : 'Send Hire Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // My submitted requests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Hire Requests',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () =>
                    setState(() => _showMyRequests = !_showMyRequests),
                child: Text(_showMyRequests ? 'Hide' : 'Show'),
              ),
            ],
          ),

          if (_showMyRequests && _phone.text.length == 10)
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('hire_requests')
                  .where('phone', isEqualTo: _phone.text.trim())
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No requests found for this number.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snap.data!.docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = snap.data!.docs[i].data()
                        as Map<String, dynamic>;
                    final status = r['status'] ?? 'Pending';
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(status).withOpacity(0.15),
                          child: Icon(Icons.handshake,
                              color: _statusColor(status)),
                        ),
                        title: Text(
                            '${r['jobType']} — ${r['workerCount']} worker(s)',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: Text(r['location'] ?? ''),
                        trailing: _statusBadge(status),
                      ),
                    );
                  },
                );
              },
            )
          else if (_showMyRequests)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                  'Request submit करने के बाद requests यहाँ दिखेंगी।',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Fulfilled':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(status).withOpacity(0.3)),
      ),
      child: Text(status,
          style: TextStyle(
              color: _statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
