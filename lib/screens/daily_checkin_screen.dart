import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyCheckinScreen extends StatefulWidget {
  final String? userId;
  final String? userType;
  final String? userName;
  const DailyCheckinScreen({super.key, this.userId, this.userType, this.userName});
  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final _db = FirebaseFirestore.instance;
  final _noteCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  bool _submitting = false;
  bool _checkedInToday = false;
  String _selectedActivity = 'घर-घर जाकर candidates ढूंढे';
  final _activities = ['घर-घर जाकर candidates ढूंढे','Village meeting की','School/College visit किया','Phone calls किए','Training दी','Documents verify किए','Office visit किया','Other'];

  String get _uid => (widget.userId?.isNotEmpty == true) ? widget.userId! : (FirebaseAuth.instance.currentUser?.uid ?? 'unknown');
  String get _uType => widget.userType ?? 'field_staff';
  String get _uName => (widget.userName?.isNotEmpty == true) ? widget.userName! : (FirebaseAuth.instance.currentUser?.displayName ?? 'User');

  @override
  void initState() { super.initState(); _checkToday(); }
  @override
  void dispose() { _noteCtrl.dispose(); _areaCtrl.dispose(); super.dispose(); }

  Future<void> _checkToday() async {
    if (_uid == 'unknown') return;
    final today = _today();
    final s = await _db.collection('checkins').where('userId', isEqualTo: _uid).where('date', isEqualTo: today).limit(1).get();
    if (mounted) setState(() => _checkedInToday = s.docs.isNotEmpty);
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  Future<void> _submit() async {
    if (_uid == 'unknown') { _snack('Please login first', Colors.red); return; }
    setState(() => _submitting = true);
    try {
      await _db.collection('checkins').add({
        'userId': _uid, 'userType': _uType, 'userName': _uName,
        'date': _today(), 'activity': _selectedActivity,
        'area': _areaCtrl.text.trim(), 'note': _noteCtrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() { _checkedInToday = true; _submitting = false; });
        _noteCtrl.clear(); _areaCtrl.clear();
        _snack('✅ Check-in हो गया!', Colors.green);
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      _snack('Error: \$e', Colors.red);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Daily Check-in', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _checkedInToday ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _checkedInToday ? Colors.green : Colors.orange),
            ),
            child: Row(children: [
              Icon(_checkedInToday ? Icons.check_circle : Icons.access_time, color: _checkedInToday ? Colors.green : Colors.orange, size: 32),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_checkedInToday ? 'आज Check-in हो गया ✅' : 'आज Check-in बाकी है', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_today(), style: TextStyle(color: Colors.grey.shade600)),
              ]),
            ]),
          ),
          if (!_checkedInToday) ...[
            const SizedBox(height: 20),
            const Text('आज क्या किया?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.white),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedActivity, isExpanded: true,
                items: _activities.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedActivity = v!))),
            ),
            const SizedBox(height: 12),
            TextField(controller: _areaCtrl, decoration: InputDecoration(labelText: 'Area / Village', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white)),
            const SizedBox(height: 12),
            TextField(controller: _noteCtrl, maxLines: 2, decoration: InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('✅ Check-in करो', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          ],
          const SizedBox(height: 24),
          const Text('हाल के Check-ins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _uid == 'unknown' ? const Stream.empty() : _db.collection('checkins').where('userId', isEqualTo: _uid).orderBy('timestamp', descending: true).limit(10).snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('कोई check-in नहीं', style: TextStyle(color: Colors.grey))));
              return Column(children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1A237E), child: Icon(Icons.check, color: Colors.white, size: 16)),
                  title: Text(d['activity'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  subtitle: Text('\${d['area'] ?? ''} • \${d['date'] ?? ''}'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                ));
              }).toList());
            },
          ),
        ]),
      ),
    );
  }
}
