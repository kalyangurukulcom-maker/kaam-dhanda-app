import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GurkulScreen extends StatefulWidget {
  const GurkulScreen({super.key});
  @override
  State<GurkulScreen> createState() => _GurkulScreenState();
}

class _GurkulScreenState extends State<GurkulScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _selectedCourse = 'Electrician';
  bool _loading = false;
  final _loginPhoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _verificationId;
  bool _otpSent = false;
  bool _loginLoading = false;
  final List<String> _courses = ['Electrician', 'Plumber', 'Carpenter', 'Welder', 'AC Technician', 'Mobile Repair'];

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabs.dispose(); _nameCtrl.dispose(); _phoneCtrl.dispose(); _ageCtrl.dispose(); _addressCtrl.dispose(); _loginPhoneCtrl.dispose(); _otpCtrl.dispose(); super.dispose(); }

  Future<void> _submitApplication() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and phone required'), backgroundColor: Colors.red)); return; }
    setState(() => _loading = true);
    try {
      await _firestore.collection('gurkul_applications').add({'name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(), 'age': _ageCtrl.text.trim(), 'address': _addressCtrl.text.trim(), 'course': _selectedCourse, 'status': 'Pending', 'uid': _auth.currentUser?.uid ?? '', 'createdAt': FieldValue.serverTimestamp()});
      _nameCtrl.clear(); _phoneCtrl.clear(); _ageCtrl.clear(); _addressCtrl.clear();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submit ✓'), backgroundColor: Colors.green)); _tabs.animateTo(1); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _sendOtp() async {
    final phone = _loginPhoneCtrl.text.trim();
    if (phone.length < 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid phone number enter carren'), backgroundColor: Colors.red)); return; }
    setState(() => _loginLoading = true);
    try {
      await _auth.verifyPhoneNumber(phoneNumber: '+91$phone', verificationCompleted: (c) async { await _auth.signInWithCredential(c); if (mounted) setState(() => _loginLoading = false); }, verificationFailed: (e) { if (mounted) { setState(() => _loginLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red)); } }, codeSent: (id, _) { if (mounted) setState(() { _verificationId = id; _otpSent = true; _loginLoading = false; }); }, codeAutoRetrievalTimeout: (id) { _verificationId = id; });
    } catch (e) { if (mounted) { setState(() => _loginLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); } }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpCtrl.text.trim().isEmpty) return;
    setState(() => _loginLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: _otpCtrl.text.trim());
      await _auth.signInWithCredential(credential);
      if (mounted) { setState(() { _loginLoading = false; _otpSent = false; }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful ✓'), backgroundColor: Colors.green)); }
    } catch (e) { if (mounted) { setState(() => _loginLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wrong OTP: $e'), backgroundColor: Colors.red)); } }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gurkul Sathi'), backgroundColor: Colors.purple[700], foregroundColor: Colors.white, bottom: TabBar(controller: _tabs, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60, tabs: const [Tab(text: 'Apply'), Tab(text: 'Login / Status')])),
      body: TabBarView(controller: _tabs, children: [
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Gurkul Apply', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'पूरा नाम&प *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ऊम्र*', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'पता', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _selectedCourse, decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()), items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) setState(() => _selectedCourse = v); }),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _submitApplication, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Application', style: TextStyle(fontSize: 16)))),
        ])),
        StreamBuilder<User?>(stream: _auth.authStateChanges(), builder: (context, authSnap) {
          if (authSnap.data != null) {
            return StreamBuilder<QuerySnapshot>(stream: _firestore.collection('gurkul_applications').where('uid', isEqualTo: authSnap.data!.uid).orderBy('createdAt', descending: true).snapshots(), builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('कोई application नहीं मिली'));
              return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (context, i) {
                final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                return Card(margin: const EdgeInsets.all(12), child: ListTile(title: Text(d['name'] ?? ''), subtitle: Text('Course: ${d['course']}'), trailing: Chip(label: Text(d['status'] ?? 'Pending'), backgroundColor: d['status'] == 'Selected' ? Colors.green[100] : Colors.orange[100])));
              });
            });
          }
          return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
            const Text('अपना Status देखें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _loginPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixText: '+91 ')),
            const SizedBox(height: 12),
            if (_otpSent) ...[TextField(controller: _otpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder())), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loginLoading ? null : _verifyOtp, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), child: _loginLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify OTP')))]
            else ...[SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loginLoading ? null : _sendOtp, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), child: _loginLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('OTP Send Karo')))],
          ]));
        }),
      ]),
    );
  }
}
