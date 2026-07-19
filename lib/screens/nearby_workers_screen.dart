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
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;
  String _selectedCategory = 'सभी';

  final List<String> _categories = [
    'सभी', 'राजमिस्त्री', 'प्लंबर', 'इलेक्ट्रिशियन',
    'पेंटर', 'कारपेंटर', 'दर्जी', 'रसोइया',
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final snap = await _db.collection('workers').limit(50).get();
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        list.add(data);
      }
      if (mounted) setState(() { _workers = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedCategory == 'सभी') return _workers;
    return _workers.where((w) {
      final jt = (w['jobType'] ?? w['category'] ?? '').toString();
      return jt.contains(_selectedCategory);
    }).toList();
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final num = digits.length == 10 ? '91$digits' : digits;
    final uri = Uri.parse('https://wa.me/$num');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text(
          'पास के कारीगर',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _CategoryBar(
            categories: _categories,
            selected: _selectedCategory,
            onSelect: (c) => setState(() => _selectedCategory = c),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'कोई कारीगर नहीं मिला',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWorkers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final w = _filtered[i];
                            final phone = (w['whatsapp'] ?? w['phone'] ?? '').toString();
                            return _NearbyWorkerCard(
                              worker: w,
                              onWhatsApp: phone.isNotEmpty ? () => _openWhatsApp(phone) : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final isSel = categories[i] == selected;
          return GestureDetector(
            onTap: () => onSelect(categories[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF1565C0) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                categories[i],
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NearbyWorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final VoidCallback? onWhatsApp;

  const _NearbyWorkerCard({required this.worker, this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    final name = (worker['name'] ?? worker['workerName'] ?? 'कारीगर').toString();
    final jobType = (worker['jobType'] ?? worker['category'] ?? 'अन्य').toString();
    final district = (worker['district'] ?? worker['city'] ?? '').toString();
    final available = worker['available'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'क',
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(jobType, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 14)),
                  if (district.isNotEmpty)
                    Text('📍 $district', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: available ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      available ? '✅ उपलब्ध' : '❌ व्यस्त',
                      style: TextStyle(
                        color: available ? Colors.green.shade700 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onWhatsApp != null)
              ElevatedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('संपर्क', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
