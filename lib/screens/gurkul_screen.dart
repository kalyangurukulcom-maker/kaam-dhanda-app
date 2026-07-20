import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GurkulScreen extends StatefulWidget {
  const GurkulScreen({super.key});

  @override
  State<GurkulScreen> createState() => _GurkulScreenState();
}

class _GurkulScreenState extends State<GurkulScreen>
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
      appBar: AppBar(
        title: const Text('Gurukul Sathi'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Registration'),
            Tab(text: 'Status Check'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RegistrationTab(),
          _StatusTab(),
        ],
      ),
    );
  }
}

// ââ Progress Step Widget ââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class _ProgressStep extends StatelessWidget {
  final int step;
  final String label;
  final bool done;

  const _ProgressStep({required this.step, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: done ? Colors.green : Colors.grey.shade300,
            child: Text(
              step.toString(),
              style: TextStyle(
                color: done ? Colors.white : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done ? Colors.green.shade700 : Colors.grey.shade600,
                fontWeight: done ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
          if (done) Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
        ],
      ),
    );
  }
}

// ââ Registration Tab ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class _RegistrationTab extends StatefulWidget {
  const _RegistrationTab();

  @override
  State<_RegistrationTab> createState() => _RegistrationTabState();
}

class _RegistrationTabState extends State<_RegistrationTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _umarCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _jila;
  String? _shiksha;
  String _anubhav = 'Fresher';
  bool _loading = false;
  bool _submitted = false;

  static const _jilaList = [
    'Garhwa', 'Palamu', 'Latehar', 'Chatra', 'Hazaribagh', 'Ranchi', 'à¤à¤¨à¥à¤¯'
  ];
  static const _shikshaList = [
    '10th Pass', '12th Pass', 'Graduate', 'Post Graduate'
  ];
  static const _anubhavList = ['Fresher', '1 à¤¸à¤¾à¤²', '2 à¤¸à¤¾à¤²', '3+ à¤¸à¤¾à¤²'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _umarCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jila == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('à¤à¥à¤ªà¤¯à¤¾ à¤à¤¿à¤²à¤¾ à¤à¥à¤¨à¥à¤'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_shiksha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('à¤à¥à¤ªà¤¯à¤¾ à¤¶à¤¿à¤à¥à¤·à¤¾ à¤à¥à¤¨à¥à¤'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final existing = await FirebaseFirestore.instance
          .collection('gurkul_applications')
          .where('phone', isEqualTo: _mobileCtrl.text.trim())
          .get();
      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('à¤¯à¤¹ à¤®à¥à¤¬à¤¾à¤à¤² à¤¨à¤à¤¬à¤° à¤ªà¤¹à¤²à¥ à¤¸à¥ à¤°à¤à¤¿à¤¸à¥à¤à¤° à¤¹à¥!'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _loading = false);
        }
        return;
      }
      await FirebaseFirestore.instance
          .collection('gurkul_applications')
          .add({
        'name': _nameCtrl.text.trim(),
        'phone': _mobileCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'district': _jila,
        'age': _umarCtrl.text.trim(),
        'education': _shiksha,
        'experience': _anubhav,
        'notes': _notesCtrl.text.trim(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _submitted = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Registration à¤à¤®à¤¾ à¤¹à¥ à¤à¤¯à¤¾!',                        
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Admin review à¤à¤°à¥à¤à¤à¥ à¤à¤° à¤à¤²à¥à¤¦ approve à¤à¤°à¥à¤à¤à¥à¥¤\nStatus check à¤à¤°à¤¨à¥ à¤à¥ à¤²à¤¿à¤ "Status Check" tab à¤ªà¤° à¤à¤¾à¤à¤à¥¤',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const _ProgressStep(step: 1, label: 'Registration Received â', done: true),
              const _ProgressStep(step: 2, label: 'Admin Review â³', done: false),
              const _ProgressStep(step: 3, label: 'Approval & Dashboard ð', done: false),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ð Gurukul Sathi Recruitment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'â¹30,000/à¤®à¤¾à¤¹ + Travel Allowance + Training',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Application Form',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 4),
            const Text('à¤¸à¤­à¥ * fields à¤­à¤°à¤¨à¤¾ à¤à¤°à¥à¤°à¥ à¤¹à¥', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'à¤ªà¥à¤°à¤¾ à¤¨à¤¾à¤® *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'à¤¨à¤¾à¤® à¤à¤°à¥à¤°à¥ à¤¹à¥' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 10) ? 'à¤¸à¤¹à¥ à¤®à¥à¤¬à¤¾à¤à¤² à¤¨à¤à¤¬à¤° à¤¡à¤¾à¤²à¥à¤' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _whatsappCtrl,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _jila,
              decoration: const InputDecoration(
                labelText: 'à¤à¤¿à¤²à¤¾ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _jilaList
                  .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                  .toList(),
              onChanged: (v) => setState(() => _jila = v),
              hint: const Text('-- à¤à¤¿à¤²à¤¾ à¤à¥à¤¨à¥à¤ --'),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _umarCtrl,
              decoration: const InputDecoration(
                labelText: 'à¤à¤®à¥à¤° *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'à¤à¤®à¥à¤° à¤à¤°à¥à¤°à¥ à¤¹à¥' : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _shiksha,
              decoration: const InputDecoration(
                labelText: 'à¤¶à¤¿à¤à¥à¤·à¤¾ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: _shikshaList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _shiksha = v),
              hint: const Text('-- à¤¶à¤¿à¤à¥à¤·à¤¾ à¤à¥à¤¨à¥à¤ --'),
            ),
            const SizedBox(height: 12),

            const Text(
              'à¤ªà¤¹à¤²à¥ à¤à¤¾ à¤à¤¨à¥à¤­à¤µ:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _anubhavList
                  .map((a) => ChoiceChip(
                        label: Text(a),
                        selected: _anubhav == a,
                        onSelected: (_) => setState(() => _anubhav = a),
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: _anubhav == a ? Colors.white : Colors.black87,
                          fontWeight: _anubhav == a ? FontWeight.bold : FontWeight.normal,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'à¤à¥à¤ à¤à¤° à¤¬à¤¤à¤¾à¤¨à¤¾ à¤¹à¥ (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text(
                  'Application Submit à¤à¤°à¥à¤',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ââ Status Check Tab ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class _StatusTab extends StatefulWidget {
  const _StatusTab();

  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab> {
  final _mobileCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  bool _notFound = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final phone = _mobileCtrl.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('à¤¸à¤¹à¥ à¤®à¥à¤¬à¤¾à¤à¤² à¤¨à¤à¤¬à¤° à¤¡à¤¾à¤²à¥à¤'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
      _notFound = false;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('gurkul_applications')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (!mounted) return;
      if (snap.docs.isEmpty) {
        setState(() {
          _notFound = true;
          _loading = false;
        });
      } else {
        setState(() {
          _result = snap.docs.first.data();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gurukul Sathi Login',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 4),
          const Text(
            'à¤à¤ªà¤¨à¤¾ registered mobile number à¤¡à¤¾à¤²à¥à¤',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mobileCtrl,
            decoration: const InputDecoration(
              labelText: 'Registered Mobile Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              hintText: '10-digit mobile number',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _checkStatus,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Dashboard à¤¦à¥à¤à¥à¤'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_notFound)
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.orange.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'à¤à¤¸ à¤¨à¤à¤¬à¤° à¤ªà¤° à¤à¥à¤ application à¤¨à¤¹à¥à¤ à¤®à¤¿à¤²à¥à¥¤\nà¤ªà¤¹à¤²à¥ "Registration" tab à¤®à¥à¤ à¤à¤¾à¤à¤° apply à¤à¤°à¥à¤à¥¤',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_result != null) _buildDashboard(_result!),
        ],
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'Pending').toString();
    final isApproved = status == 'Approved';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Application Status: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isApproved ? Colors.green.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _infoRow('à¤¨à¤¾à¤®', data['name']),
                _infoRow('à¤à¤¿à¤²à¤¾', data['district']),
                _infoRow('à¤¶à¤¿à¤à¥à¤·à¤¾', data['education']),
                _infoRow('à¤à¤¨à¥à¤­à¤µ', data['experience']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Progress steps
        const Text(
          'à¤à¤ªà¤à¥ Progress:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        _ProgressStep(step: 1, label: 'Registration Received â', done: true),
        _ProgressStep(step: 2, label: 'Admin Review â³', done: isApproved),
        _ProgressStep(step: 3, label: 'Approval & Dashboard ð', done: isApproved),

        if (!isApproved) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'â³ Admin Approval Pending à¤¹à¥',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1565C0)),
                  ),
                  SizedBox(height: 8),
                  Text('à¤à¤ªà¤à¥ application à¤¹à¤®à¥à¤ à¤®à¤¿à¤² à¤à¤ à¤¹à¥à¥¤ Admin review à¤à¤°à¥à¤à¤à¥ à¤à¤° à¤à¤²à¥à¤¦ approve à¤à¤°à¥à¤à¤à¥à¥¤'),
                  SizedBox(height: 4),
                  Text('ð Under Review â 24â48 Hours', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],

        if (isApproved) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Congratulations! ð',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text('à¤à¤ªà¤à¥ application Approved à¤¹à¥ à¤à¤ à¤¹à¥!'),
                  SizedBox(height: 4),
                  Text('à¤à¤¬ à¤à¤ª Jobs tab à¤®à¥à¤ à¤à¤¾à¤à¤° à¤¨à¥à¤à¤°à¥ à¤¢à¥à¤à¤¢ à¤¸à¤à¤¤à¥ à¤¹à¥à¤à¥¤'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label + ': ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text((value ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
