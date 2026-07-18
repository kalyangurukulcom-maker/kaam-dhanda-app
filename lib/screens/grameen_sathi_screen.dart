import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class GrameenSathiScreen extends StatefulWidget {
  final String? userId;
  const GrameenSathiScreen({super.key, this.userId});
  @override
  State<GrameenSathiScreen> createState() => _GrameenSathiScreenState();
}

class _GrameenSathiScreenState extends State<GrameenSathiScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _uid;
  Map<String,dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (_uid != null) _loadProfile();
    else setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('gurkul_applications').doc(_uid).get();
      if (doc.exists) setState(() { _profile = doc.data(); _loading = false; });
      else setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))));
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Grameen Sathi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Dashboard'), Tab(text: 'My Workers'), Tab(text: 'Earnings')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_dashboardTab(), _workersTab(), _earningsTab()],
      ),
    );
  }

  Widget _dashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _profileCard(),
        const SizedBox(height: 16),
        _statsSection(),
        const SizedBox(height: 16),
        _quickActions(),
      ]),
    );
  }

  Widget _profileCard() {
    final name = _profile?['name'] ?? _profile?['fullName'] ?? 'Grameen Sathi';
    final phone = _profile?['phone'] ?? '';
    final area = _profile?['area'] ?? _profile?['village'] ?? 'Your Area';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 12, offset: const Offset(0,4))],
      ),
      child: Row(children: [
        CircleAvatar(radius: 30, backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (area.isNotEmpty) Text(area, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          if (phone.isNotEmpty) Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _statsSection() {
    if (_uid == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gurkul_applications')
          .where('referredBy', isEqualTo: _uid).snapshots(),
      builder: (ctx, snap) {
        final all = snap.data?.docs ?? [];
        final placed = all.where((d) => (d.data() as Map)['status'] == 'placed').length;
        final pending = all.where((d) => (d.data() as Map)['status'] == 'pending').length;
        final earnings = placed * 500;
        return Column(children: [
          Row(children: [
            Expanded(child: _statCard('Total Referred', all.length.toString(), Icons.people, const Color(0xFF1565C0))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Placed', placed.toString(), Icons.check_circle, Colors.green)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statCard('Pending', pending.toString(), Icons.hourglass_empty, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Earnings', 'Rs.$earnings', Icons.currency_rupee, Colors.purple)),
          ]),
        ]);
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ])),
      ]),
    );
  }

  Widget _quickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          _actionBtn(Icons.person_add, 'Refer Worker', Colors.blue, () => _referWorkerDialog()),
          const SizedBox(width: 10),
          _actionBtn(Icons.share, 'Share Link', Colors.green, () => launchUrl(Uri.parse('https://wa.me/?text=Join%20KaamDhanda%20-%20Find%20jobs%20near%20you!%20https://kamdhanda.in'))),
          const SizedBox(width: 10),
          _actionBtn(Icons.calculate, 'Calculator', Colors.purple, () => _tab.animateTo(2)),
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(child: InkWell(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]))));
  }

  void _referWorkerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final skillCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Refer a Worker'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Worker Name')),
        const SizedBox(height: 8),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        TextField(controller: skillCtrl, decoration: const InputDecoration(labelText: 'Skill (e.g. Helper, Driver)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
          onPressed: () async {
            if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
            await FirebaseFirestore.instance.collection('gurkul_applications').add({
              'name': nameCtrl.text, 'phone': phoneCtrl.text, 'skill': skillCtrl.text,
              'referredBy': _uid, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
            });
            if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker referred!'), backgroundColor: Colors.green)); }
          },
          child: const Text('Refer'),
        ),
      ],
    ));
  }

  Widget _workersTab() {
    if (_uid == null) return const Center(child: Text('Please login'));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gurkul_applications').where('referredBy', isEqualTo: _uid).orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.people_outline, size: 64, color: Color(0xFF90CAF9)),
          const SizedBox(height: 12),
          Text('No workers referred yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _referWorkerDialog, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white), child: const Text('Refer First Worker')),
        ]));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String,dynamic>;
            final status = d['status'] ?? 'pending';
            final statusColor = status == 'placed' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: Text((d['name'] ?? 'W')[0].toUpperCase(), style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold))),
                title: Text(d['name'] ?? 'Worker', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${d['skill'] ?? 'Worker'} • ${d['phone'] ?? ''}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _earningsTab() {
    int referred = 0, placed = 0;
    return StatefulBuilder(builder: (ctx, set) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Earnings Calculator', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Calculate your commission income', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _calcField('Workers Referred', referred.toString(), (v) => set(() => referred = int.tryParse(v) ?? 0))),
                const SizedBox(width: 12),
                Expanded(child: _calcField('Workers Placed', placed.toString(), (v) => set(() => placed = int.tryParse(v) ?? 0))),
              ]),
              const SizedBox(height: 20),
              Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _earningRow('Placement Fee (Rs.500 each)', 'Rs.${placed * 500}'),
                  const Divider(color: Colors.white30, height: 16),
                  _earningRow('Referral Bonus (Rs.100 each)', 'Rs.${referred * 100}'),
                  const Divider(color: Colors.white30, height: 16),
                  _earningRow('TOTAL EARNINGS', 'Rs.${placed * 500 + referred * 100}', bold: true, size: 18),
                ])),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How Earnings Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _howRow('1', 'Refer workers to KaamDhanda', Colors.blue),
              _howRow('2', 'When worker gets placed, earn Rs.500', Colors.green),
              _howRow('3', 'Rs.100 bonus for each referral registration', Colors.orange),
              _howRow('4', 'Track all earnings in your dashboard', Colors.purple),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _calcField(String label, String value, ValueChanged<String> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 6),
      Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: TextField(
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          decoration: const InputDecoration(hintText: '0', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        )),
    ]);
  }

  Widget _earningRow(String label, String value, {bool bold = false, double size = 14}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: size - 1)),
      Text(value, style: TextStyle(color: Colors.white, fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: size)),
    ]);
  }

  Widget _howRow(String step, String text, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      CircleAvatar(radius: 14, backgroundColor: color, child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
    ]));
  }
}
