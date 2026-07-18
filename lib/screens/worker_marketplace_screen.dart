import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerMarketplaceScreen extends StatefulWidget {
  const WorkerMarketplaceScreen({Key? key}) : super(key: key);
  @override
  State<WorkerMarketplaceScreen> createState() => _WorkerMarketplaceScreenState();
}

class _WorkerMarketplaceScreenState extends State<WorkerMarketplaceScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeCategory = 'सभी';
  String _sortBy = 'newest';
  bool _availOnly = false;
  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

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
    {'label': 'Welder', 'icon': '🔩'},
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
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loading = true);
    try {
      // NO where() filter — get ALL workers
      final snap = await _db.collection('workers').limit(100).get();
      _allWorkers = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      _allWorkers = [];
    }
    _applyFilters();
    setState(() => _loading = false);
  }

  String _getCat(Map<String, dynamic> w) =>
      (w['jobType'] ?? w['category'] ?? '').toString();

  String _getLoc(Map<String, dynamic> w) =>
      (w['district'] ?? w['city'] ?? w['location'] ?? '').toString();

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    var list = List<Map<String, dynamic>>.from(_allWorkers);
    if (_availOnly) list = list.where((w) => w['available'] == true).toList();
    if (_activeCategory != 'सभी') {
      list = list.where((w) => _getCat(w).toLowerCase().contains(_activeCategory.toLowerCase())).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((w) =>
        (w['name'] ?? '').toString().toLowerCase().contains(query) ||
        _getCat(w).toLowerCase().contains(query) ||
        _getLoc(w).toLowerCase().contains(query)
      ).toList();
    }
    list.sort((a, b) {
      if (_sortBy == 'rating') return ((b['rating'] as num? ?? 0)).compareTo((a['rating'] as num? ?? 0));
      if (_sortBy == 'price_low') return ((a['dailyRate'] as num? ?? 0)).compareTo((b['dailyRate'] as num? ?? 0));
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
        title: const Text('👷 कारीगर ढूंढें', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_availOnly ? Icons.toggle_on : Icons.toggle_off, size: 28, color: _availOnly ? Colors.greenAccent : Colors.white60),
            tooltip: 'उपलब्ध कारीगर',
            onPressed: () { setState(() => _availOnly = !_availOnly); _applyFilters(); },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) { setState(() => _sortBy = val); _applyFilters(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rating', child: Text('⭐ Rating से')),
              const PopupMenuItem(value: 'price_low', child: Text('💰 कम Rate से')),
              const PopupMenuItem(value: 'newest', child: Text('🆕 नए पहले')),
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
                hintText: 'नाम, काम या जिला खोजें...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18), onPressed: () { _searchCtrl.clear(); _applyFilters(); })
                    : null,
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : RefreshIndicator(
              onRefresh: _loadWorkers,
              color: const Color(0xFF1565C0),
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(child: _buildCategories()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(children: [
                      Text(_filtered.length.toString() + ' कारीगर मिले', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      const Spacer(),
                      if (_availOnly) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade300)),
                        child: const Text('✅ उपलब्ध', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ),
                    ]),
                  ),
                ),
                _filtered.isEmpty
                    ? SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(_allWorkers.isEmpty ? 'अभी कोई कारीगर उपलब्ध नहीं' : 'कोई कारीगर नहीं मिला', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                        if (_allWorkers.isEmpty) TextButton(onPressed: _loadWorkers, child: const Text('फिर से कोशिश करें')),
                      ])))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _WorkerCard(worker: _filtered[i], getCat: _getCat, getLoc: _getLoc, onHire: () => _showHireSheet(context, _filtered[i])),
                          childCount: _filtered.length,
                        )),
                      ),
              ]),
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
            onTap: () { setState(() => _activeCategory = cat['label'] as String); _applyFilters(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1565C0) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? const Color(0xFF1565C0) : Colors.grey.shade300),
                boxShadow: active ? [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
              ),
              child: Text(
                cat['icon'].toString() + ' ' + cat['label'].toString(),
                style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.black87, fontWeight: active ? FontWeight.bold : FontWeight.normal),
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
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: const Color(0xFF1565C0).withOpacity(0.1), child: Text((worker['emoji'] ?? '👷').toString(), style: const TextStyle(fontSize: 20))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((worker['name'] ?? '').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(_getCat(worker) + ' • ' + _getLoc(worker), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ])),
          ]),
          const Divider(height: 20),
          const Text('📋 Hire / WhatsApp करें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          const SizedBox(height: 14),
          TextField(controller: nameCtrl, decoration: InputDecoration(hintText: 'आपका नाम *', prefixIcon: const Icon(Icons.person, color: Color(0xFF1565C0), size: 18), filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
          const SizedBox(height: 10),
          TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: 'आपका मोबाइल *', prefixIcon: const Icon(Icons.phone, color: Color(0xFF1565C0), size: 18), filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final raw = (worker['whatsapp'] ?? worker['phone'] ?? '').toString();
                final ph = raw.replaceAll(RegExp(r'[^0-9]'), '');
                if (ph.isEmpty) return;
                final num = (ph.startsWith('91') && ph.length > 10) ? ph : '91' + ph;
                final cat = _getCat(worker);
                final msgText = Uri.encodeComponent('नमस्ते, मुझे ' + cat + ' कारीगर चाहिए। काम धंधा ऐप से।');
                final uri = Uri.parse('https://wa.me/' + num + '?text=' + msgText);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Text('💬', style: TextStyle(fontSize: 16)),
              label: const Text('WhatsApp'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF43A047), side: const BorderSide(color: Color(0xFF43A047)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('नाम और नंबर ज़रूरी है')));
                  return;
                }
                await FirebaseFirestore.instance.collection('hire_requests').add({
                  'workerId': worker['id'], 'workerName': worker['name'],
                  'workerCategory': _getCat(worker), 'employerName': nameCtrl.text.trim(),
                  'employerPhone': phoneCtrl.text.trim(), 'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Request भेज दी गई!'), backgroundColor: Color(0xFF43A047)));
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Request भेजें'),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final String Function(Map<String, dynamic>) getCat;
  final String Function(Map<String, dynamic>) getLoc;
  final VoidCallback onHire;
  const _WorkerCard({required this.worker, required this.getCat, required this.getLoc, required this.onHire});

  @override
  Widget build(BuildContext context) {
    final name = (worker['name'] ?? 'कारीगर').toString();
    final rating = (worker['rating'] as num? ?? 0).toDouble();
    final available = worker['available'] as bool? ?? false;
    final verified = worker['verified'] as bool? ?? false;
    final jobs = (worker['completedJobs'] as num? ?? 0).toInt();
    final experience = (worker['experience'] ?? '').toString();
    final dailyRate = worker['dailyRate'] as num?;
    final emoji = (worker['emoji'] ?? '👷').toString();
    final category = getCat(worker);
    final location = getLoc(worker);
    final state = (worker['state'] ?? '').toString();
    final locStr = location.isNotEmpty ? (state.isNotEmpty ? location + ', ' + state : location) : state;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              CircleAvatar(radius: 28, backgroundColor: const Color(0xFF1565C0).withOpacity(0.1), child: Text(emoji, style: const TextStyle(fontSize: 26))),
              if (available) Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF43A047), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                if (verified) const Text('✅', style: TextStyle(fontSize: 12)),
              ]),
              const SizedBox(height: 3),
              if (category.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(category.length > 20 ? category.substring(0, 20) : category, style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              if (locStr.isNotEmpty) Row(children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                const SizedBox(width: 2),
                Flexible(child: Text(locStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
              ]),
            ])),
            if (rating > 0) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFFC107))),
              ]),
              if (jobs > 0) Text(jobs.toString() + ' jobs', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ]),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (experience.isNotEmpty) _chip('⏱️ ' + experience, Colors.blue.shade50, Colors.blue.shade700),
            if (dailyRate != null) _chip('₹' + dailyRate.toString() + '/दिन', Colors.orange.shade50, Colors.orange.shade800),
            _chip(available ? '✅ उपलब्ध' : '⏳ Busy', available ? Colors.green.shade50 : Colors.red.shade50, available ? Colors.green.shade700 : Colors.red.shade700),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: available ? const Color(0xFF1565C0) : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: available ? onHire : null,
            child: Text(available ? '📞 Hire करें / WhatsApp' : '⏳ अभी Busy है', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}