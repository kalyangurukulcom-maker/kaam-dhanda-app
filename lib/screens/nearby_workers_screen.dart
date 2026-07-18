import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyWorkersScreen extends StatefulWidget {
  const NearbyWorkersScreen({super.key});
  @override
  State<NearbyWorkersScreen> createState() => _NearbyWorkersScreenState();
}

class _NearbyWorkersScreenState extends State<NearbyWorkersScreen> {
  final _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _selectedCat = 'सभी';
  bool _availableOnly = false;
  String _searchText = '';
  final _searchCtrl = TextEditingController();

  static const List<String> _cats = [
    'सभी', 'ड्राइवर', 'निर्माण', 'सिक्योरिटी', 'दुकान',
    'इलेक्ट्रीशियन', 'फैक्ट्री', 'डिलीवरी', 'होटल', 'अन्य',
  ];
  static const Map<String, String> _catEmoji = {
    'सभी': '📂', 'ड्राइवर': '🚗', 'निर्माण': '🏗️', 'सिक्योरिटी': '🛡️',
    'दुकान': '🏪', 'इलेक्ट्रीशियन': '⚡', 'फैक्ट्री': '🏭',
    'डिलीवरी': '🛵', 'होटल': '🍽️', 'अन्य': '✨',
  };
  static const Map<String, List<String>> _catKw = {
    'ड्राइवर': ['driver', 'cab', 'truck', 'driving'],
    'निर्माण': ['construction', 'building', 'civil', 'mason', 'mistri'],
    'सिक्योरिटी': ['security', 'guard', 'watchman'],
    'दुकान': ['shop', 'retail', 'sales'],
    'इलेक्ट्रीशियन': ['electric', 'electrician', 'wiring'],
    'फैक्ट्री': ['factory', 'manufacturing', 'production', 'packing'],
    'डिलीवरी': ['delivery', 'courier', 'logistics'],
    'होटल': ['hotel', 'cook', 'chef', 'waiter', 'kitchen'],
  };

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loading = true);
    try {
      // NO where() filter — fetch ALL workers, no isActive/isAvailable filter
      final snap = await _db.collection('workers').limit(200).get();
      _allWorkers = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      _allWorkers = [];
    }
    _applyFilters();
    setState(() => _loading = false);
  }

  String _getJobType(Map<String, dynamic> w) =>
      (w['jobType'] ?? w['category'] ?? '').toString();

  String _getLocation(Map<String, dynamic> w) =>
      (w['district'] ?? w['city'] ?? w['location'] ?? '').toString();

  bool _isAvailable(Map<String, dynamic> w) {
    final a = w['available'];
    if (a == null) return true;
    if (a is bool) return a;
    return a.toString().toLowerCase() == 'true';
  }

  bool _matchCat(Map<String, dynamic> w) {
    if (_selectedCat == 'सभी') return true;
    final jt = _getJobType(w).toLowerCase();
    if (jt.contains(_selectedCat.toLowerCase())) return true;
    return (_catKw[_selectedCat] ?? []).any((k) => jt.contains(k));
  }

  void _applyFilters() {
    setState(() {
      _filtered = _allWorkers.where((w) {
        final jt = _getJobType(w).toLowerCase();
        final nm = (w['name'] ?? '').toString().toLowerCase();
        final loc = _getLocation(w).toLowerCase();
        final q = _searchText.toLowerCase();
        if (q.isNotEmpty && !nm.contains(q) && !jt.contains(q) && !loc.contains(q)) {
          return false;
        }
        if (_availableOnly && !_isAvailable(w)) return false;
        return _matchCat(w);
      }).toList();
    });
  }

  Future<void> _openWhatsApp(Map<String, dynamic> w) async {
    final raw = (w['whatsapp'] ?? w['phone'] ?? '').toString();
    final ph = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (ph.isEmpty) return;
    final num = (ph.startsWith('91') && ph.length > 10) ? ph : '91$ph';
    final name = w['name'] ?? 'कारीगर';
    final msg = Uri.encodeComponent(
        'नमस्ते $name जी, मुझे आपसे काम के बारे में बात करनी है। (काम धंधा ऐप से)');
    final uri = Uri.parse('https://wa.me/$num?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('📍 पास के कारीगर',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWorkers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _searchText = v;
                _applyFilters();
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'नाम, काम या जगह खोजें...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _cats.length,
              itemBuilder: (_, i) {
                final c = _cats[i];
                final sel = c == _selectedCat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCat = c);
                    _applyFilters();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF1565C0) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1565C0)),
                    ),
                    child: Text(
                      '${_catEmoji[c] ?? ''} $c',
                      style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF1565C0),
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Stats + available toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_filtered.length} कारीगर मिले',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                const Text('सिर्फ उपलब्ध', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _availableOnly,
                  onChanged: (v) {
                    setState(() => _availableOnly = v);
                    _applyFilters();
                  },
                  activeColor: const Color(0xFF1565C0),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('कोई कारीगर नहीं मिला',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('फिर से खोजें'),
                              onPressed: _loadWorkers,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _WorkerCard(
                          worker: _filtered[i],
                          getJobType: _getJobType,
                          getLocation: _getLocation,
                          isAvailable: _isAvailable,
                          onWhatsApp: () => _openWhatsApp(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final String Function(Map<String, dynamic>) getJobType;
  final String Function(Map<String, dynamic>) getLocation;
  final bool Function(Map<String, dynamic>) isAvailable;
  final VoidCallback onWhatsApp;

  const _WorkerCard({
    required this.worker,
    required this.getJobType,
    required this.getLocation,
    required this.isAvailable,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final name = (worker['name'] ?? 'कारीगर').toString();
    final jt = getJobType(worker);
    final loc = getLocation(worker);
    final avail = isAvailable(worker);
    final exp = (worker['experience'] ?? worker['experience_years'] ?? '').toString();
    final rating = double.tryParse(worker['rating']?.toString() ?? '') ?? 0;
    final verified = worker['verified'] == true;
    final pic = (worker['profilePic'] ?? worker['photo'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
              backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
              child: pic.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'क',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0)),
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
                                fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (verified)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.verified,
                              color: Color(0xFF1565C0), size: 16),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: avail
                              ? const Color(0xFF25D366).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          avail ? '✅ उपलब्ध' : '⏸ व्यस्त',
                          style: TextStyle(
                            fontSize: 10,
                            color: avail
                                ? const Color(0xFF25D366)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (jt.isNotEmpty)
                    Text(jt,
                        style: const TextStyle(
                            color: Color(0xFF1565C0), fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (loc.isNotEmpty) ...[
                        const Icon(Icons.location_on,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(loc,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      if (exp.isNotEmpty) ...[
                        const Icon(Icons.work_outline,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text('$exp साल',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < rating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                )),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onWhatsApp,
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('WhatsApp पर संपर्क करें',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
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
}
