import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class FieldStaffScreen extends StatefulWidget {
  const FieldStaffScreen({super.key});
  @override
  State<FieldStaffScreen> createState() => _FieldStaffScreenState();
}

class _FieldStaffScreenState extends State<FieldStaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  String _selectedSkill = 'Electrician';
  bool _loading = false;
  final List<String> _skills = ['Electrician', 'Plumber', 'Carpenter', 'Mason', 'Painter', 'Welder', 'Driver', 'Security', 'Cook', 'Other'];

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabs.dispose(); _nameCtrl.dispose(); _phoneCtrl.dispose(); _districtCtrl.dispose(); _experienceCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    final user = _auth.currentUser;
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and phone required'), backgroundColor: Colors.red)); return; }
    setState(() => _loading = true);
    try {
      await _firestore.collection('field_staff_registrations').add({'Name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(), 'district': _districtCtrl.text.trim(), 'experience': _experienceCtrl.text.trim(), 'skill': _selectedSkill, 'uid': user?.uid ?? '', 'status': 'Active', 'available': true, 'rating': 0.0, 'createdAt': FieldValue.serverTimestamp()});
      _nameCtrl.clear(); _phoneCtrl.clear(); _districtCtrl.clear(); _experienceCtrl.clear();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful ✓'), backgroundColor: Colors.green)); _tabs.animateTo(1); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Field Staff'), backgroundColor: Colors.orange[800], foregroundColor: Colors.white, bottom: TabBar(controller: _tabs, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60, tabs: const [Tab(text: 'Register'), Tab(text: 'My Candidates')])),
      body: TabBarView(controller: _tabs, children: [
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Field Staff Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'पूरा नाम' *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _experienceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Experience (Years)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _selectedSkill, decoration: const InputDecoration(labelText: 'Skill', border: OutlineInputBorder()), items: _skills.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) setState(() => _selectedSkill = v); }),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register', style: TextStyle(fontSize: 16)))),
        ])),
        user == null ? const Center(child: Text('Please login first')) : StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('field_staff_candidates').where('addedByUid', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('कोई candidate नहीं मिला'));
            return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (context, i) {
              final d = snap.data!.docs[i].data() as Map<String, dynamic>;
              final status = d['status'] ?? 'Active';
              return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.orange[200], child: Text((d['name'] ?? '?')[0].toUpperCase())), title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${d['skill'] ?? ''} • ${d['district'] ?? ''}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Chip(label: Text(status, style: const TextStyle(fontSize: 10)), backgroundColor: status == 'Active' ? Colors.green[100] : Colors.grey[200]), IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () async { final phone = d['phone']; if (phone != null && phone.isNotEmpty) { final uri = Uri.parse('tel:$phone'); if (await canLaunchUrl(uri)) launchUrl(uri); } })]), isThreeLine: false));
            });
          },
        ),
      ]),
    );
  }
}
