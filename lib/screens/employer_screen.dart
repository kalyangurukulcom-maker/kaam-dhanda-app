import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerScreen extends StatefulWidget {
  const EmployerScreen({super.key});
  @override
  State<EmployerScreen> createState() => _EmployerScreenState();
}

class _EmployerScreenState extends State<EmployerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Form fields
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _workersCtrl = TextEditingController();
  String _selectedJobType = 'ड्राइवर';
  bool _isLocal = true;
  bool _submitting = false;

  // Browse workers
  List<Map<String, dynamic>> _workers = [];
  bool _loadingWorkers = true;
  String _filterCat = 'सभी';

  static const List<String> _jobTypes = [
    'ड्राइवर', 'निर्माण', 'सिक्योरिटी', 'द����W��������(�������लेक्ट्रीशियन', 'फैक्ट्री', 'डिलीवरी', 'होटल', 'अन्य',
  ];

  static const List<String> _filterCats = [
    'सभी', 'ड्राइवर', 'निर्माण', 'सिक्योरिटी', 'दुकान',
    'इलेक्ट्रीशियन', 'फैक्ट्री', 'डिलीवरी', 'होटल', 'अन्य',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWorkers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _salaryCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _workersCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loadingWorkers = true);
    try {
      // NO where('isActive') filter — website saves 'available', not 'isActive'
      final snap = await _db.collection('workers').limit(100).get();
      _workers = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      _workers = [];
    }
    setState(() => _loadingWorkers = false);
  }

  List<Map<String, dynamic>> get _filteredWorkers {
    if (_filterCat == 'सभी') return _workers;
    return _workers.where((w) {
      final jt = (wW'jobType'] ?? w['category'] ?? '').toString().toLowerCase();
      return jt.contains(_filterCat.toLowerCase());
    }).toList();
  }

  Future<void> _postJob() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया नौकरी का नाम भरें')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = _auth.currentUser;
      await _db.collection('jobs').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'jobType': _selectedJobType,
        'salary': _salaryCtrl.text.trim(),
        'district': _locationCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'workersNeeded': int.tryParse(_workersCtrl.text.trim()) ?? 1,
        'isLocal': _isLocal,
        'uid': user?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      _titleCtrl.clear();
      _descCtrl.clear();
      _salaryCtrl.clear();
      _locationCtrl.clear();
      _phoneCtrl.clear();
      _workersCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ नौकरी पोस्ट हो गई!'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('गड़बड़ी: $e')),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('💼 नियोक्ता (Employer)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '📝 नौकरी पोस्ट करें'),
            Tab(text: '👷 कारीगर खोजें'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostJobTab(),
          _buildBrowseWorkersTab(),
        ],
      ),
    );
  }

  Widget _buildPostJobTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('नौकरी की जानकारी',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _field(_titleCtrl, 'नौकरी का नाम *', Icons.work),
                  const SizedBox(height: 12),
                  _field(_descCtrl, 'काम का विवरण', Icons.description, maxLines: 3),
                  const SizedBox(height: 12),
                  // Job type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedJobType,
                    decoration: InputDecoration(
                      labelText: 'काम का प्रकार',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true, fillColor: Colors.grey.shade50,
                    ),
                    items: _jobTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedJobType = v!),
                  ),
                  const SizedBox(height: 12),
                  _field(_salaryCtrl, 'वेतन (जैसे: 12000-15000)', Icons.currency_rupee),
                  const SizedBox(height: 12),
                  _field(_locationCtrl, 'जिला / शहर', Icons.location_on),
                  const SizedBox(height: 12),
                  _field(_phoneCtrl, 'संपर्क नंबर', Icons.phone),
                  const SizedBox(height: 12),
                  _field(_workersCtrl, 'कितने कारीगर चाहिए', Icons.people,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  // Local / Bahar toggle
                  Row(
                    children: [
                      const Icon(Icons.location_city, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('नौकरी कहां है?'),
                      const Spacer(),
                      ToggleButtons(
                        isSelected: [_isLocal, !_isLocal],
                        onPressed: (i) => setState(() => _isLocal = i == 0),
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: const Color(0xFF1565C0),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('🏠 लोकल'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('✈️ बाहर'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _postJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('✅ नौकरी पोस्ट करें',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildBrowseWorkersTab() {
    final workers = _filteredWorkers;
    return Column(
      children: [
        // Category filter
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: _filterCats.length,
            itemBuilder: (_, i) {
              final c = _filterCats[i];
              final sel = c == _filterCat;
              return GestureDetector(
                onTap: () => setState(() => _filterCat = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF1565C0) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1565C0)),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: sel ? Colors.white : const Color(0xFF1565C0),
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _loadingWorkers
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
              : workers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('कोई कारीगर नहीं मिला',
                              style: TextStyle(color: Colors.grey)),
                          TextButton(onPressed: _loadWorkers, child: const Text('फिर से खोजें')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: workers.length,
                      itemBuilder: (_, i) {
                        final w = workers[i];
                        final name = (w['name'] ?? 'कारीगर').toString();
                        // Use jobType, not category
                        final jt = (w['jobType'] ?? w['category'] ?? '').toString();
                        final loc = (w['district'] ?? w['city'] ?? '').toString();
                        final phone = (w['whatsapp'] ?? w['phone'] ?? '').toString();
                        final avail = w['available'];
                        final isAvail = avail == null ? true : (avail is bool ? avail : avail.toString() == 'true');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'क',
                                style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (jt.isNotEmpty)
                                  Text(jt,
                                      style: const TextStyle(
                                          color: Color(0xFF1565C0), fontSize: 12)),
                                if (loc.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 12, color: Colors.grey),
                                      Text(loc,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: phone.isNotEmpty
                                ? ElevatedButton(
                                    onPressed: () async {
                                      final ph = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                      final num = ph.startsWith('91') && ph.length > 10 ? ph : '91$ph';
                                      final uri = Uri.parse('https://wa.me/$num');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('WA', style: TextStyle(fontSize: 11)),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
