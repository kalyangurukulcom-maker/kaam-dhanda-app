import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FieldStaffScreen extends StatefulWidget {
  const FieldStaffScreen({super.key});
  @override
  State<FieldStaffScreen> createState() => _FieldStaffScreenState();
}

class _FieldStaffScreenState extends State<FieldStaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Registration form
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  bool _registered = false;
  User? _user;

  // District list
  final List<String> _districts = [
    'Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Purnia',
    'Darbhanga', 'Ara', 'Begusarai', 'Katihar', 'Munger',
    'Chapra', 'Hajipur', 'Siwan', 'Motihari', 'Samastipur',
    'Aurangabad', 'Buxar', 'Rohtas', 'Sitamarhi', 'Madhubani',
    'Other',
  ];
  String? _selectedDistrict;

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
    _phoneCtrl.dispose();
    _districtCtrl.dispose();
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
          _showMsg('Error: ${e.message}');
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
    if (_verificationId == null) return;
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
      _showMsg('OTP गलत है');
    }
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showMsg('पूरा नाम भरें');
      return;
    }
    if (_selectedDistrict == null) {
      _showMsg('जिला चुनें');
      return;
    }
    setState(() => _loading = true);
    try {
      await _firestore.collection('field_staff').add({
        'naam': _nameCtrl.text.trim(),
        'phone': _user?.phoneNumber ?? _phoneCtrl.text.trim(),
        'uid': _user?.uid ?? '',
        'jila': _selectedDistrict,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() { _registered = true; _loading = false; });
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
        title: const Text('Field Staff'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Register करें'),
            Tab(text: 'मेरे Candidates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegisterTab(),
          _buildCandidatesTab(),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    if (_registered) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Registration सफल ✓',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('आप Field Staff में registered हो गए'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('मेरे Candidates देखें'),
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
          const Text('Field Staff Registration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Phone: ${_user!.phoneNumber ?? ""}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          _buildField(_nameCtrl, 'पूरा नाम *', Icons.person),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              labelText: 'जिला / District *',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDistrict = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF1565C0),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register करें',
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

  Widget _buildCandidatesTab() {
    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Candidates देखने के लिए पहले Login करें'),
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
          .collection('field_staff_candidates')
          .where('staffUid', isEqualTo: _user!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('कोई candidate नहीं मिला'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final status = d['status'] ?? 'pending';
            final color = status == 'placed'
                ? Colors.green
                : status == 'rejected'
                    ? Colors.red
                    : Colors.orange;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(Icons.person, color: color),
                ),
                title: Text(d['naam'] ?? ''),
                subtitle: Text('जिला: ${d['jila'] ?? '-'}  |  Phone: ${d['phone'] ?? '-'}'),
                trailing: Chip(
                  label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)),
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
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
