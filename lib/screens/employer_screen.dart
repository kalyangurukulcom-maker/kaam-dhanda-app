import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

class EmployerScreen extends StatefulWidget {
  const EmployerScreen({super.key});
  @override
  State<EmployerScreen> createState() => _EmployerScreenState();
}

class _EmployerScreenState extends State<EmployerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey,
      appBar: AppBar(
        title: const Text('नियोक्ता पैनल', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppTheme.orange,
          tabs: const [Tab(text: '+ नई नौकरी पोस्ट'), Tab(text: 'मेरी नौकरियां')],
        ),
      ),
      body: TabBarView(controller: _tabs, children: const [_PostJobTab(), _MyJobsTab()]),
    );
  }
}

// ── POST JOB TAB ─────────────────────────────────────────────────────────────
class _PostJobTab extends StatefulWidget {
  const _PostJobTab();
  @override
  State<_PostJobTab> createState() => _PostJobTabState();
}

class _PostJobTabState extends State<_PostJobTab> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _salary = TextEditingController();
  final _whatsapp = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'local';
  String _category = 'अन्य';
  bool _urgent = false;
  bool _loading = false;

  static const _categories = ['मजद', 'ड्राइवर', 'सिक्य', 'दुकान', 'इलेक्ट', 'फैक्ट', 'डिलीवरी', 'कंस', 'कुक', 'नर्स', 'वेल्डर', 'सफाई', 'अन्य'];

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = AuthService.currentUser;
    final ok = await JobService.postJob({
      'title': _title.text.trim(),
      'company': _company.text.trim(),
      'location': _location.text.trim(),
      'city': _location.text.trim(),
      'state': '',
      'salary': _salary.text.trim(),
      'salaryPeriod': 'माह',
      'type': _type,
      'category': _category,
      'description': _desc.text.trim(),
      'whatsappNumber': _whatsapp.text.trim(),
      'contactPhone': _whatsapp.text.trim(),
      'postedBy': user?.uid ?? '',
      'isUrgent': _urgent,
      'requirements': [],
      'savedBy': [],
    });
    setState(() => _loading = false);
    if (ok && mounted) {
      _form.currentState!.reset();
      _title.clear(); _company.clear(); _location.clear(); _salary.clear(); _whatsapp.clear(); _desc.clear();
      setState(() { _urgent = false; _type = 'local'; _category = 'अन्य'; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ नौकरी पोस्ट हो गई! लोग अब apply कर सकते हैं।'),
        backgroundColor: AppTheme.green, duration: Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header(),
          const SizedBox(height: 16),
          _card([
            _sectionLabel('नौकरी का प्रकार'),
            Row(children: [
              _typeBtn('local', '🏠 लोकल (यहीं पास)'),
              const SizedBox(width: 10),
              _typeBtn('bahar', '✈️ बाहर (दूसरth: 10),
              _typeBtn('bahar', '✈️ बाहर (दूसरे राज्य)'),
            ]),
          ]),
          const SizedBox(height: 12),
          _card([
            _field(_title, 'नौकरी का नाम *', Icons.work_outline, required: true, hint: 'जैसे: ड्राइवर, सिक्योरिटी गार्ड'),
            const SizedBox(height: 12),
            _field(_company, 'कंपनी / दुकान का नाम', Icons.business_outlined, hint: 'जैसे: रामू ट्रांसपोर्ट'),
            const SizedBox(height: 12),
            _sectionLabel('श्रेणी चुनें'),
            Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) => GestureDetector(
              onTap: () => setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _category == c ? AppTheme.orange : AppTheme.grey, borderRadius: BorderRadius.circular(20)),
                child: Text(c, style: TextStyle(color: _category == c ? Colors.white : AppTheme.textGrey, fontWeight: _category == c ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
              ),
            )).toList()),
          ]),
          const SizedBox(height: 12),
          _card([
            _field(_location, 'जगह / पता *', Icons.location_on_outlined, required: true, hint: 'जैसे: रांची, झारखंड'),
            const SizedBox(height: 12),
            _field(_salary, 'सैलरी (₹/माह) *', Icons.currency_rupee, required: true, hint: 'जैसे: 15000', type: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(value: _urgent, onChanged: (v) => setState(() => _urgent = v!), activeColor: Colors.red),
              const Text('🔥 अर्जेंट भर्ती (लोगों को जल्दी दिखेगा)', style: TextStyle(fontSize: 13)),
            ]),
          ]),
          const SizedBox(height: 12),
          _card([
            _field(_whatsapp, 'WhatsApp नंबर *', Icons.phone_outlined, required: true, hint: '10 अंकों का नंबर', type: TextInputType.phone),
            const SizedBox(height: 4),
            const Text('* आवेदक इसी नंबर पर WhatsApp करेंगे', style: TextStyle(color: AppTheme.textGrey, fontSize: 11)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'नौकरी की जानकारी (वैकल्पिक)', prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true, hintText: 'काम क्या करना है, समय, सुविधाएं...'),
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('🚀  नौकरी पोस्ट करें', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.navy, Color(0xFF2D3561)]), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('नई नौकरी पोस्ट करें', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('हजारों नौकरी खोजने वाले तक पहुंचें — बिल्कुल मुफ्त', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
    ]),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _typeBtn(String val, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _type = val),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _type == val ? AppTheme.orange : AppTheme.grey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _type == val ? AppTheme.orange : Colors.transparent),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: _type == val ? Colors.white : AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ),
  );

  Widget _sectionLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)));

  Widget _field(TextEditingController c, String label, IconData icon, {bool required = false, String? hint, TextInputType? type}) =>
    TextFormField(
      controller: c,
      keyboardType: type,
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label डालना जरूरी है' : null : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), hintText: hint),
    );
}

// ── MY JOBS TAB ───────────────────────────────────────────────────────────────
class _MyJobsTab extends StatelessWidget {
  const _MyJobsTab();

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.uid ?? '';
    return StreamBuilder<List<JobModel>>(
      stream: JobService.myPostedJobs(userId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.orange));
        final jobs = snap.data ?? [];
        if (jobs.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('अभी कोई नौकरी पोस्ट नहीं की', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('"नई नौकरी पोस्ट" tab से डालें', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
        ]));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (_, i) {
            final j = jobs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(j.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${j.location} • ₹${j.salary}/माह', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${j.applicants} आवेदन', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 13)),
                ])),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                      title: const Text('नौकरी हटाएं?'), content: Text('${j.title} हटाना चाहते हैं?'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('नहीं')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('हाँ', style: TextStyle(color: Colors.red)))],
                    ));
                    if (ok == true) await JobService.deleteJob(j.id);
                  },
                ),
              ]),
            );
          },
        );
      },
    );
  }
}
