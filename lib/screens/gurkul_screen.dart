import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GurkulScreen extends StatefulWidget {
  const GurkulScreen({super.key});
  @override
  State<GurkulScreen> createState() => _GurkulScreenState();
}

class _GurkulScreenState extends State<GurkulScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form fields
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  bool _submitted = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _user = _auth.currentUser;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _showMsg('Valid phone number दर्ज करें');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential cred) async {
          await _auth.signInWithCredential(cred);
          setState(() { _user = _auth.currentUser; _loading = false; });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _loading = false);
          _showMsg('OTP भेजने में error: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });
          _showMsg('OTP भेजा गया ✓');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      _showMsg('Error: $e');
    }
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null || _otpCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      final result = await _auth.signInWithCredential(cred);
      setState(() { _user = result.user; _loading = false; });
      _showMsg('Login सफल ✓');
    } catch (e) {
      setState(() => _loading = false);
      _showMsg('OTP गलत है, दोबारा try करें');
    }
  }

  Future<void> _submitApplication() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showMsg('पूरा नाम भरें');
      return;
    }
    setState(() => _loading = true);
    try {
      await _firestore.collection('gurkul_applications').add({
        'naam': _nameCtrl.text.trim(),
        'umra': _ageCtrl.text.trim(),
        'pata': _addressCtrl.text.trim(),
        'phone': _user?.phoneNumber ?? _phoneCtrl.text.trim(),
        'uid': _user?.uid ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() { _submitted = true; _loading = false; });
      _nameCtrl.clear();
      _ageCtrl.clear();
      _addressCtrl.clear();
    } catch (e) {
      setState(() => _loading = false);
      _showMsg('Error: $e');
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gurkul Sathi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gurkul में Apply करें'),
            Tab(text: 'अपना Status देखें'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplyTab(),
          _buildStatusTab(),
        ],
      ),
    );
  }

  Widget _buildApplyTab() {
    if (_submitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Application submit हो गया ✓',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('हम जल्द ही संपर्क करेंगे'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _submitted = false),
              child: const Text('नई Application भेजें'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return _buildLoginSection();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gurkul Application Form',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Phone: ${_user!.phoneNumber ?? ""}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          _buildField(_nameCtrl, 'पूरा नाम *', Icons.person),
          const SizedBox(height: 12),
          _buildField(_ageCtrl, 'उम्र', Icons.cake, inputType: TextInputType.number),
          const SizedBox(height: 12),
          _buildField(_addressCtrl, 'पता', Icons.location_on, maxLines: 2),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF1565C0),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Application भेजें',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Login करें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildField(_phoneCtrl, 'Phone Number', Icons.phone,
              inputType: TextInputType.phone),
          const SizedBox(height: 12),
          if (_otpSent) ...[
            _buildField(_otpCtrl, 'OTP दर्ज करें', Icons.lock,
                inputType: TextInputType.number),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : (_otpSent ? _verifyOTP : _sendOTP),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF1565C0),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_otpSent ? 'OTP Verify करें' : 'OTP भेजें',
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    final phone = _user?.phoneNumber ?? '';
    if (phone.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Status देखने के लिए पहले Login करें'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Login करें'),
            ),
          ],
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('gurkul_applications')
          .where('uid', isEqualTo: _user!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('कोई application नहीं मिला'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final status = d['status'] ?? 'pending';
            final color = status == 'approved'
                ? Colors.green
                : status == 'rejected'
                    ? Colors.red
                    : Colors.orange;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(Icons.school, color: color),
                ),
                title: Text(d['naam'] ?? ''),
                subtitle: Text('उम्र: ${d['umra'] ?? '-'}  |  पता: ${d['pata'] ?? '-'}'),
                trailing: Chip(
                  label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: color,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
