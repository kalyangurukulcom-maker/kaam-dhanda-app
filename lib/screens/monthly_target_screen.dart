// ============================================================
// Feature #82: Monthly Target Tracker
// File: lib/screens/monthly_target_screen.dart
// Kaam Dhanda App — Flutter
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class MonthlyTargetScreen extends StatefulWidget {
  final String userType; // 'field_staff' or 'gurukul'
  final String userId;

  const MonthlyTargetScreen({
    Key? key,
    required this.userType,
    required this.userId,
  }) : super(key: key);

  @override
  State<MonthlyTargetScreen> createState() => _MonthlyTargetScreenState();
}

class _MonthlyTargetScreenState extends State<MonthlyTargetScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _achieved = 0;
  int _target = 10;
  bool _loading = true;
  String _month = '';
  List<Map<String, dynamic>> _candidates = [];

  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  // Payout slabs
  static const List<Map<String, dynamic>> _slabs = [
    {'min': 1, 'max': 3, 'rate': 1500, 'label': '1–3 candidates'},
    {'min': 4, 'max': 6, 'rate': 2000, 'label': '4–6 candidates'},
    {'min': 7, 'max': 9, 'rate': 2500, 'label': '7–9 candidates'},
    {'min': 10, 'max': 999, 'rate': 3000, 'label': '10+ candidates'},
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _currentMonth() {
    final now = DateTime.now();
    final months = [
      '', 'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];
    return '${months[now.month]} ${now.year}';
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      final collection = widget.userType == 'field_staff'
          ? 'field_staff_candidates'
          : 'gurkul_students';

      final snap = await _db
          .collection(collection)
          .where('staffId', isEqualTo: widget.userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('createdAt', descending: true)
          .get();

      final candidates = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['name'] ?? 'नाम उपलब्ध नहीं',
          'phone': data['phone'] ?? '',
          'status': data['status'] ?? 'pending',
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();

      final achieved = candidates.length;
      final progress = achieved / _target;

      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: progress.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.forward(from: 0);

      setState(() {
        _achieved = achieved;
        _candidates = candidates;
        _month = _currentMonth();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int _calcPayout(int count) {
    if (count == 0) return 0;
    for (final slab in _slabs) {
      if (count >= slab['min'] && count <= slab['max']) {
        return count * (slab['rate'] as int);
      }
    }
    return count * 3000;
  }

  Color _progressColor(double progress) {
    if (progress < 0.4) return const Color(0xFFE53935);
    if (progress < 0.7) return const Color(0xFFFF8F00);
    if (progress < 1.0) return const Color(0xFF43A047);
    return const Color(0xFF1E88E5);
  }

  String _progressLabel(int achieved) {
    if (achieved == 0) return 'अभी शुरू नहीं हुआ';
    if (achieved < 4) return 'शुरुआत हो गई! 💪';
    if (achieved < 7) return 'अच्छी Progress! 🔥';
    if (achieved < 10) return 'लगभग पहुँच गए! 🎯';
    return 'Target पूरा! 🎉';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified': return const Color(0xFF43A047);
      case 'joined': return const Color(0xFF1E88E5);
      case 'rejected': return const Color(0xFFE53935);
      default: return const Color(0xFFFF8F00);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified': return 'Verified ✓';
      case 'joined': return 'Joined ✅';
      case 'rejected': return 'Rejected ✗';
      default: return 'Pending ⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final payout = _calcPayout(_achieved);
    final isFieldStaff = widget.userType == 'field_staff';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFieldStaff ? '📊 Monthly Target' : '🎓 Monthly Target',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _month,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF1565C0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Progress Card
                    _buildProgressCard(payout),
                    const SizedBox(height: 16),

                    // Payout Slabs
                    _buildSlabsCard(),
                    const SizedBox(height: 16),

                    // Candidates List
                    _buildCandidatesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressCard(int payout) {
    final progress = _target > 0 ? _achieved / _target : 0.0;
    final color = _progressColor(progress);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Circular Progress
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(160, 160),
                  painter: _CircularProgressPainter(
                    progress: _progressAnim.value,
                    color: color,
                  ),
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_achieved',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '/ $_target',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            Text(
              _progressLabel(_achieved),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip('🎯 Target', '$_target'),
                _statChip('✅ किए', '$_achieved'),
                _statChip('⏳ बाकी', '${math.max(0, _target - _achieved)}'),
              ],
            ),
            const SizedBox(height: 16),

            // Payout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '💰 अनुमानित कमाई: ',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '₹${_formatNum(payout)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        )),
      ],
    );
  }

  Widget _buildSlabsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💵 Payout Structure',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            ..._slabs.map((slab) {
              final isActive = _achieved >= slab['min'] &&
                  _achieved <= slab['max'];
              final isCompleted = _achieved > slab['max'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE3F2FD)
                      : isCompleted
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF1565C0)
                        : isCompleted
                            ? const Color(0xFF43A047)
                            : Colors.grey.shade200,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      isCompleted ? '✅' : isActive ? '👉' : '  ',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slab['label'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive
                              ? const Color(0xFF1565C0)
                              : Colors.black87,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '₹${_formatNum(slab['rate'])}/candidate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xFF1565C0)
                            : isCompleted
                                ? const Color(0xFF43A047)
                                : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.userType == 'field_staff'
                      ? '👥 इस महीने के Candidates'
                      : '🎓 इस महीने के Students',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_achieved',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_candidates.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'इस महीने अभी कोई नहीं जोड़ा',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._candidates.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final date = c['createdAt'] as DateTime?;
                final dateStr = date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (dateStr.isNotEmpty)
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(c['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _statusColor(c['status']).withOpacity(0.4)),
                        ),
                        child: Text(
                          _statusLabel(c['status']),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(c['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '$n';
  }
}

// Custom circular progress painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.color != color;
}
