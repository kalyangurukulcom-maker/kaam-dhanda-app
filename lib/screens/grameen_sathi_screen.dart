import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class GrameenSathiScreen extends StatefulWidget {
  const GrameenSathiScreen({super.key});
  @override
  State<GrameenSathiScreen> createState() => _GrameenSathiScreenState();
}

class _GrameenSathiScreenState extends State<GrameenSathiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  String _selectedService = 'Job Placement';
  bool _loading = false;

  final List<String> _services = ['Job Placement', 'Gurkul Admission', 'Worker Registration', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLead() async {
    final user = _auth.currentUser;
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone required'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _firestore.collection('grameen_sathi_leads').add({
        'sathiUid': user?.uid ?? '',
        'sathiPhone': user?.phoneNumber ?? '',
        'leadName': _nameCtrl.text.trim(),
        'leadPhone': _phoneCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'service': _selectedService,
        'status': 'New',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _villageCtrl.clear();
      _districtCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead जमा हो गया ✓'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grameen Sathi'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'New Lead'), Tab(text: 'My Leads')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('नया Lead जोडें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Lead का नाम *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Lead का $Phone *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _villageCtrl,
                  decoration: const InputDecoration(labelText: 'गाँव', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(labelText: 'जिला', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(labelText: 'Service', border: OutlineInputBorder()),
                  items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedService = v); },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitLead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Lead Submit करें', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          user == null
              ? const Center(child: Text('Please login first'))
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('grameen_sathi_leads')
                      .where('sathiUid', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(child: Text('कोई lead नहीं मिला'));
                    }
                    final docs = snap.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            title: Text(d['leadName'] ?? ''),
                            subtitle: Text('${d['leadPhone']} • ${d['service']}'),
                            trailing: Chip(
                              label: Text(d['status'] ?? 'New'),
                              backgroundColor: d['status'] == 'Converted'
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                            ),
                            onTap: () async {
                              final phone = d['leadPhone'];
                              if (phone != null && phone.isNotEmpty) {
                                final uri = Uri.parse('https://wa.me/91$phone');
                                if (await canLaunchUrl(uri)) launchUrl(uri);
                              }
                            },
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
