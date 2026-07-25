import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerMarketplaceScreen extends StatefulWidget {
  const WorkerMarketplaceScreen({super.key});

  @override
  State<WorkerMarketplaceScreen> createState() =>
      _WorkerMarketplaceScreenState();
}

class _WorkerMarketplaceScreenState extends State<WorkerMarketplaceScreen> {
  final _firestore = FirebaseFirestore.instance;

  // Filters
  String _selectedCategory = 'All';
  String _selectedExp = 'All';
  bool _availableOnly = false;
  int _maxSalary = 0; // 0 = no filter
  String _sortBy = 'Recent'; // 'Recent' | 'Rating' | 'Salary'

  final List<String> _categories = [
    'All', 'Construction', 'Driver', 'Security',
    'Housekeeping', 'Factory', 'Farming', 'Plumber', 'Electrician', 'Cook'
  ];
  final List<String> _expOptions = ['All', 'Fresher', '1-3 साल', '3+ साल'];
  final List<String> _sortOptions = ['Recent', 'Rating', 'Salary'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Marketplace'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort by',
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => _sortOptions
                .map((s) => PopupMenuItem(
                    value: s,
                    child: Row(children: [
                      Icon(
                          _sortBy == s ? Icons.check : Icons.sort,
                          size: 16,
                          color:
                              _sortBy == s ? const Color(0xFF1565C0) : Colors.grey),
                      const SizedBox(width: 8),
                      Text(s),
                    ])))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category filter row ──
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final sel = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: const Color(0xFF1565C0),
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.black87),
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              },
            ),
          ),

          // ── Experience + Available + Salary filter row ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Experience chips
                ..._expOptions.map((exp) {
                  final sel = exp == _selectedExp;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(exp,
                          style: const TextStyle(fontSize: 11)),
                      selected: sel,
                      onSelected: (_) =>
                          setState(() => _selectedExp = exp),
                      selectedColor: const Color(0xFFF57C00),
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontSize: 11),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                // Available today toggle
                FilterChip(
                  label: const Text('Available Today',
                      style: TextStyle(fontSize: 11)),
                  selected: _availableOnly,
                  onSelected: (v) => setState(() => _availableOnly = v),
                  selectedColor: Colors.green,
                  labelStyle: TextStyle(
                      color: _availableOnly ? Colors.white : Colors.black87,
                      fontSize: 11),
                  avatar: Icon(Icons.circle,
                      size: 8,
                      color: _availableOnly ? Colors.white : Colors.grey),
                ),
                const SizedBox(width: 6),
                // Salary filter
                PopupMenuButton<int>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _maxSalary > 0
                          ? Colors.purple.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _maxSalary > 0
                              ? Colors.purple
                              : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee, size: 13),
                        Text(
                          _maxSalary == 0
                              ? 'Budget'
                              : 'Max ₹$_maxSalary',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 0, child: Text('Any Budget')),
                    const PopupMenuItem(
                        value: 300, child: Text('Max ₹300/day')),
                    const PopupMenuItem(
                        value: 500, child: Text('Max ₹500/day')),
                    const PopupMenuItem(
                        value: 800, child: Text('Max ₹800/day')),
                    const PopupMenuItem(
                        value: 1200, child: Text('Max ₹1200/day')),
                  ],
                  onSelected: (v) => setState(() => _maxSalary = v),
                ),
              ],
            ),
          ),

          // ── Active filter indicator ──
          if (_selectedCategory != 'All' ||
              _selectedExp != 'All' ||
              _availableOnly ||
              _maxSalary > 0)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('Filters active',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedCategory = 'All';
                      _selectedExp = 'All';
                      _availableOnly = false;
                      _maxSalary = 0;
                      _sortBy = 'Recent';
                    }),
                    child: const Text('Clear All',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // ── Workers list ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No workers found',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedCategory = 'All';
                            _selectedExp = 'All';
                            _availableOnly = false;
                            _maxSalary = 0;
                          }),
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  );
                }

                List<QueryDocumentSnapshot> docs = snap.data!.docs;

                // Client-side filtering for experience and salary
                docs = docs.where((d) {
                  final w = d.data() as Map<String, dynamic>;
                  // Experience filter
                  if (_selectedExp != 'All') {
                    final exp = (w['experience'] ?? '').toString().toLowerCase();
                    if (_selectedExp == 'Fresher' &&
                        !exp.contains('fresher') &&
                        !exp.contains('0')) return false;
                    if (_selectedExp == '1-3 साल') {
                      final years = int.tryParse(
                              exp.replaceAll(RegExp(r'[^0-9]'), '')) ??
                          0;
                      if (years < 1 || years > 3) return false;
                    }
                    if (_selectedExp == '3+ साल') {
                      final years = int.tryParse(
                              exp.replaceAll(RegExp(r'[^0-9]'), '')) ??
                          0;
                      if (years < 3) return false;
                    }
                  }
                  // Salary filter
                  if (_maxSalary > 0) {
                    final sal = w['dailyWage'] ??
                        w['salary'] ??
                        w['expectedSalary'] ??
                        0;
                    final salNum = sal is int
                        ? sal
                        : int.tryParse(sal.toString().replaceAll(
                                RegExp(r'[^0-9]'), '')) ??
                            0;
                    if (salNum > _maxSalary) return false;
                  }
                  return true;
                }).toList();

                // Client-side sort
                if (_sortBy == 'Rating') {
                  docs.sort((a, b) {
                    final ra = (a.data()
                            as Map<String, dynamic>)['rating'] as num? ??
                        0;
                    final rb = (b.data()
                            as Map<String, dynamic>)['rating'] as num? ??
                        0;
                    return rb.compareTo(ra);
                  });
                } else if (_sortBy == 'Salary') {
                  docs.sort((a, b) {
                    final wa = a.data() as Map<String, dynamic>;
                    final wb = b.data() as Map<String, dynamic>;
                    final sa = (wa['dailyWage'] ?? wa['salary'] ?? 0) as num;
                    final sb = (wb['dailyWage'] ?? wb['salary'] ?? 0) as num;
                    return sa.compareTo(sb);
                  });
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No workers match your filters',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final w = docs[i].data() as Map<String, dynamic>;
                    return _WorkerCard(worker: w);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query q = _firestore.collection('workers');
    if (_selectedCategory != 'All') {
      q = q.where('category', isEqualTo: _selectedCategory);
    }
    if (_availableOnly) {
      q = q.where('available', isEqualTo: true);
    }
    // Default ordering
    if (_sortBy == 'Recent') {
      q = q.orderBy('createdAt', descending: true);
    }
    return q.snapshots();
  }
}

// ─── WORKER CARD ────────────────────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;

  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final name = worker['name'] ?? worker['naam'] ?? 'Worker';
    final category = worker['category'] ?? worker['skill'] ?? '';
    final location = worker['location'] ?? worker['jila'] ?? '';
    final experience = worker['experience'] ?? '';
    final salary = worker['dailyWage'] ?? worker['salary'] ?? '';
    final phone = worker['phone'] ?? worker['mobile'] ?? '';
    final available = worker['available'] == true;
    final rating = (worker['rating'] ?? worker['avgRating'] ?? 0.0) as num;
    final ratingCount = worker['ratingCount'] ?? 0;
    final photoUrl = worker['photoUrl'] ?? '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + info + available badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 22,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (available)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      size: 8, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text('Available',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (category.isNotEmpty)
                        Text(category,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Star Rating
            if (rating > 0) ...[
              Row(
                children: [
                  _buildStars(rating.toDouble()),
                  const SizedBox(width: 6),
                  Text('${rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                  if (ratingCount > 0)
                    Text('  ($ratingCount reviews)',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Info chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (location.isNotEmpty)
                  _chip(Icons.location_on, location, Colors.blue),
                if (experience.isNotEmpty)
                  _chip(Icons.work_history, experience, Colors.purple),
                if (salary.isNotEmpty)
                  _chip(Icons.currency_rupee, '₹$salary/day', Colors.green),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: phone.isNotEmpty
                        ? () => _call(phone)
                        : null,
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: phone.isNotEmpty
                        ? () => _whatsapp(phone, name, category)
                        : null,
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
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
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star, size: 16, color: Colors.orange);
        } else if (i < rating) {
          return const Icon(Icons.star_half, size: 16, color: Colors.orange);
        } else {
          return const Icon(Icons.star_border, size: 16, color: Colors.orange);
        }
      }),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String phone, String name, String skill) async {
    final msg = Uri.encodeComponent(
        'नमस्ते $name ji, मुझे $skill के लिए आपकी जरूरत है। KaamDhanda.in से contact कर रहा हूँ।');
    final uri = Uri.parse('https://wa.me/91$phone?text=$msg');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
