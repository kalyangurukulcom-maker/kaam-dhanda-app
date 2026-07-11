// ══════════════════════════════════════════════════════════════
//  Gurkul Sathi Screen — Apply + Login Tabs
//  Apply → Firebase → Admin panel website पर दिखता है
//  Login → Phone lookup → Dashboard (Registration/Training/Placement/Payment)
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'gurkul_dashboard_screen.dart';

class GurkulScreen extends StatefulWidget {
  const GurkulScreen({super.key});
  @override
  State<GurkulScreen> createState() => _GurkulScreenState();
}

class _GurkulScreenState extends State<GurkulScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFFFFD600),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: const [
                Tab(text: '📋 Apply करें'),
                Tab(text: '🔐 Gurukul Sathi Login'),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🔥 तुरंत भर्ती — सीमित 10 सीटें',
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gurkul Sathi Program',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: const [
            _ApplyTab(),
            _LoginTab(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  APPLY TAB
// ══════════════════════════════════════════════════════════════
class _ApplyTab extends StatefulWidget {
  const _ApplyTab();
  @override
  State<_ApplyTab> createState() => _ApplyTabState();
}

class _ApplyTabState extends State<_ApplyTab> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _submitted = false;

  final _name   = TextEditingController();
  final _phone  = TextEditingController();
  final _age    = TextEditingController();
  final _remark = TextEditingController();

  String _district   = 'गढ़वा';
  String _education  = '10वीं पास';
  String _experience = 'कोई अनुभव नहीं';

  static const _districts  = ['गढ़वा','पलामू','लातेहार','चतरा','हजारीबाग','रांची','बोकारो','धनबाद','गिरिडीह','दुमका','देवघर','अन्य'];
  static const _educations = ['8वीं पास','10वीं पास','12वीं पास','ग्रेजुएट','अन्य'];
  static const _experiences= ['कोई अनुभव नहीं','6 महीने','1 साल','2 साल','3+ साल'];

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _age.dispose(); _remark.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseService.submitGurkulApplication(
        name:       _name.text.trim(),
        phone:      _phone.text.trim(),
        district:   _district,
        age:        _age.text.trim(),
        education:  _education,
        experience: _experience,
        remark:     _remark.text.trim(),
      );
      setState(() { _loading = false; _submitted = true; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Salary Strip
            _SalaryCard(),
            const SizedBox(height: 12),
            // Form
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋 Application Form',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
                  const SizedBox(height: 4),
                  const Text('सभी * fields भरना अनिवार्य है', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 18),
                  _input(_name,  '👤 पूरा नाम *', 'जैसे: राम कुमार शर्मा'),
                  _input(_phone, '📱 Mobile Number *', '10 अंकों का नंबर', type: TextInputType.phone, maxLen: 10),
                  _input(_age,   '🎂 उम्र *', 'जैसे: 25', type: TextInputType.number, maxLen: 2),
                  _drop('📍 जिला *', _districts,  _district,   (v) => setState(() => _district   = v!)),
                  _drop('🎓 शिक्षा *', _educations, _education,  (v) => setState(() => _education  = v!)),
                  _drop('💼 अनुभव *', _experiences,_experience,(v) => setState(() => _experience = v!)),
                  _input(_remark, '📝 कोई बात (Optional)', 'कोई विशेष जानकारी...', required: false, maxLines: 3),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('📤 Form Submit करें',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _Card(
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Application Submit हो गई! ✅',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('हम 24 घंटे के भीतर आपसे WhatsApp/Call पर संपर्क करेंगे।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            _SalaryCard(),
            const SizedBox(height: 20),
            const Text('अपनी Application का status check करने के लिए\n"Gurukul Sathi Login" tab पर जाएं',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, String hint, {
    TextInputType type = TextInputType.text, int maxLen = 100, int maxLines = 1, bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl, keyboardType: type, maxLength: maxLen, maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), counterText: '',
            filled: true, fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: required ? (v) => v == null || v.trim().isEmpty ? 'यह field जरूरी है' : null : null,
        ),
      ]),
    );
  }

  Widget _drop(String label, List<String> items, String val, void Function(String?) cb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: val, onChanged: cb,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LOGIN TAB
// ══════════════════════════════════════════════════════════════
class _LoginTab extends StatefulWidget {
  const _LoginTab();
  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _phone.dispose(); super.dispose(); }

  Future<void> _login() async {
    final ph = _phone.text.trim();
    if (ph.length != 10) {
      setState(() => _error = '10 अंक का valid number डालें');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await FirebaseService.gurkulLogin(ph);
      if (!mounted) return;
      if (data == null) {
        setState(() { _loading = false; _error = 'इस number से application नहीं मिली। पहले Apply करें।'; });
        return;
      }
      setState(() => _loading = false);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => GurkulDashboardScreen(data: data),
      ));
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.15)),
            ),
            child: const Text(
              '📱 अपने registered mobile number से login करें और अपनी application का पूरा status देखें — Registration, Training, Placement, Payment सब कुछ।',
              style: TextStyle(fontSize: 13, color: Color(0xFF1A237E), fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔐 Gurukul Sathi Login',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
                const SizedBox(height: 18),
                const Text('📱 Mobile Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    hintText: 'जिस number से Apply 
किया था',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    counterText: '',
                    filled: true, fillColor: const Color(0xFFF8F9FC),
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF1A237E), size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: