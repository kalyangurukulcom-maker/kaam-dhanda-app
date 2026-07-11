// ══════════════════════════════════════════════════════════════
//  Gurukul Sathi Dashboard Screen
//  Live Firestore stream → auto-update जब Admin change करे
// ══════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class GurkulDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const GurkulDashboardScreen({super.key, required this.data});

  @override
  State<GurkulDashboardScreen> createState() => _GurkulDashboardScreenState();
}

class _GurkulDashboardScreenState extends State<GurkulDashboardScreen> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.data);
  }

  // ── Status helpers ─────────────────────────────────────────
  _StatusInfo _regStatus() => _statusMap(_data['registrationStatus'], {
    'pending':  _StatusInfo('⏳', 'Pending Review', Colors.orange, const Color(0xFFFFF3E0)),
    'approved': _StatusInfo('✅', 'Approved', Colors.green, const Color(0xFFE8F5E9)),
    'rejected': _StatusInfo('❌', 'Rejected', Colors.red, const Color(0xFFFFEBEE)),
  });

  _StatusInfo _trainStatus() => _statusMap(_data['trainingStatus'], {
    'not_started': _StatusInfo('⏸', 'Not Started', Colors.grey, const Color(0xFFF5F5F5)),
    'scheduled':   _StatusInfo('📅', 'Scheduled', Colors.blue, const Color(0xFFE3F2FD)),
    'ongoing':     _StatusInfo('🎓', 'Ongoing', Colors.blue, const Color(0xFFE3F2FD)),
    'completed':   _StatusInfo('✅', 'Completed', Colors.green, const Color(0xFFE8F5E9)),
  });

  _StatusInfo _placeStatus() => _statusMap(_data['placementStatus'], {
    'not_started': _StatusInfo('⏸', 'Not Started', Colors.grey, const Color(0xFFF5F5F5)),
    'in_process':  _StatusInfo('🔄', 'In Process', Colors.orange, const Color(0xFFFFF3E0)),
    'placed':      _StatusInfo('💼', 'Placed ✅', Colors.green, const Color(0xFFE8F5E9)),
  });

  _StatusInfo _payStatus() => _statusMap(_data['paymentStatus'], {
    'pending': _StatusInfo('⏳', 'Pending', Colors.orange, const Color(0xFFFFF3E0)),
    'partial': _StatusInfo('⚡', 'Partial', Colors.orange, const Color(0xFFFFF3E0)),
    'paid':    _StatusInfo('💰', 'Paid ✅', Colors.green, const Color(0xFFE8F5E9)),
  });

  _StatusInfo _statusMap(dynamic val, Map<String, _StatusInfo> map) {
    return map[val?.toString()] ?? _StatusInfo('•', val?.toString() ?? '—', Colors.grey, const Color(0xFFF5F5F5));
  }

  // ── Step index for progress tracker ───────────────────────
  int get _currentStep {
    final reg   = _data['registrationStatus']?.toString();
    final train = _data['trainingStatus']?.toString();
    final place = _data['placementStatus']?.toString();
    final pay   = _data['paymentStatus']?.toString();
    if (pay == 'paid') return 4;
    if (place == 'placed') return 3;
    if (train == 'completed') return 3;
    if (train == 'ongoing' || train == 'scheduled') return 2;
    if (reg == 'approved') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final docId = _data['_id']?.toString() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docId.isNotEmpty ? FirebaseService.gurkulDashboardStream(docId) : null,
        builder: (ctx, snap) {
          if (snap.hasData && snap.data!.exists) {
            final fresh = snap.data!.data() as Map<String, dynamic>;
            _data = {'_id': docId, ...fresh};
          }
          return CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: const Color(0xFF1A237E),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('My Dashboard', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              _data['name']?.toString() ?? '—',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '📱 ${_data['phone']?.toString() ?? ''}  •  📍 ${_data['district']?.toString() ?? ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12, top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: snap.connectionState == ConnectionState.active
                          ? const Color(0xFF4CAF50).withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('Live', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Progress Tracker ────────────────────
                      _buildProgressTracker(),
                      const SizedBox(height: 16),

                      // ── Status Cards Grid ───────────────────
                      const Text('📊 Status Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
                      const SizedBox(height: 10),
                      _buildStatusGrid(),
                      const SizedBox(height: 16),

                      // ── Training Details ────────────────────
                      if (_data['trainingDate'] != null && _data['trainingDate'].toString().isNotEmpty) ...[
                        _buildInfoCard('🎓 Training Details', [
                          _infoRow('📅 Date', _data['trainingDate']?.toString() ?? '—'),
                          _infoRow('📍 Venue', _data['trainingVenue']?.toString() ?? '—'),
                        ]),
                        const SizedBox(height: 12),
                      ],

                      // ── Placement Details ───────────────────
                      if (_data['placementLocation'] != null && _data['placementLocation'].toString().isNotEmpty) ...[
                        _buildInfoCard('💼 Placement Details', [
                          _infoRow('📍 Location/Company', _data['placementLocation']?.toString() ?? '—'),
                        ]),
                        const SizedBox(height: 12),
                      ],

                      // ── Payment Progress ────────────────────
                      _buildPaymentCard(),
                      const SizedBox(height: 12),

                      // ── Profile Details ─────────────────────
                      _buildInfoCard('👤 Profile Details', [
                        _infoRow('🎓 Education', _data['education']?.toString() ?? '—'),
                        _infoRow('💼 Experience', _data['experience']?.toString() ?? '—'),
                        _infoRow('📱 WhatsApp', _data['whatsapp']?.toString() ?? _data['phone']?.toString() ?? '—'),
                        _infoRow('📅 Applied On', _formatDate(_data['createdAt'])),
                        _infoRow('📡 Source', _data['source']?.toString() ?? 'web'),
                      ]),
                      const SizedBox(height: 12),

                      // ── Admin Remark ────────────────────────
                      if (_data['adminRemark'] != null && _data['adminRemark'].toString().isNotEmpty)
                        _buildRemarkCard(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Progress Tracker ──────────────────────────────────────
  Widget _buildProgressTracker() {
    final steps = ['Registration', 'Approved', 'Training', 'Placement', 'Payment'];
    final step = _currentStep;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚀 Your Journey', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final idx = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: idx < step ? const Color(0xFF1A237E) : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final idx = i ~/ 2;
              final done = idx < step;
              final current = idx == step;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFF1A237E)
                          : current
                              ? const Color(0xFFFFD600)
                              : const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : current
                              ? const Icon(Icons.circle, color: Color(0xFF1A237E), size: 10)
                              : Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[idx],
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: done ? const Color(0xFF1A237E) : current ? Colors.orange : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                         ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Status Grid ────────────────────────────────────────────
  Widget _buildStatusGrid() {
    final items = [
      {'label': 'Registration', 'status': _regStatus()},
      {'label': 'Training',     'status': _trainStatus()},
      {'label': 'Placement',    'status': _placeStatus()},
      {'label': 'Payment',      'status': _payStatus()},
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: items.map((item) {
        final st = item['status'] as _StatusInfo;
        final lbl = item['label'] as String;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: st.bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: st.color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lbl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: st.color.withOpacity(0.8))),
              Row(children: [
                Text(st.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(child: Text(st.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: st.color),
                  overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Payment Card ───────────────────────────────────────────
  Widget _buildPaymentCard() {
    final paid  = (_data['paymentPaid']  as num?)?.toDouble() ?? 0;
    final total = (_data['paymentTotal'] as num?)?.toDouble() ?? 30000;
    final pct   = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💰 Payment Progress',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct, minHeight: 10,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0 ? const Color(0xFF2E7D32) : const Color(0xFF1A237E),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Paid: ₹${_fmt(paid.toInt())}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF2E7D32))),
            Text('Remaining: ₹${_fmt((total - paid).toInt())}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Total: ₹${_fmt(total.toInt())}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1A237E))),
          ]),
          const SizedBox(height: 8),
          Center(
            child: Text('${(pct * 100).round()}% Complete',
              style: TextStyle(
                color: pct >= 1.0 ? const Color(0xFF2E7D32) : const Color(0xFF1A237E),
                fontWeight: FontWeight.w900, fontSize: 13,
              )),
          ),
        ],
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────
  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(key, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))),
        Expanded(child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  // ── Admin Remark Card ──────────────────────────────────────
  Widget _buildRemarkCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬 Admin Note',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
          const SizedBox(height: 8),
          Text(
            _data['adminRemark']?.toString() ?? '',
            style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E), height: 1.5),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    if (s.length <= 5) return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    return '${s.substring(0, s.length - 5)},${s.substring(s.length - 5, s.length - 3)},${s.substring(s.length - 3)}';
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    return ts.toString();
  }
}

// ── Status Data Class ─────────────────────────────────────────
class _StatusInfo {
  final String emoji, label;
  final Color color, bg;
  const _StatusInfo(this.emoji, this.label, this.color, this.bg);
}
