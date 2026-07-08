// ============================================================
// Feature #87: Worker Profile Screen
// File: lib/screens/worker_profile_screen.dart
// Kaam Dhanda App — Flutter
//
// pubspec.yaml mein add karo:
//   url_launcher: ^6.2.5
//   share_plus: ^7.2.1
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String workerId;
  final Map<String, dynamic>? initialData; // optional — avoids extra fetch

  const WorkerProfileScreen({
    Key? key,
    required this.workerId,
    this.initialData,
  }) : super(key: key);

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _worker;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _worker = widget.initialData;
      _loading = false;
      _loadReviews();
    } else {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final doc =
          await _db.collection('workers').doc(widget.workerId).get();
      if (doc.exists) {
        _worker = {...doc.data()!, 'id': doc.id};
      }
    } catch (_) {}
    await _loadReviews();
    setState(() => _loading = false);
  }

  Future<void> _loadReviews() async {
    try {
      final snap = await _db
          .collection('worker_ratings')
          .where('workerId', isEqualTo: widget.workerId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      setState(() {
        _reviews = snap.docs.map((d) => d.data()).toList();
      });
    } catch (_) {}
  }

  void _openWhatsApp() async {
    final phone = _worker?['phone'] ?? '';
    final name = _worker?['name'] ?? 'worker';
    final category = _worker?['category'] ?? 'काम';
    final uri = Uri.parse(
        'https://wa.me/91$phone?text=नमस्ते $name जी, मुझे $category के लिए आपकी ज़रूरत है।');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _callWorker() async {
    final phone = _worker?['phone'] ?? '';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _shareProfile() {
    final name = _worker?['name'] ?? '';
    final category = _worker?['category'] ?? '';
    final city = _worker?['city'] ?? '';
    final rating = _worker?['rating']?.toString() ?? '4.5';
    Share.share(
      '👷 $name — $category\n'
      '📍 $city | ⭐ $rating Rating\n'
      'काम धंधा App पर देखें: https://kamdhanda.in/hire.html',
    );
  }

  void _showHireSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 ${_worker?['name'] ?? ''} को Hire करें',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 16),
            _field(nameCtrl, 'आपका नाम *', Icons.person),
            const SizedBox(height: 10),
            _field(phoneCtrl, 'मोबाइल नंबर *', Icons.phone,
                type: TextInputType.phone),
            const SizedBox(height: 10),
            _field(descCtrl, 'काम का विवरण (optional)',
                Icons.description, lines: 2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Text('💬', style: TextStyle(fontSize: 16)),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF43A047),
                      side:
                          const BorderSide(color: Color(0xFF43A047)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty ||
                          phoneCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('नाम और नंबर ज़रूरी है')),
                        );
                        return;
                      }
                      await _db.collection('hire_requests').add({
                        'workerId': widget.workerId,
                        'workerName': _worker?['name'],
                        'workerCategory': _worker?['category'],
                        'employerName': nameCtrl.text.trim(),
                        'employerPhone': phoneCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Hire Request भेज दी!'),
                          backgroundColor: Color(0xFF43A047),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Request भेजें'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingSheet() {
    double _stars = 5;
    final commentCtrl = TextEditingController();
    final employerCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⭐ Rating दें',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0))),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setS(() => _stars = (i + 1).toDouble()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < _stars ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              _field(employerCtrl, 'आपका नाम', Icons.person),
              const SizedBox(height: 10),
              _field(commentCtrl, 'Comment (optional)',
                  Icons.comment, lines: 2),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await _db.collection('worker_ratings').add({
                      'workerId': widget.workerId,
                      'workerName': _worker?['name'],
                      'rating': _stars,
                      'employerName': employerCtrl.text.trim(),
                      'comment': commentCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    // Update worker average rating
                    final allRatings = await _db
                        .collection('worker_ratings')
                        .where('workerId',
                            isEqualTo: widget.workerId)
                        .get();
                    if (allRatings.docs.isNotEmpty) {
                      final avg = allRatings.docs
                              .map((d) =>
                                  (d['rating'] as num).toDouble())
                              .reduce((a, b) => a + b) /
                          allRatings.docs.length;
                      await _db
                          .collection('workers')
                          .doc(widget.workerId)
                          .update({
                        'rating': double.parse(avg.toStringAsFixed(1)),
                        'ratingCount': allRatings.docs.length,
                      });
                    }
                    Navigator.pop(ctx);
                    _loadReviews();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⭐ Rating दे दी! शुक्रिया'),
                        backgroundColor: Color(0xFFFFC107),
                      ),
                    );
                  },
                  child: const Text('Rating Submit करें',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF1565C0))),
      );
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white),
        body: const Center(child: Text('Worker नहीं मिला')),
      );
    }

    final w = _worker!;
    final rating = (w['rating'] as num? ?? 0).toDouble();
    final verified = w['verified'] as bool? ?? false;
    final available = w['available'] as bool? ?? false;
    final isNew = (w['joinedDaysAgo'] as num? ?? 999) <= 7;
    final skills = (w['skills'] as List?)?.cast<String>() ??
        [w['category'] ?? 'General Labour'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareProfile,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            w['emoji'] ?? '👷',
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                        if (available)
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF43A047),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          w['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: Colors.lightBlueAccent, size: 18),
                        ],
                        if (isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('NEW',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${w['category']} • ${w['city']}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _statCard('⭐ Rating',
                          rating.toStringAsFixed(1),
                          const Color(0xFFFFC107)),
                      const SizedBox(width: 10),
                      _statCard(
                          '✅ Jobs',
                          '${w['completedJobs'] ?? 0}',
                          const Color(0xFF43A047)),
                      const SizedBox(width: 10),
                      _statCard(
                          '⏱️ Experience',
                          w['experience'] ?? '—',
                          const Color(0xFF1565C0)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Price & availability
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Daily Rate',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                              Text(
                                '₹${w['dailyRate'] ?? '—'}/दिन',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: available
                                  ? const Color(0xFF43A047)
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              available ? '✅ उपलब्ध' : '⏳ Busy',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Skills
                  const Text('🛠️ Skills',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: skills
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0)
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF1565C0)
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1565C0))),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // About
                  if ((w['about'] as String?)?.isNotEmpty == true) ...[
                    const Text('📖 About',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),
                    const SizedBox(height: 6),
                    Text(w['about'],
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // Ratings section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⭐ Reviews (${_reviews.length})',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0)),
                      ),
                      TextButton(
                        onPressed: _showRatingSheet,
                        child: const Text('+ Rating दें',
                            style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        child: Text('अभी कोई review नहीं',
                            style: TextStyle(
                                color: Colors.grey.shade500)),
                      ),
                    )
                  else
                    ..._reviews.map((r) => _ReviewTile(review: r)),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom CTA bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Call button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1565C0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _callWorker,
                  icon: const Icon(Icons.call, color: Color(0xFF1565C0)),
                ),
              ),
              const SizedBox(width: 8),
              // WhatsApp button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF43A047)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _openWhatsApp,
                  icon: const Text('💬',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 8),
              // Hire button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: available
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: available ? _showHireSheet : null,
                  child: Text(
                    available ? '📞 Hire करें' : '⏳ अभी Busy',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int lines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            Icon(icon, color: const Color(0xFF1565C0), size: 18),
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

// ---- Review Tile ----
class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final stars = (review['rating'] as num? ?? 5).toInt();
    final name = review['employerName'] as String? ?? 'Anonymous';
    final comment = review['comment'] as String? ?? '';
    final ts = review['createdAt'] as Timestamp?;
    final date = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    const Color(0xFF1565C0).withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 14,
                        )),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4)),
          ],
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(date,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }
}
