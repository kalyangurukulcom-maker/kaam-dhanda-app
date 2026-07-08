// ============================================================
// Feature #109: Testimonials / Success Stories
// File: lib/screens/testimonials_screen.dart
// Kaam Dhanda App — Flutter
//
// Includes:
//   1. TestimonialsScreen     — full standalone page
//   2. TestimonialsCarousel   — reusable horizontal widget
//                               (Home Screen mein embed karo)
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ---- Demo stories ----
const List<Map<String, dynamic>> _demoStories = [
  {
    'id': 's1',
    'name': 'राजेश कुमार',
    'role': 'डिलीवरी पार्टनर, Zepto',
    'city': 'बेंगलुरु',
    'type': 'bahar',
    'emoji': '🛵',
    'quote':
        'काम धंधा से अप्लाई किया और 3 दिन में Zepto का कॉल आ गया। रहने की व्यवस्था भी कंपनी ने की। अब ₹28,000 कमा रहा हूँ।',
    'salary': 28000,
    'stars': 5,
    'color': 0xFF1565C0,
  },
  {
    'id': 's2',
    'name': 'सुरेश मुंडा',
    'role': 'इलेक्ट्रीशियन',
    'city': 'रांची',
    'type': 'local',
    'emoji': '⚡',
    'quote':
        'रांची में ही काम मिल गया। घर के पास काम है तो परिवार के साथ हूँ। ₹18,000 महीना मिलता है, कोई कमीशन नहीं।',
    'salary': 18000,
    'stars': 5,
    'color': 0xFF43A047,
  },
  {
    'id': 's3',
    'name': 'प्रिया देवी',
    'role': 'फैक्ट्री वर्कर, Tata Motors',
    'city': 'पुणे',
    'type': 'bahar',
    'emoji': '🏭',
    'quote':
        'पुणे में Tata Motors में काम मिला। रहना-खाना फ्री है। ₹22,000 में से सारा पैसा घर भेज सकती हूँ।',
    'salary': 22000,
    'stars': 5,
    'color': 0xFF8E24AA,
  },
  {
    'id': 's4',
    'name': 'मोहम्मद आरिफ',
    'role': 'Ola ड्राइवर',
    'city': 'धनबाद',
    'type': 'local',
    'emoji': '🚗',
    'quote':
        'Ola में ड्राइवर का काम मिला, धनबाद में। खुद का समय खुद तय होता है। महीने में ₹22-25 हज़ार हो जाते हैं।',
    'salary': 23000,
    'stars': 5,
    'color': 0xFFFF8F00,
  },
  {
    'id': 's5',
    'name': 'बिरसा उराँव',
    'role': 'वेयरहाउस हेल्पर, Amazon',
    'city': 'दिल्ली NCR',
    'type': 'bahar',
    'emoji': '📦',
    'quote':
        'दिल्ली Amazon में जॉब मिली। OT मिला तो ₹25,000 हो गए। काम धंधा ने ट्रेन टिकट दिलवाने में भी मदद की।',
    'salary': 25000,
    'stars': 5,
    'color': 0xFF00897B,
  },
  {
    'id': 's6',
    'name': 'अनीता सिन्हा',
    'role': 'सिक्योरिटी गार्ड, G4S',
    'city': 'जमशेदपुर',
    'type': 'local',
    'emoji': '🛡️',
    'quote':
        'जमशेदपुर में G4S Security में जॉब मिली। परिवार के साथ रह सकती हूँ। बच्चों की पढ़ाई भी चल रही है।',
    'salary': 14500,
    'stars': 5,
    'color': 0xFFE53935,
  },
];

// ============================================================
// 1. Full Testimonials Screen
// ============================================================
class TestimonialsScreen extends StatefulWidget {
  const TestimonialsScreen({Key? key}) : super(key: key);

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _stories = [];
  String _filter = 'all'; // all / local / bahar
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _db
          .collection('testimonials')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      _stories = snap.docs.isNotEmpty
          ? snap.docs.map((d) => {...d.data(), 'id': d.id}).toList()
          : _demoStories;
    } catch (_) {
      _stories = _demoStories;
    }
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _stories;
    return _stories.where((s) => s['type'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          '🌟 Success Stories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF1565C0),
              child: CustomScrollView(
                slivers: [
                  // Header banner
                  SliverToBoxAdapter(child: _buildBanner()),

                  // Filter chips
                  SliverToBoxAdapter(child: _buildFilterChips()),

                  // Count
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        '${_filtered.length} success stories',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ),

                  // Story cards
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _StoryCard(story: _filtered[i]),
                        childCount: _filtered.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '🎉 असली लोग, असली कहानियाँ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'काम धंधा से नौकरी पाने वाले हज़ारों लोगों की कहानियाँ',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bannerStat('8,700+', 'Placements'),
              _vDiv(),
              _bannerStat('120+', 'Cities'),
              _vDiv(),
              _bannerStat('4.8 ⭐', 'Avg Rating'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(String val, String label) => Column(
        children: [
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _vDiv() => Container(
      width: 1, height: 32, color: Colors.white.withOpacity(0.25));

  Widget _buildFilterChips() {
    const filters = [
      {'key': 'all', 'label': '🌐 सभी'},
      {'key': 'local', 'label': '🏠 Local'},
      {'key': 'bahar', 'label': '✈️ Bahar'},
    ];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final active = _filter == filters[i]['key'];
          return GestureDetector(
            onTap: () => setState(() => _filter = filters[i]['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 6),
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
              ),
              child: Text(
                filters[i]['label']!,
                style: TextStyle(
                  fontSize: 13,
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
}

// ---- Story Card ----
class _StoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final color = Color(story['color'] as int? ?? 0xFF1565C0);
    final stars = (story['stars'] as int? ?? 5);
    final salary = story['salary'] as int? ?? 0;
    final isLocal = (story['type'] as String? ?? '') == 'local';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('"',
                    style: TextStyle(
                        fontSize: 48,
                        color: color.withOpacity(0.3),
                        height: 0.8,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    story['quote'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Author row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    story['emoji'] ?? '👷',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        story['role'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 11, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            story['city'] ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right side: salary + type + stars
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLocal
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLocal
                              ? Colors.green.shade300
                              : Colors.blue.shade300,
                        ),
                      ),
                      child: Text(
                        isLocal ? '🏠 Local' : '✈️ Bahar',
                        style: TextStyle(
                          fontSize: 10,
                          color: isLocal
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_fmt(salary)}/माह',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < stars
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFFFFC107),
                                size: 12,
                              )),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '$n';
  }
}

// ============================================================
// 2. Reusable Testimonials Carousel (Home Screen mein use karo)
// ============================================================
class TestimonialsCarousel extends StatefulWidget {
  const TestimonialsCarousel({Key? key}) : super(key: key);

  @override
  State<TestimonialsCarousel> createState() =>
      _TestimonialsCarouselState();
}

class _TestimonialsCarouselState extends State<TestimonialsCarousel> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  List<Map<String, dynamic>> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('testimonials')
          .limit(6)
          .get();
      _stories = snap.docs.isNotEmpty
          ? snap.docs.map((d) => {...d.data(), 'id': d.id}).toList()
          : _demoStories;
    } catch (_) {
      _stories = _demoStories;
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 160,
        child: Center(
            child:
                CircularProgressIndicator(color: Color(0xFF1565C0))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              const Text(
                '🌟 Success Stories',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TestimonialsScreen()),
                ),
                child: const Text(
                  'सभी देखें →',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _stories.length,
            itemBuilder: (ctx, i) =>
                _CarouselCard(story: _stories[i]),
          ),
        ),
        const SizedBox(height: 8),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _stories.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final Map<String, dynamic> story;
  const _CarouselCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final color = Color(story['color'] as int? ?? 0xFF1565C0);
    final salary = story['salary'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: [
              ...List.generate(
                  5,
                  (_) => const Icon(Icons.star,
                      color: Color(0xFFFFC107), size: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${salary ~/ 1000}k/माह',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quote
          Expanded(
            child: Text(
              story['quote'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // Author
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  story['emoji'] ?? '👷',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${story['role']} • ${story['city']}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
