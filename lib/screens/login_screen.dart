import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _findProfile() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) { setState(() => _error = 'Valid 10-digit number enter karein'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      // Search field_staff_registrations
      var q = await FirebaseFirestore.instance.collection('field_staff_registrations').where('phone', isEqualTo: phone).limit(1).get();
      if (q.docs.isNotEmpty) { await _save(phone,'field_staff',q.docs.first.id,q.docs.first.data()); return; }
      // Search gurkul_applications
      q = await FirebaseFirestore.instance.collection('gurkul_applications').where('phone', isEqualTo: phone).limit(1).get();
      if (q.docs.isNotEmpty) { await _save(phone,'gurkul',q.docs.first.id,q.docs.first.data()); return; }
      // Search workers
      q = await FirebaseFirestore.instance.collection('workers').where('phone', isEqualTo: phone).limit(1).get();
      if (q.docs.isNotEmpty) { await _save(phone,'worker',q.docs.first.id,q.docs.first.data()); return; }
      // Not found
      setState(() => _loading = false);
      _notFoundDialog(phone);
    } catch (e) { setState(() { _error = 'Error: ${e.toString().substring(0,50)}'; _loading = false; }); }
  }

  Future<void> _save(String phone, String type, String id, Map<String,dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_type', type);
    await prefs.setString('user_doc_id', id);
    await prefs.setString('user_name', data['name'] ?? data['fullName'] ?? '');
    if (mounted) Navigator.pushReplacementNamed(context, '/home', arguments: {'phone': phone, 'userType': type, 'docId': id, 'name': data['name'] ?? data['fullName'] ?? ''});
  }

  void _notFoundDialog(String phone) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [Icon(Icons.search_off, color: Colors.orange), SizedBox(width: 8), Text('Profile Nahi Mila')]),
      content: Text('+91 $phone ka koi profile nahi mila.\n\nKya aap register karna chahte hain?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
          onPressed: () { Navigator.pop(ctx); Navigator.pushReplacementNamed(context, '/home', arguments: {'phone': phone, 'userType': 'guest', 'docId': '', 'name': ''}); },
          child: const Text('Jobs Browse Karein'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: SingleChildScrollView(child: Column(children: [
        _header(),
        Padding(padding: const EdgeInsets.all(24), child: _form()),
      ]))),
    );
  }

  Widget _header() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 44, bottom: 32, left: 24, right: 24),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: Column(children: [
      Container(width: 78, height: 78,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0,4))]),
        child: const Icon(Icons.work_rounded, size: 42, color: Color(0xFF1565C0))),
      const SizedBox(height: 14),
      const Text('KaamDhanda', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Rozgaar Ka Sahi Platform', style: TextStyle(color: Colors.white70, fontSize: 14)),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _chip(Icons.work_outline, 'Jobs'),
        const SizedBox(width: 10),
        _chip(Icons.people_outline, 'Workers'),
        const SizedBox(width: 10),
        _chip(Icons.location_on_outlined, 'Nearby'),
      ]),
    ]),
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: Colors.white), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500))]),
  );

  Widget _form() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 16),
    const Text('Login / Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
    const SizedBox(height: 6),
    Text('Apna registered mobile number dalein', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
    const SizedBox(height: 24),
    Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.35))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.08), borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14))),
          child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontSize: 16)),
        ),
        Expanded(child: TextField(
          controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5),
          decoration: const InputDecoration(counterText: '', hintText: '00000 00000', hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, letterSpacing: 0.5), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
          onSubmitted: (_) => _findProfile(),
        )),
      ]),
    ),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [const Icon(Icons.info_outline, size: 13, color: Colors.red), const SizedBox(width: 4), Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))])),
    const SizedBox(height: 18),
    SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
      onPressed: _loading ? null : _findProfile,
      icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search, size: 20),
      label: Text(_loading ? 'Searching...' : 'Dashboard Dekhen', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 3),
    )),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, height: 46, child: OutlinedButton.icon(
      onPressed: () => Navigator.pushReplacementNamed(context, '/home', arguments: {'phone': '', 'userType': 'guest', 'docId': '', 'name': ''}),
      icon: const Icon(Icons.work_outline, size: 17),
      label: const Text('Jobs Browse Karein (Login ke bina)', style: TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1565C0), side: BorderSide(color: const Color(0xFF1565C0).withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    )),
    const SizedBox(height: 28),
    Row(children: [Expanded(child: Divider(color: Colors.grey[300])), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('Naya Registration', style: TextStyle(color: Colors.grey[500], fontSize: 12))), Expanded(child: Divider(color: Colors.grey[300]))]),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _regCard(Icons.person_outline, 'Worker', 'Kaam dhundna hai', Colors.green)),
      const SizedBox(width: 8),
      Expanded(child: _regCard(Icons.people_outline, 'Field Staff', 'Team manage karo', const Color(0xFF1565C0))),
      const SizedBox(width: 8),
      Expanded(child: _regCard(Icons.school_outlined, 'Gurkul', 'Students laao', Colors.purple)),
    ]),
    const SizedBox(height: 24),
    Center(child: Text('By continuing, you agree to our Terms of Service', style: TextStyle(fontSize: 10, color: Colors.grey[400]), textAlign: TextAlign.center)),
  ]);

  Widget _regCard(IconData icon, String title, String sub, Color color) => InkWell(
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 5), Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 2), Text(sub, style: TextStyle(fontSize: 9, color: Colors.grey[600]), textAlign: TextAlign.center)]),
    ),
  );
}