import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerMarketplaceScreen extends StatefulWidget {
  const WorkerMarketplaceScreen({Key? key}) : super(key: key);
  @override
  State<WorkerMarketplaceScreen> createState() => _WorkerMarketplaceScreenState();
}

class _WorkerMarketplaceScreenState extends State<WorkerMarketplaceScreen> {
  final _search = TextEditingController();
  String _cat = 'सभी';
  bool _availOnly = false;

  static const _kBlue = Color(0xFF1565C0);
  static const _kGreen = Color(0xFF25D366);

  static const _cats = <Map<String, String>>[
    {'l': 'सभी', 'e': '📂'},
    {'l': 'मजदूर', 'e': '🏗️'},
    {'l': 'ड्राइवर', 'e': '🚗'},
    {'l': 'इलेक्ट्रीशियन', 'e': '⚡'},
    {'l': 'प्लम्बर', 'e': '🔧'},
    {'l': 'सिक्योरिटी', 'e': '🛡️'},
    {'l': 'कारपेंटर', 'e': '🪵'},
    {'l': 'पेंटर', 'e': '🎨'},
    {'l': 'मिस्त्री', 'e': '🔨'},
    {'l': 'कुक', 'e': '🍽️'},
    {'l': 'डिलीवरी', 'e': '📦'},
    {'l': 'फैक्ट्री', 'e': '🏭'},
    {'l': 'अन्य', 'e': '✨'},
  ];

  bool _matchCat(String stored, String filter) {
    if (filter == 'सभी') return true;
    final s = stored.toLowerCase();
    final f = filter.toLowerCase();
    if (s.contains(f)) return true;
    const m = <String, List<String>>{
      'ड्राइवर': ['driver','cab','truck','driving'],
      'इलेक्ट्रीशियन': ['electric','electrician','wiring'],
      'प्लम्बर': ['plumber','plumbing','pipe'],
      'सिक्योरिटी': ['security','guard','watchman'],
      'कारपेंटर': ['carpenter','wood','furniture'],
      'पेंटर': ['painter','paint'],
      'मजदूर': ['mazdoor','labour','labor','helper'],
      'मिस्त्री': ['mistri','mason','राजमिस्त्री'],
      'कुक': ['cook','chef','kitchen','रसोइया'],
      'डिलीवरी': ['delivery','courier','logistics'],
      'फैक्ट्री': ['factory','manufacturing','production','operator','packing'],
    };
    return (m[filter] ?? []).any((k) => s.contains(k));
  }

  String _icon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('driver') || c.contains('ड्राइवर') || c.contains('cab')) return '🚗';
    if (c.contains('electric') || c.contains('इलेक्ट्रीशियन')) return '⚡';
    if (c.contains('plumb') || c.contains('प्लम्बर')) return '🔧';
    if (c.contains('security') || c.contains('guard')) return '🛡️';
    if (c.contains('carpenter') || c.contains('कारपेंटर')) return '🪵';
    if (c.contains('painter') || c.contains('पेंटर')) return '🎨';
    if (c.contains('mason') || c.contains('mistri') || c.contains('मिस्त्री')) return '🔨';
    if (c.contains('cook') || c.contains('chef') || c.contains('kitchen')) return '🍽️';
    if (c.contains('delivery') || c.contains('डिलीवरी')) return '📦';
    if (c.contains('factory') || c.contains('फैक्ट्री')) return '🏭';
    if (c.contains('mazdoor') || c.contains('मजदूर') || c.contains('labour')) return '🏗️';
    return '👷';
  }

  Future<void> _wa(Map<String, dynamic> d, String name) async {
    final raw = (d['whatsapp'] ?? d['phone'] ?? '').toString();
    final ph = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (ph.isEmpty) return;
    final cat = (d['jobType'] ?? d['category'] ?? 'काम').toString();
    final msg = Uri.encodeComponent('नमस्ते $name जी, मुझे $cat के लिए कारीगर चाहिए। काम धंधा ऐप से।');
    final url = Uri.parse('https://wa.me/91$ph?text=$msg');
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(Map<String, dynamic> d) async {
    final ph = (d['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (ph.isEmpty) return;
    if (await canLaunchUrl(Uri.parse('tel:$ph'))) launchUrl(Uri.parse('tel:$ph'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('👷 कारीगर ढूंढें',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('झारखंड के वेरिफाइड कामगार',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _availOnly = !_availOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _availOnly ? _kGreen : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _availOnly ? _kGreen : Colors.white38),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _availOnly ? Colors.white : Colors.white60,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text('✅ Available',
                    style: TextStyle(fontSize: 11, color: _availOnly ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: '🔍 नाम, काम या जिला खोजें...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () { _search.clear(); setState(() {}); })
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _cats.length,
                itemBuilder: (ctx, i) {
                  final sel = _cat == _cats[i]['l'];
                  return GestureDetector(
                    onTap: () => setState(() => _cat = _cats[i]['l']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? _kBlue : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: sel
                            ? [BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Text(
                        '${_cats[i]['e']} ${_cats[i]['l']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : Colors.black87,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Workers
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('workers').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _kBlue));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _empty('कोई कारीगर नहीं मिला', 'अभी कोई registered नहीं है');
                }

                final q = _search.text.trim().toLowerCase();
                final workers = snap.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  if (_availOnly && d['available'] != true) return false;
                  final cat = (d['jobType'] ?? d['category'] ?? '').toString();
                  if (!_matchCat(cat, _cat)) return false;
                  if (q.isNotEmpty) {
                    final name = (d['name'] ?? '').toString().toLowerCase();
                    final dist = (d['district'] ?? d['city'] ?? '').toString().toLowerCase();
                    final jt = (d['jobType'] ?? d['category'] ?? '').toString().toLowerCase();
                    if (!name.contains(q) && !dist.contains(q) && !jt.contains(q)) return false;
                  }
                  return true;
                }).toList();

                if (workers.isEmpty) {
                  return _empty('कोई कारीगर नहीं मिला', 'फ़िल्टर बदलकर देखें');
                }

                return Column(children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(children: [
                      Text('${workers.length} कारीगर मिले',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      if (_availOnly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text('✅ Available filter ON', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: _kBlue,
                      onRefresh: () async {},
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: workers.length,
                        itemBuilder: (ctx, i) => _workerCard(workers[i]),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _workerCard(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = (d['name'] ?? 'Unknown').toString();
    final jobType = (d['jobType'] ?? d['category'] ?? 'कारीगर').toString();
    // Clean display text (strip emoji prefix)
    final jobText = jobType.replaceAll(RegExp(r'^[\s\S]*?(?=[\u0900-\u097F])', unicode: true), '').trim();
    final display = jobText.isNotEmpty ? jobText : jobType;
    final district = (d['district'] ?? d['city'] ?? d['location'] ?? '').toString();
    final experience = (d['experience'] ?? '').toString();
    final available = d['available'] == true;
    final icon = _icon(jobType);
    final hasContact = (d['phone'] ?? d['whatsapp'] ?? '').toString().isNotEmpty;
    final phone = (d['phone'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        border: available ? Border.all(color: Colors.green.withOpacity(0.2), width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: _kBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
                  ),
                  if (available)
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          display.length > 20 ? '${display.substring(0, 20)}…' : display,
                          style: const TextStyle(fontSize: 11, color: _kBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (district.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(district, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ]),
                      ],
                    ],
                  ),
                ),
                // Availability badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: available ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: available ? Colors.green.shade200 : Colors.grey.shade300),
                  ),
                  child: Text(
                    available ? '✅ उपलब्ध' : '⏳ Busy',
                    style: TextStyle(
                      fontSize: 11,
                      color: available ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (experience.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                  child: Text('⏱️ $experience अनुभव',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                ),
                if (phone.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                    child: Text('📞 ${phone.length > 10 ? phone.substring(phone.length - 10) : phone}',
                        style: const TextStyle(fontSize: 12, color: _kBlue, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasContact ? () => _call(d) : null,
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call करें', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: const BorderSide(color: _kBlue),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasContact ? () => _wa(d, name) : null,
                  icon: const Text('💬', style: TextStyle(fontSize: 15)),
                  label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _empty(String t, String s) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('😔', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(s, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
    ]),
  );
}
