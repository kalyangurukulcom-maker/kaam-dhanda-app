// ============================================================
// Feature #85: Worker Marketplace Screen
// File: lib/screens/worker_marketplace_screen.dart
// Kaam Dhanda App — Flutter
//
// pubspec.yaml mein add karo:
//   url_launcher: ^6.2.5
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerMarketplaceScreen extends StatefulWidget {
  const WorkerMarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<WorkerMarketplaceScreen> createState() =>
      _WorkerMarketplaceScreenState();
}

class _WorkerMarketplaceScreenState extends State<WorkerMarketplaceScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String _activeCategory = 'सभी';
  String _sortBy = 'rating';
  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  // Categories
  static const List<Map<String, dynamic>> _categories = [
    {'label': 'सभी', 'icon': '👷'},
    {'label': 'इलेक्ट्रीशियन', 'icon': '⚡'},
    {'label': 'प्लम्बर', 'icon': '🔧'},
    {'label': 'कारपेंटर', 'icon': '🪵'},
    {'label': 'पेंटर', 'icon': '🎨'},
    {'label': 'मजदूर', 'icon': '🏗️'},
    {'label': 'ड्राइवर', 'icon': '🚗'},
    {'label': 'सिक्योरिटी', 'icon': '🛡️'},
    {'label': 'Cook', 'icon': '🍽️'},
    {'label': 'AC Technician', 'icon': '❄️'},
    {'label': 'Welder', 'icon': '🔩'},
  ];

  // Demo workers fallback
  static final List<Map<String, dynamic>> _demoWorkers = [
    {
      'id': 'd1', 'name': 'राजेश कुमार', 'category': 'इलेक्ट्रीशियन',
      'city': 'रांची', 'state': 'Jharkhand', 'rating': 4.8,
      'experience': '5 साल', 'dailyRate': 800, 'available': true,
      'phone': '9876543210', 'verified': true, 'emoji': '⚡',
      'completedJobs': 142, 'joinedDaysAgo': 3,
    },
    {
      'id': 'd2', 'name': 'सुनील मिस्त्री', 'category': 'प्लम्बर',
      'city': 'धनबाद', 'state': 'Jharkhand', 'rating': 4.5,
      'experience': '3 साल', 'dailyRate': 700, 'available': true,
      'phone': '9876543211', 'verified': true, 'emoji': '🔧',
      'completedJobs': 89, 'joinedDaysAgo': 10,
    },
    {
      'id': 'd3', 'name': 'मोहन कारपेंटर', 'category': 'कारपेंटर',
      'city': 'जमशेदपुर', 'state': 'Jharkhand', 'rating': 4.7,
      'experience': '7 साल', 'dailyRate': 900, 'available': false,
      'phone': '9876543212', 'verified': true, 'emoji': '🪵',
      'completedJobs': 203, 'joinedDaysAgo': 25,
    },
    {
      'id': 'd4', 'name': 'रमेश पेंटर', 'category': 'पेंटर',
      'city': 'रांची', 'state': 'Jharkhand', 'rating': 4.3,
      'experience': '4 साल', 'dailyRate': 650, 'available': true,
      'phone': '9876543213', 'verified': false, 'emoji': '🎨',
      'completedJobs': 67, 'joinedDaysAgo': 5,
    },
    {
      'id': 'd5', 'name': 'अजय ड्राइवर', 'category': 'ड्राइवर',
      'city': 'पुणे', 'state': 'Maharashtra', 'rating': 4.9,
      'experience': '6 साल', 'dailyRate': 1000, 'available': true,
      'phone': '9876543214', 'verified': true, 'emoji': '🚗',
      'completedJobs': 318, 'joinedDaysAgo': 1,
    },
    {
      'id': 'd6', 'name': 'प्रकाश सिक्योरिटी', 'category': 'सिक्योरिटी',
      'city': 'बेंगलुरु', 'state': 'Karnataka', 'rating': 4.4,
      'experience': '2 साल', 'dailyRate': 600, 'available': true,
      'phone': '9876543215', 'verified': true, 'emoji': '🛡️',
      'completedJobs': 45, 'joinedDaysAgo': 15,
    },
    {
      'id': 'd7', 'name': 'संजय वेल्डर', 'category': 'Welder',
      'city': 'बोकारो', 'state': 'Jharkhand', 'rating': 4.6,
      'experience': '8 साल', 'dailyRate': 950, 'available': true,
      'phone': '9876543216', 'verified': true, 'emoji': '🔩',
      'completedJobs': 177, 'joinedDaysAgo': 30,
    },
    {
      'id': 'd8', 'name': 'गीता Cook', 'category': 'Cook',
      'city': 'दिल्ली', 'state': 'Delhi', 'rating': 4.7,
      'experience': '5 साल', 'dailyRate': 750, 'available': true,
      'phone': '9876543217', 'verified': true, 'emoji': '🍽️',
      'completedJobs': 124, 'joinedDaysAgo': 7,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loading = true);
    try {
      final snap = await _db
          .collection('workers')
          .where('isActive', isEqualTo: true)
          .limit(60)
          .get();

      if (snap.docs.isNotEmpty) {
        _allWorkers = snap.docs.map((d) {
          final data = d.data();
          return {...data, 'id': d.id};
        }).toList();
      } else {
        _allWorkers = _demoWorkers;
      }
    } catch (_) {
      _allWorkers = _demoWorkers;
    }
    _applyFilters();
    setState(() => _loading = false);
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    var list = List<Map<String, dynamic>>.from(_allWorkers);

    // Category filter
    if (_activeCategory != 'सभी') {
      list = list
          .where((w) =>
              (w['category'] as String? ?? '').toLowerCase() ==
              _activeCategory.toLowerCase())
          .toList();
    }

    // Search filter
    if (query.isNotEmpty) {
      list = list
          .where((w) =>
              (w['name'] as String? ?? '').toLowerCase().contains(query) ||
              (w['category'] as String? ?? '').toLowerCase().contains(query) ||
              (w['city'] as String? ?? '').toLowerCase().contains(query))
          .toList();
    }

    // Sort
    list.sort((a, b) {
      if (_sortBy == 'rating') {
        return ((b['rating'] as num? ?? 0))
            .compareTo((a['rating'] as num? ?? 0));
      } else if (_sortBy == 'price_low') {
        return ((a['dailyRate'] as num? ?? 0))
            .compareTo((b['dailyRate'] as num? ?? 0));
      } else if (_sortBy == 'newest') {
        return ((a['joinedDaysAgo'] as num? ?? 999))
            .compareTo((b['joinedDaysAgo'] as num? ?? 999));
      }
      return 0;
    });

    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          '👷 कारीगर ढूंढें',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (val) {
              setState(() => _sortBy = val);
              _applyFilters();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'rating', child: Text('⭐ Rating से')),
              const PopupMenuItem(
                  value: 'price_low', child: Text('💰 कम Price से')),
              const PopupMenuItem(
                  value: 'newest', child: Text('🆕 नए पहले')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'नाम, काम या शहर खोजें...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : RefreshIndicator(
              onRefresh: _loadWorkers,
              color: const Color(0xFF1565C0),
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  // Category chips
                  SliverToBoxAdapter(child: _buildCategories()),

                  // Count bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${_filtered.length} कारीगर मिले',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          Text(
                            _sortBy == 'rating'
                                ? '⭐ Rating से'
                                : _sortBy == 'price_low'
                                    ? '💰 Price से'
                                    : '🆕 Newest',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF1565C0)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Worker cards
                  _filtered.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 60,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'कोई कारीगर नहीं मिला',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _WorkerCard(
                                worker: _filtered[i],
                                onHire: () =>
                                    _showHireSheet(context, _filtered[i]),
                              ),
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final active = _activeCategory == cat['label'];
          return GestureDetector(
            onTap: () {
              setState(() => _activeCategory = cat['label'] as String);
              _applyFilters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1565C0)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade300,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                '${cat['icon']} ${cat['label']}',
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.white : Colors.black87,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHireSheet(BuildContext context, Map<String, dynamic> worker) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();

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
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      const Color(0xFF1565C0).withOpacity(0.1),
                  child: Text(
                    worker['emoji'] ?? '👷',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${worker['category']} • ${worker['city']}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              '📋 Hire Request भेजें',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 14),
            _field(nameCtrl, 'आपका नाम *', Icons.person),
            const SizedBox(height: 10),
            _field(phoneCtrl, 'आपका मोबाइल *', Icons.phone,
                type: TextInputType.phone),
            const SizedBox(height: 10),
            _field(descCtrl, 'काम का विवरण (optional)', Icons.description,
                lines: 2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://wa.me/91${worker['phone']}?text=नमस्ते, मुझे ${worker['category']} चाहिए');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                    icon: const Text('💬', style: TextStyle(fontSize: 16)),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF43A047),
                      side: const BorderSide(color: Color(0xFF43A047)),
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
                      if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('नाम और नंबर ज़रूरी है')),
                        );
                        return;
                      }
                      await FirebaseFirestore.instance
                          .collection('hire_requests')
                          .add({
                        'workerId': worker['id'],
                        'workerName': worker['name'],
                        'workerCategory': worker['category'],
                        'employerName': nameCtrl.text.trim(),
                        'employerPhone': phoneCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Request भेज दी गई!'),
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

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int lines = 1,
  }) {
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

// ---- Worker Card ----
class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final VoidCallback onHire;

  const _WorkerCard({required this.worker, required this.onHire});

  @override
  Widget build(BuildContext context) {
    final rating = (worker['rating'] as num? ?? 0).toDouble();
    final available = worker['available'] as bool? ?? false;
    final verified = worker['verified'] as bool? ?? false;
    final isNew = (worker['joinedDaysAgo'] as num? ?? 999) <= 7;
    final jobs = worker['completedJobs'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          const Color(0xFF1565C0).withOpacity(0.1),
                      child: Text(
                        worker['emoji'] ?? '👷',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    if (available)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.green.shade300),
                              ),
                              child: const Text('🆕 New',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              worker['category'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (verified)
                            const Text('✅',
                                style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            '${worker['city']}, ${worker['state']}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFC107),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$jobs jobs',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Info chips row
            Row(
              children: [
                _chip('⏱️ ${worker['experience']}', Colors.blue.shade50,
                    Colors.blue.shade700),
                const SizedBox(width: 8),
                _chip('₹${worker['dailyRate']}/दिन',
                    Colors.orange.shade50, Colors.orange.shade800),
                const SizedBox(width: 8),
                _chip(
                  available ? '✅ उपलब्ध' : '⏳ Busy',
                  available
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  available
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hire button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: available
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: available ? 2 : 0,
                ),
                onPressed: available ? onHire : null,
                child: Text(
                  available ? '📞 Hire करें' : '⏳ अभी Busy है',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600)),
    );
  }
}
