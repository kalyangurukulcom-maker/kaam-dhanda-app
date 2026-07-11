import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GrameenSathiScreen extends StatefulWidget {
  final String? staffId;
  final String? staffName;
  const GrameenSathiScreen({super.key, this.staffId, this.staffName});
  @override
  State<GrameenSathiScreen> createState() => _GrameenSathiScreenState();
}

class _GrameenSathiScreenState extends State<GrameenSathiScreen> {
  final _db = FirebaseFirestore.instance;
  static const double _workerComm = 500;
  static const double _gurkulComm = 750;
  static const _statuses = ['pending','contacted','placed','selected','rejected'];
  static const _sColors = {'pending': Color(0xFFF97316),'contacted': Color(0xFF0EA5E9),'placed': Color(0xFF22C55E),'selected': Color(0xFF22C55E),'rejected': Color(0xFFEF4444)};

  String get _sid => (widget.staffId?.isNotEmpty == true) ? widget.staffId! : (FirebaseAuth.instance.currentUser?.uid ?? 'unknown');
  String get _sName => (widget.staffName?.isNotEmpty == true) ? widget.staffName! : (FirebaseAuth.instance.currentUser?.displayName ?? 'Grameen Sathi');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Grameen Sathi', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: _sid == 'unknown'
          ? const Center(child: Text('Please login first', style: TextStyle(color: Colors.grey)))
          : StreamBuilder<QuerySnapshot>(
              stream: _db.collection('grameen_sathi_leads').where('staffId', isEqualTo: _sid).orderBy('timestamp', descending: true).snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                final wPlaced = docs.where((d) => (d.data() as Map)['type'] == 'worker' && (d.data() as Map)['status'] == 'placed').length;
                final gSel = docs.where((d) => (d.data() as Map)['type'] == 'gurukul' && (d.data() as Map)['status'] == 'selected').length;
                final earn = wPlaced * _workerComm + gSel * _gurkulComm;
                return Column(children: [
                  Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D47A1)]), borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('₹\${earn.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _Chip('Workers Placed: \$wPlaced', Colors.teal),
                        const SizedBox(width: 8),
                        _Chip('Gurkul Selected: \$gSel', Colors.orange),
                      ]),
                    ])),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
                    Expanded(child: _RateCard('Worker', '₹500/lead', Colors.teal)),
                    const SizedBow(width: 10),
                    Expanded(child: _RateCard('Gurkul', '₹750/lead', Colors.orange)),
                  ])),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Leads (\${docs.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ElevatedButton.icon(onPressed: () => _showAddDialog(), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), icon: const Icon(Icons.add, size: 16), label: const Text('Add Lead', style: TextStyle(fontSize: 13))),
                    ])),
                  Expanded(child: docs.isEmpty
                      ? const Center(child: Text('कोई lead नहीं\n+ button से add करो', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final doc = docs[i]; final d = doc.data() as Map<String, dynamic>;
                            final t = d['type'] ?? 'worker'; final st = d['status'] ?? 'pending';
                            final c = _sColors[st] ?? Colors.grey;
                            return Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: t == 'worker' ? Colors.teal.shade100 : Colors.orange.shade100, child: Icon(t == 'worker' ? Icons.engineering : Icons.school, color: t == 'worker' ? Colors.teal : Colors.orange, size: 18)),
                                title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('\${d['phone'] ?? ''} • \${d['village'] ?? ''}'),
                                trailing: PopupMenuButton<String>(
                                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: c)), child: Text(st, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600))),
                                  itemBuilder: (_) => _statuses.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                                  onSelected: (s) => _db.collection('grameen_sathi_leads').doc(doc.id).update({'status': s, 'updatedAt': FieldValue.serverTimestamp()}),
                                ),
                              ));
                          })),
                ]);
              }),
    );
  }

  void _showAddDialog() {
    final nCtrl = TextEditingController(); final pCtrl = TextEditingController(); final vCtrl = TextEditingController();
    String type = 'worker';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: const Text('नया Lead जोड़ें'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: RadioListTile<String>(title: const Text('Worker', style: TextStyle(fontSize: 13)), value: 'worker', groupValue: type, onChanged: (v) => ss(() => type = v!), contentPadding: EdgeInsets.zero, dense: true)),
          Expanded(child: RadioListTile<String>(title: const Text('Gurkul', style: TextStyle(fontSize: 13)), value: 'gurukul', groupValue: type, onChanged: (v) => ss(() => type = v!), contentPadding: EdgeInsets.zero, dense: true)),
        ]),
        const Divider(),
        TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'Name *', isDense: true)),
        const SizedBox(height: 6),
        TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'Phone *', isDense: true), keyboardType: TextInputType.phone),
        const SizedBox(height: 6),
        TextField(controller: vCtrl, decoration: const InputDecoration(labelText: 'Village/Area', isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
          onPressed: () async {
            if (nCtrl.text.isEmpty || pCtrl.text.isEmpty) return;
            await _db.collection('grameen_sathi_leads').add({'staffId': _sid, 'staffName': _sName, 'name': nCtrl.text.trim(), 'phone': pCtrl.text.trim(), 'village': vCtrl.text.trim(), 'type': type, 'status': 'pending', 'timestamp': FieldValue.serverTimestamp()});
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Add')),
      ],
    )));
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip(this.label, this.color);
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)));
}

class _RateCard extends StatelessWidget {
  final String title, rate; final Color color;
  const _RateCard(this.title, this.rate, this.color);
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Text(title, style: TextStyle(fontSize: 11, color: color), textAlign: TextAlign.center), const SizedBox(height: 4), Text(rate, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))]));
}
