// ============================================================
// Feature #83: Candidate Status Update
// File: lib/screens/candidate_status_screen.dart
// Kaam Dhanda App — Flutter
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CandidateStatusScreen extends StatefulWidget {
  final String userType; // 'field_staff' or 'gurukul'
  final String userId;

  const CandidateStatusScreen({
    Key? key,
    required this.userType,
    required this.userId,
  }) : super(key: key);

  @override
  State<CandidateStatusScreen> createState() => _CandidateStatusScreenState();
}

class _CandidateStatusScreenState extends State<CandidateStatusScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

  final List<_StatusTab> _tabs = const [
    _StatusTab('सभी', 'all', Icons.people, Colors.blueGrey),
    _StatusTab('Pending', 'pending', Icons.hourglass_empty, Color(0xFFFF8F00)),
    _StatusTab('Verified', 'verified', Icons.verified, Color(0xFF43A047)),
    _StatusTab('Joined', 'joined', Icons.check_circle, Color(0xFF1E88E5)),
    _StatusTab('Rejected', 'rejected', Icons.cancel, Color(0xFFE53935)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _collection =>
      widget.userType == 'field_staff' ? 'field_staff_candidates' : 'gurkul_students';

  String get _screenTitle =>
      widget.userType == 'field_staff' ? '👥 मेरे Candidates' : '🎓 मेरे Students';

  Stream<QuerySnapshot> _stream(String statusFilter) {
    Query q = _db
        .collection(_collection)
        .where('staffId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true);
    if (statusFilter != 'all') {
      q = q.where('status', isEqualTo: statusFilter);
    }
    return q.snapshots();
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await _db.collection(_collection).doc(docId).update({
      'status': newStatus,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addNote(String docId, String note) async {
    await _db.collection(_collection).doc(docId).update({
      'staffNote': note,
      'noteUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Text(
          _screenTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _tabs
              .map((t) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 14),
                        const SizedBox(width: 4),
                        Text(t.label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((t) => _CandidateList(
                  stream: _stream(t.statusKey),
                  statusKey: t.statusKey,
                  userType: widget.userType,
                  onStatusChange: _updateStatus,
                  onAddNote: _addNote,
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(
          widget.userType == 'field_staff' ? 'Candidate जोड़ें' : 'Student जोड़ें',
        ),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final jobCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userType == 'field_staff'
                  ? '➕ नया Candidate जोड़ें'
                  : '➕ नया Student जोड़ें',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            _inputField(nameCtrl, 'पूरा नाम *', Icons.person),
            const SizedBox(height: 12),
            _inputField(phoneCtrl, 'मोबाइल नंबर *', Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _inputField(
              jobCtrl,
              widget.userType == 'field_staff' ? 'Job Type' : 'Course Name',
              Icons.work,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      phoneCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('नाम और नंबर ज़रूरी है')),
                    );
                    return;
                  }
                  await _db.collection(_collection).add({
                    'staffId': widget.userId,
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'jobType': jobCtrl.text.trim(),
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ सफलतापूर्वक जोड़ा गया!'),
                      backgroundColor: Color(0xFF43A047),
                    ),
                  );
                },
                child: const Text('जोड़ें', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ---- Candidate List Widget ----
class _CandidateList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String statusKey;
  final String userType;
  final Future<void> Function(String docId, String status) onStatusChange;
  final Future<void> Function(String docId, String note) onAddNote;

  const _CandidateList({
    required this.stream,
    required this.statusKey,
    required this.userType,
    required this.onStatusChange,
    required this.onAddNote,
  });

  static const _statusOptions = [
    {'key': 'pending', 'label': 'Pending ⏳', 'color': Color(0xFFFF8F00)},
    {'key': 'verified', 'label': 'Verified ✓', 'color': Color(0xFF43A047)},
    {'key': 'joined', 'label': 'Joined ✅', 'color': Color(0xFF1E88E5)},
    {'key': 'rejected', 'label': 'Rejected ✗', 'color': Color(0xFFE53935)},
  ];

  Color _statusColor(String s) {
    return (_statusOptions.firstWhere(
          (o) => o['key'] == s,
          orElse: () => {'color': Colors.grey},
        )['color'] as Color);
  }

  String _statusLabel(String s) {
    return (_statusOptions.firstWhere(
          (o) => o['key'] == s,
          orElse: () => {'label': s},
        )['label'] as String);
  }

  void _showStatusSheet(BuildContext ctx, String docId, String current) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Status बदलें',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            ..._statusOptions.map((opt) {
              final isSelected = opt['key'] == current;
              return ListTile(
                onTap: () async {
                  Navigator.pop(_);
                  await onStatusChange(docId, opt['key'] as String);
                },
                leading: CircleAvatar(
                  backgroundColor:
                      (opt['color'] as Color).withOpacity(0.15),
                  radius: 20,
                  child: Icon(
                    isSelected ? Icons.check : Icons.circle_outlined,
                    color: opt['color'] as Color,
                    size: 18,
                  ),
                ),
                title: Text(
                  opt['label'] as String,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: opt['color'] as Color,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF1565C0))
                    : null,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext ctx, String docId, String? currentNote) {
    final ctrl = TextEditingController(text: currentNote ?? '');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('📝 Note जोड़ें'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'यहाँ note लिखें...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            onPressed: () async {
              Navigator.pop(_);
              await onAddNote(docId, ctrl.text.trim());
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  statusKey == 'all'
                      ? 'अभी कोई नहीं है'
                      : 'इस status में कोई नहीं',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
              ],
            ),
          );
        }

        final docs = snap.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'नाम नहीं';
            final phone = data['phone'] ?? '';
            final jobType = data['jobType'] ?? '';
            final status = data['status'] ?? 'pending';
            final note = data['staffNote'] as String?;
            final ts = data['createdAt'] as Timestamp?;
            final date =
                ts != null ? '${ts.toDate().day}/${ts.toDate().month}' : '';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              const Color(0xFF1565C0).withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  if (phone.isNotEmpty) ...[
                                    Icon(Icons.phone,
                                        size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 2),
                                    Text(phone,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                    const SizedBox(width: 8),
                                  ],
                                  if (date.isNotEmpty)
                                    Text(date,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _showStatusSheet(ctx, doc.id, status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      _statusColor(status).withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down,
                                    size: 14,
                                    color: _statusColor(status)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (jobType.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '💼 $jobType',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],

                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text(
                          '📝 $note',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade800),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showStatusSheet(ctx, doc.id, status),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Status',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1565C0),
                              side: const BorderSide(color: Color(0xFF1565C0)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showNoteDialog(ctx, doc.id, note),
                            icon: const Icon(Icons.note_add, size: 14),
                            label: const Text('Note',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                              side:
                                  BorderSide(color: Colors.orange.shade300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---- Data class for tab ----
class _StatusTab {
  final String label;
  final String statusKey;
  final IconData icon;
  final Color color;
  const _StatusTab(this.label, this.statusKey, this.icon, this.color);
}
