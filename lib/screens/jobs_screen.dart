import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'सभी';

  static const _kBlue = Color(0xFF1565C0);
  static const _kGreen = Color(0xFF25D366);

  static const _cats = [
    'सभी','निर्माण','ड्राइवर','सिक्योरिटी',
    'दुकान','इलेक्ट्रीशियन','फैक्ट्री','डिलीवरी','होटल','अन्य',
  ];

  static const _catEmoji = {
    'सभी':'📂','निर्माण':'🏗️','ड्राइवर':'🚗','सिक्योरिटी':'🛡️',
    'दुकान':'🏪','इलेक्ट्रीशियन':'⚡','फैक्ट्री':'🏭',
    'डिलीवरी':'🛵','होटल':'🍽️','अन्य':'✨',
  };

  static const _baharCities = [
    'pune','bengaluru','bangalore','delhi','mumbai','surat',
    'goa','gurgaon','gurugram','noida','hyderabad','chennai',
    'kolkata','ahmedabad','puna','dilli',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isLocal => _tabController.index == 0;

  bool _matchTab(Map<String, dynamic> d) {
    if (d.containsKey('isLocal')) {
      return _isLocal ? d['isLocal'] == true : d['isLocal'] == false;
    }
    final loc = (d['location'] ?? d['city'] ?? d['district'] ?? '')
        .toString().toLowerCase();
    final isBahar = _baharCities.any((c) => loc.contains(c));
    return _isLocal ? !isBahar : isBahar;
  }

  bool _matchCat(Map<String, dynamic> d) {
    if (_selectedCategory == 'सभी') return true;
    final cat = (d['category'] ?? d['type'] ?? d['jobType'] ?? '')
        .toString().toLowerCase();
    final f = _selectedCategory.toLowerCase();
    if (cat.contains(f)) return true;
    const m = <String, List<String>>{
      'ड्राइवर': ['driver','cab','truck','driving'],
      'निर्माण': ['construction','building','civil','mason','bar bending'],
      'सिक्योरिटी': ['security','guard','watchman'],
      'दुकान': ['shop','retail','sales','dukan'],
      'इलेक्ट्रीशियन': ['electric','electrician','wiring'],
      'फैक्ट्री': ['factory','manufacturing','production','operator','packing'],
      'डिलीवरी': ['delivery','courier','logistics'],
      'होटल': ['hotel','cook','chef','waiter','restaurant','kitchen','hospitality'],
    };
    return (m[_selectedCategory] ?? []).any((k) => cat.contains(k));
  }

  List<String> _perks(Map<String, dynamic> d) {
    if (d['perks'] is List) return (d['perks'] as List).map((e) => e.toString()).toList();
    final p = <String>[];
    if (d['accommodation'] == true) p.add('🏠 रहना मुफ्त');
    if (d['food'] == true) p.add('🍽️ खाना मुफ्त');
    if (d['trainTicket'] == true || d['train'] == true) p.add('🚆 ट्रेन टिकट');
    return p;
  }

  String _emoji(Map<String, dynamic> d) {
    final c = (d['category'] ?? d['type'] ?? d['jobType'] ?? '').toString().toLowerCase();
    if (c.contains('driver') || c.contains('ड्राइवर') || c.contains('cab')) return '🚗';
    if (c.contains('security') || c.contains('guard')) return '🛡️';
    if (c.contains('electric') || c.contains('इलेक्ट्रीशियन')) return '⚡';
    if (c.contains('factory') || c.contains('फैक्ट्री') || c.contains('packing')) return '🏭';
    if (c.contains('delivery') || c.contains('डिलीवरी')) return '🛵';
    if (c.contains('hotel') || c.contains('cook') || c.contains('kitchen')) return '🍽️';
    if (c.contains('construction') || c.contains('निर्माण') || c.contains('mason')) return '🏗️';
    if (c.contains('shop') || c.contains('दुकान') || c.contains('sales')) return '🏪';
    return '💼';
  }

  Future<void> _wa(Map<String, dynamic> d) async {
    final raw = (d['phone'] ?? d['contactPhone'] ?? d['whatsapp'] ?? '').toString();
    final ph = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (ph.isEmpty) return;
    final title = (d['title'] ?? 'नौकरी').toString();
    final msg = Uri.encodeComponent(
        'नमस्ते, मुझे $title के बारे में जानकारी चाहिए। काम धंधा ऐप से।');
    final url = Uri.parse('https://wa.me/91$ph?text=$msg');
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(Map<String, dynamic> d) async {
    final raw = (d['phone'] ?? d['contactPhone'] ?? '').toString();
    final ph = raw.replaceAll(RegExp(r'[^0-9]'), '');
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
            const Text('💼 नौकरियाँ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('लोकल और बाहर — दोनों मिलेंगी',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🏠', style: TextStyle(fontSize: 15)),
                SizedBox(width: 6),
                Text('लोकल जॉब'),
              ])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('✈️', style: TextStyle(fontSize: 15)),
                SizedBox(width: 6),
                Text('बाहर की जॉब'),
              ])),
            ],
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
                  final sel = _selectedCategory == _cats[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = _cats[i]),
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
                        '${_catEmoji[_cats[i]] ?? ''} ${_cats[i]}',
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
          // Jobs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _kBlue));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _empty('कोई नौकरी नहीं मिली', 'नई नौकरियाँ जल्द आएंगी');
                }
                final docs = snap.data!.docs
                    .where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return _matchTab(d) && _matchCat(d);
                    })
                    .toList();
                if (docs.isEmpty) {
                  return _empty(
                    '${_isLocal ? "लोकल" : "बाहर की"} नौकरी नहीं मिली',
                    'दूसरी category चुनें',
                  );
                }
                return RefreshIndicator(
                  color: _kBlue,
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) => _card(docs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final perks = _perks(d);
    final salary = (d['salary'] ?? d['salaryRange'] ?? '').toString();
    final loc = (d['location'] ?? d['city'] ?? d['district'] ?? '').toString();
    final vac = (d['vacancies'] ?? d['posts'] ?? d['seats'] ?? '').toString();
    final isUrgent = d['urgent'] == true || d['isUrgent'] == true;
    final rawCat = (d['category'] ?? d['type'] ?? d['jobType'] ?? '').toString();
    final company = (d['company'] ?? d['employer'] ?? '').toString();
    final em = _emoji(d);
    final hasContact =
        (d['phone'] ?? d['contactPhone'] ?? d['whatsapp'] ?? '').toString().isNotEmpty;
    // Strip emojis for badge text
    final catText = rawCat.replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\s]*', unicode: true), '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job emoji icon
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(em, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (isUrgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                            child: const Text('🚨 Urgent', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isLocal ? Colors.blue.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _isLocal ? '🏠 लोकल' : '✈️ बाहर',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold,
                              color: _isLocal ? _kBlue : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Text(
                        (d['title'] ?? 'नौकरी').toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(company, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ),
                if (catText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catText.length > 8 ? '${catText.substring(0, 8)}…' : catText,
                      style: const TextStyle(fontSize: 10, color: _kBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Info badges
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Wrap(
              spacing: 8, runSpacing: 6,
              children: [
                if (salary.isNotEmpty) _badge('💰 $salary', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                if (loc.isNotEmpty) _badge('📍 $loc', const Color(0xFFE3F2FD), _kBlue),
                if (vac.isNotEmpty) _badge('👥 $vac पद खाली', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
              ],
            ),
          ),
          if (perks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Wrap(
                spacing: 6, runSpacing: 5,
                children: perks.map((p) => _badge(p, const Color(0xFFE8F5E9), const Color(0xFF2E7D32))).toList(),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasContact ? () => _call(d) : null,
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call करें', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: const BorderSide(color: _kBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasContact ? () => _wa(d) : null,
                  icon: const Text('💬', style: TextStyle(fontSize: 15)),
                  label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
  );

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
