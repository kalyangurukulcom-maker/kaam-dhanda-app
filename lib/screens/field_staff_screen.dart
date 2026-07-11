// ══════════════════════════════════════════════════════════════
//  Field Staff Registration Screen — same as field-staff.html
//  App → Firebase → Admin panel website पर दिखता है
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class FieldStaffScreen extends StatefulWidget {
  const FieldStaffScreen({super.key});
  @override
  State<FieldStaffScreen> createState() => _FieldStaffScreenState();
}

class _FieldStaffScreenState extends State<FieldStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _submitted = false;

  final _name      = TextEditingController();
  final _phone     = TextEditingController();
  final _remark    = TextEditingController();

  String _district       = 'गढ़वा';
  String _role           = 'Field Executive';
  String _experience     = '1 साल';
  String _language       = 'Hindi';
  String _qualification  = 'ग्रेजुएट';
  String _hasVehicle     = 'no';

  static const _districts = [
    'गढ़वा','पलामू','लातेहार','चतरा','हजारीबाग','रांची',
    'बोकारो','धनबाद','गिरिडीह','दुमका','देवघर','अन्य'
  ];
  static const _roles = [
    'Field Executive','Sales Executive','Mobilization Executive',
    'Supervisor','Team Leader','Data Entry Operator','Office Assistant','अन्य'
  ];
  static const _experiences  = ['Fresher','6 महीने','1 साल','2 साल','3+ साल'];
  static const _languages    = ['Hindi','Hindi + English','Hindi + Regional','All'];
  static const _qualifs      = ['12वीं पास','ग्रेजुएट','Post Graduate','Diploma','अन्य'];

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _remark.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseService.submitFieldStaffRegistration(
        name:          _name.text.trim(),
        phone:         _phone.text.trim(),
        district:      _district,
        role:          _role,
        experience:    _experience,
        language:      _language,
        qualification: _qualification,
        hasVehicle:    _hasVehicle,
        remark:        _remark.text.trim(),
      );
      setState(() { _loading = false; _submitted = true; });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                        child: const Text(
                          '🎯 Field Staff Registration',
                          style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Field Staff\nKaamDhanda.in',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _submitted ? _buildSuccess() : _buildForm()),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)],
      ),
      child: Column(
        children: [
          const Icon(Icons.how_to_reg, color: Color(0xFF2E7D32), size: 64),
          const SizedBox(height: 16),
          const Text('Application Submit! ✅', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'आपकी Field Staff application submit हो गई।\nHR team 24-48 hours में contact करेगी।',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Home पर जाएं'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯 Field Staff Form', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 4),
                  const Text('सभी * fields अनिवार्य हैं', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),

                  _field(_name, '👤 पूरा नाम *', 'जैसे: सुनीता देवी'),
                  _field(_phone, '📱 Mobile *', '10 अंक', type: TextInputType.phone, max: 10),
                  _drop('🎯 Role/पद *', _roles, _role, (v) => setState(() => _role = v!)),
                  _drop('📍 जिला *', _districts, _district, (v) => setState(() => _district = v!)),
                  _drop('💼 अनुभव *', _experiences, _experience, (v) => setState(() => _experience = v!)),
                  _drop('🎓 Qualification *', _qualifs, _qualification, (v) => setState(() => _qualification = v!)),
                  _drop('🗣️ भाषा *', _languages, _language, (v) => setState(() => _language = v!)),

                  // Vehicle toggle
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('🏍️ अपना Vehicle है?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        Switch(
                          value: _hasVehicle == 'yes',
                          onChanged: (v) => setState(() => _hasVehicle = v ? 'yes' : 'no'),
                          activeColor: const Color(0xFF1B5E20),
                        ),
                        Text(_hasVehicle == 'yes' ? 'हाँ' : 'नहीं',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _hasVehicle == 'yes' ? const Color(0xFF1B5E20) : Colors.grey,
                          )),
                      ],
                    ),
                  ),

                  _field(_remark, '📝 कोई बात', 'कोई विशेष जानकारी...', required: false, lines: 3),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('📤 Apply करें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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

  Widget _field(TextEditingController ctrl, String label, String hint, {
    TextInputType type = TextInputType.text, int max = 100, int lines = 1, bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl, keyboardType: type, maxLength: max, maxLines: lines,
            decoration: InputDecoration(
              hintText: hint, counterText: '',
              filled: true, fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: required ? (v) => v == null || v.trim().isEmpty ? 'जरूरी है' : null : null,
          ),
        ],
      ),
    );
  }

  Widget _drop(String label, List<String> items, String val, void Function(String?) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: val,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChange,
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}
