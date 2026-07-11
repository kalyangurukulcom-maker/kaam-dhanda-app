import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CandidateStatusScreen extends StatefulWidget {
  final String? userId;
  final String? userType;
  const CandidateStatusScreen({super.key, this.userId, this.userType});
  @override
  State<CandidateStatusScreen> createState() => _CandidateStatusScreenState();
}

class _CandidateStatusScreenState extends State<CandidateStatusScreen> {
  final _db = FirebaseFirestore.instance;

  String get _uid => (widget.userId?.isNotEmpty == true) ? widget.userId! : (FirebaseAuth.instance.currentUser?.uid ?? 'unknown');
  String get _uType => widget.userType ?? 'field_staff';
  String get _col => _uType == 'gurukul' ? 'gurkul_candidates' : 'field_staff_candidates';

  static const _statuses = ['pending','contacted','selected','placed','rejected'];
  static const _colors = {
    'pending': Color(0xFFF97316),'contacted': Color(0xFF0EA5E9),
    'selected': Color(0xFF14B8A6),'placed': Color(0xFF22C55E),'rejected': Color(0xFFEF4444),
  };

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _distCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _distCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Candidate Status', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add), label: const Text('Add Candidate'),
      ),
      body: _uid == 'unknown'
          ? const Center(child: Text('Please login to view candidates', style: TextStyle(color: Colors.grey)))
          : StreamBuilder<QuerySnapshot>(
              stream: _db.collection(_col).where('staffId', isEqualTo: _uid).orderBy('timestamp', descending: true).snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('कोई candidate नहीं', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('+ button से candidate जोड़ें', style: TextStyle(color: Colors.grey.shade600)),
                ]));
                return Column(children: [
                  Padding(padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                      child: Row(children: _statuses.map((s) {
                        final cnt = docs.where((d) => (d.data() as Map)['status'] == s).length;
                        final c = _colors[s]!;
                        return Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: c)),
                          child: Text('\$s: \$cnt', style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)));
                      }).toList()))),
                  Expanded(child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final doc = docs[i]; final d = doc.data() as Map<String, dynamic>;
                      final status = d['status'] ?? 'pending';
                      final c = _colors[status] ?? Colors.grey;
                      return Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(d['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                              child: Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 11))),
                          ]),
                          const SizedBox(height: 4),
                          Text('📞 \${d['phone'] ?? ''}  📍 \${d['district'] ?? ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 6, runSpacing: 4, children: _statuses.map((s) {
                            final sc = _colors[s]!;
                            return InkWell(
                              onTap: () => _db.collection(_col).doc(doc.id).update({'status': s, 'updatedAt': FieldValue.serverTimestamp()}),
                              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: s == status ? sc : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: sc)),
                                child: Text(s, style: TextStyle(color: s == status ? Colors.white : sc, fontSize: 11, fontWeight: FontWeight.w600))));
                          }).toList()),
                        ])));
                    })),
                ]);
              }),
    );
  }

  void _showAddDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('नया Candidate जोड़ें'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *', isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone *', isDense: true), keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        TextField(controller: _distCtrl, decoration: const InputDecoration(labelText: 'District', isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
          onPressed: () async {
            if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;
            await _db.collection(_col).add({'staffId': _uid, 'name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(), 'district': _distCtrl.text.trim(), 'status': 'pending', 'timestamp': FieldValue.serverTimestamp()});
            _nameCtrl.clear(); _phoneCtrl.clear(); _distCtrl.clear();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Add')),
      ],
    ));
  }
}
