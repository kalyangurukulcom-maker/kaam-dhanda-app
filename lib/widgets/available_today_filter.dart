// ============================================================
// Feature #118: Available Today Filter
// File: lib/widgets/available_today_filter.dart
// Kaam Dhanda App — Flutter
//
// 3 Components:
//
// 1. AvailableTodaySection — Home/Marketplace top strip
//    Shows live count + horizontal card list of available workers
//    Usage:
//      AvailableTodaySection(
//        category: 'Construction',   // optional filter
//        onHire: (workerId) { ... },
//      )
//
// 2. AvailableTodayToggle — Filter toggle button (for top bar)
//    AvailableTodayToggle(
//      active: _availableNow,
//      count: 12,
//      onChanged: (v) => setState(() => _availableNow = v),
//    )
//
// 3. AvailableNowBadge — Animated live indicator dot + text
//    AvailableNowBadge()
//    AvailableNowBadge.withCount(count: 24)
//
// Firestore: workers collection
//   Filter: availability == 'available'
//   Sort: availabilityUpdatedAt DESC (most recently available first)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// ============================================================
// 1. AvailableTodaySection — Horizontal strip with live workers
// ============================================================
class AvailableTodaySection extends StatelessWidget {
  final String? category;       // filter by category (optional)
  final String? location;       // filter by location (optional)
  final void Function(String workerId, Map<String, dynamic> data)? onHire;
  final VoidCallback? onSeeAll;

  const AvailableTodaySection({
    Key? key,
    this.category,
    this.location,
    this.onHire,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('workers')
        .where('availability', isEqualTo: 'available')
        .orderBy('availabilityUpdatedAt', descending: true)
        .limit(20);

    if (category != null && category!.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        List<Map<String, dynamic>> workers = [];

        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          workers = snap.data!.docs
              .map((d) => {...d.data() as Map<String, dynamic>, 'docId': d.id})
              .toList();
        } else if (!snap.hasData ||
            (snap.hasData && snap.data!.docs.isEmpty)) {
          // Demo fallback
          workers = _demoWorkers;
        }

        if (workers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  AvailableNowBadge.withCount(count: workers.length),
                  const Spacer(),
                  if (onSeeAll != null)
                    GestureDetector(
                      onTap: onSeeAll,
                      child: const Text(
                        'सभी देखें →',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Horizontal cards
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: workers.length,
                itemBuilder: (ctx, i) => _AvailableWorkerCard(
                  worker: workers[i],
                  onHire: onHire,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// Horizontal worker card
class _AvailableWorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final void Function(String, Map<String, dynamic>)? onHire;

  const _AvailableWorkerCard({required this.worker, this.onHire});

  String _updatedAgo(dynamic ts) {
    if (ts == null) return 'अभी';
    final dt = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min पहले';
    if (diff.inHours < 24) return '${diff.inHours} hr पहले';
    return DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final name = worker['name'] ?? worker['workerName'] ?? 'Worker';
    final category = worker['category'] ?? worker['skill'] ?? 'Worker';
    final rate = worker['dailyRate'] ?? worker['rate'] ?? 500;
    final rating = (worker['rating'] ?? 4.0).toDouble();
    final location = worker['location'] ?? worker['city'] ?? '';
    final phone = worker['phone'] ?? worker['mobile'] ?? '';
    final updatedAt = worker['availabilityUpdatedAt'];
    final jobs = worker['completedJobs'] ?? worker['jobsDone'] ?? 0;
    final docId = worker['docId'] ?? '';

    // Pick avatar color by name
    final colors = [
      const Color(0xFF1565C0), const Color(0xFF2E7D32),
      const Color(0xFF6A1B9A), const Color(0xFFE65100),
      const Color(0xFF00695C),
    ];
    final avatarColor = colors[name.codeUnitAt(0) % colors.length];

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Avatar with live dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: avatarColor.withOpacity(0.15),
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: avatarColor,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _LiveDot(),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          color: avatarColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('⭐ $rating',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('✅ $jobs jobs',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 3),
                if (location.isNotEmpty)
                  Text(
                    '📍 $location',
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black45),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 3),
                Text(
                  '🕐 ${_updatedAgo(updatedAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.green),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Rate + Hire button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '₹$rate/day',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (onHire != null) {
                      onHire!(docId, worker);
                    } else if (phone.isNotEmpty) {
                      launchUrl(Uri.parse('tel:$phone'));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Hire',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 2. AvailableTodayToggle — Filter button for top bar
// ============================================================
class AvailableTodayToggle extends StatelessWidget {
  final bool active;
  final int? count;
  final ValueChanged<bool> onChanged;

  const AvailableTodayToggle({
    Key? key,
    required this.active,
    this.count,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!active);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              _LiveDot(size: 8, color: Colors.white)
            else
              _LiveDot(size: 8),
            const SizedBox(width: 6),
            Text(
              'Available Now',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.25)
                      : const Color(0xFF2E7D32).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
            if (active) ...[
              const SizedBox(width: 5),
              const Icon(Icons.close, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 3. AvailableNowBadge — Animated live indicator
// ============================================================
class AvailableNowBadge extends StatefulWidget {
  final int? count;
  final bool showLabel;

  const AvailableNowBadge({Key? key, this.count, this.showLabel = true})
      : super(key: key);

  factory AvailableNowBadge.withCount({required int count}) =>
      AvailableNowBadge(count: count);

  @override
  State<AvailableNowBadge> createState() => _AvailableNowBadgeState();
}

class _AvailableNowBadgeState extends State<AvailableNowBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _scale,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          widget.count != null
              ? '${widget.count} Workers अभी Available हैं'
              : 'अभी Available',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Live Dot — animated pulsing dot
// ============================================================
class _LiveDot extends StatefulWidget {
  final double size;
  final Color? color;

  const _LiveDot({this.size = 10, this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF2E7D32);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color.withOpacity(_anim.value),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4 * _anim.value),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// AvailableNowScreen — Dedicated full-page Available Workers
// ============================================================
class AvailableNowScreen extends StatefulWidget {
  final String? initialCategory;

  const AvailableNowScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<AvailableNowScreen> createState() => _AvailableNowScreenState();
}

class _AvailableNowScreenState extends State<AvailableNowScreen> {
  final _db = FirebaseFirestore.instance;
  String? _selectedCategory;
  String _sortBy = 'recent'; // 'recent' | 'rating' | 'price_low'

  final _categories = [
    'सभी', 'Construction', 'Painting', 'Plumbing', 'Electrical',
    'Carpentry', 'Welding', 'Cooking', 'Cleaning', 'Security', 'Driving',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    Query query = _db
        .collection('workers')
        .where('availability', isEqualTo: 'available');

    if (_selectedCategory != null && _selectedCategory != 'सभी') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Firestore ordering
    if (_sortBy == 'recent') {
      query = query.orderBy('availabilityUpdatedAt', descending: true);
    }
    query = query.limit(50);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            _LiveDot(),
            const SizedBox(width: 8),
            const Text(
              'अभी Available Workers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'recent', child: Text('🕐 हाल में Available')),
              PopupMenuItem(
                  value: 'rating', child: Text('⭐ Rating')),
              PopupMenuItem(
                  value: 'price_low', child: Text('💸 Lowest Rate')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              children: _categories.map((cat) {
                final sel = (_selectedCategory == null && cat == 'सभी') ||
                    _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory =
                          cat == 'सभी' ? null : cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF2E7D32)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: sel ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Worker list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (ctx, snap) {
                List<Map<String, dynamic>> workers = [];

                if (snap.hasData) {
                  workers = snap.data!.docs
                      .map((d) => {
                            ...d.data() as Map<String, dynamic>,
                            'docId': d.id
                          })
                      .toList();
                }

                if (workers.isEmpty && snap.connectionState != ConnectionState.waiting) {
                  workers = _demoWorkers;
                }

                // Client-side sort for rating / price
                if (_sortBy == 'rating') {
                  workers.sort((a, b) =>
                      ((b['rating'] ?? 0.0) as double)
                          .compareTo((a['rating'] ?? 0.0) as double));
                } else if (_sortBy == 'price_low') {
                  workers.sort((a, b) =>
                      ((a['dailyRate'] ?? 999) as int)
                          .compareTo((b['dailyRate'] ?? 999) as int));
                }

                if (snap.connectionState == ConnectionState.waiting &&
                    workers.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32)));
                }

                return Column(
                  children: [
                    // Live count banner
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF2E7D32)
                                .withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          AvailableNowBadge.withCount(count: workers.length),
                          const Spacer(),
                          Text(
                            'अभी Hire करें',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: workers.length,
                        itemBuilder: (_, i) =>
                            _AvailableListTile(worker: workers[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Full list tile version
class _AvailableListTile extends StatelessWidget {
  final Map<String, dynamic> worker;

  const _AvailableListTile({required this.worker});

  String _updatedAgo(dynamic ts) {
    if (ts == null) return 'अभी';
    final dt = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 5) return 'अभी अभी';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min पहले';
    if (diff.inHours < 24) return '${diff.inHours} घंटे पहले';
    return DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final name = worker['name'] ?? worker['workerName'] ?? 'Worker';
    final category = worker['category'] ?? 'Worker';
    final rate = worker['dailyRate'] ?? 500;
    final rating = (worker['rating'] ?? 4.0).toDouble();
    final location = worker['location'] ?? worker['city'] ?? '';
    final phone = worker['phone'] ?? worker['mobile'] ?? '';
    final experience = worker['experience'] ?? '';
    final ts = worker['availabilityUpdatedAt'];

    final colors = [
      const Color(0xFF1565C0), const Color(0xFF2E7D32),
      const Color(0xFF6A1B9A), const Color(0xFFE65100),
    ];
    final avatarColor = colors[name.codeUnitAt(0) % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + live dot
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: avatarColor.withOpacity(0.1),
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: avatarColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _LiveDot(size: 12),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.shade300),
                      ),
                      child: Text(
                        '🕐 ${_updatedAgo(ts)}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$category${experience.isNotEmpty ? " • $experience" : ""}',
                  style: TextStyle(
                      fontSize: 13,
                      color: avatarColor,
                      fontWeight: FontWeight.w500),
                ),
                if (location.isNotEmpty)
                  Text('📍 $location',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('⭐ $rating',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Text('💰 ₹$rate/day',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    // Call button
                    if (phone.isNotEmpty) ...[
                      _ActionBtn(
                        icon: '📞',
                        color: const Color(0xFF1565C0),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('tel:$phone'));
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: '💬',
                        color: const Color(0xFF25D366),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse(
                              'https://wa.me/91$phone?text=${Uri.encodeComponent("नमस्ते $name! Kaam Dhanda से आपका profile देखा। क्या आप आज available हैं?")}'));
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 16))),
      ),
    );
  }
}

// ============================================================
// Demo fallback data
// ============================================================
final _demoWorkers = [
  {
    'docId': 'd1',
    'name': 'Ramesh Kumar',
    'category': 'Construction',
    'dailyRate': 700,
    'rating': 4.5,
    'location': 'Ranchi, JH',
    'phone': '9801234567',
    'experience': '5 साल',
    'completedJobs': 127,
    'availability': 'available',
    'availabilityUpdatedAt': null,
  },
  {
    'docId': 'd2',
    'name': 'Suresh Yadav',
    'category': 'Painting',
    'dailyRate': 600,
    'rating': 4.2,
    'location': 'Dhanbad, JH',
    'phone': '9812345678',
    'experience': '3 साल',
    'completedJobs': 84,
    'availability': 'available',
    'availabilityUpdatedAt': null,
  },
  {
    'docId': 'd3',
    'name': 'Mohan Sah',
    'category': 'Plumbing',
    'dailyRate': 800,
    'rating': 4.8,
    'location': 'Bokaro, JH',
    'phone': '9823456789',
    'experience': '7 साल',
    'completedJobs': 203,
    'availability': 'available',
    'availabilityUpdatedAt': null,
  },
  {
    'docId': 'd4',
    'name': 'Dinesh Paswan',
    'category': 'Electrical',
    'dailyRate': 900,
    'rating': 4.6,
    'location': 'Jamshedpur, JH',
    'phone': '9834567890',
    'experience': '6 साल',
    'completedJobs': 156,
    'availability': 'available',
    'availabilityUpdatedAt': null,
  },
  {
    'docId': 'd5',
    'name': 'Ajay Mahto',
    'category': 'Carpentry',
    'dailyRate': 750,
    'rating': 4.3,
    'location': 'Hazaribagh, JH',
    'phone': '9845678901',
    'experience': '4 साल',
    'completedJobs': 91,
    'availability': 'available',
    'availabilityUpdatedAt': null,
  },
];
