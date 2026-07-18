import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class JobsScreen extends StatefulWidget {
  final Map<String, dynamic>? userArgs;
  const JobsScreen({super.key, this.userArgs});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'सभी';
  final _search = TextEditingController();
  String _searchText = '';
  static const _blue = Color(0xFF1565C0);
  static const _orange = Color(0xFFE65100);

  // Website ke categories se match karte hain
  static const _cats = ['सभी','निर्माण','ड्राइवर','सिक्योरिटी','दुकान','इलेक्ट्रीशियन','फैक्ट्री','डिलीवरी','होटल','अन्य'];

  // Bahar cities list (website se sync)
  static const _baharCities = ['pune','puna','bengaluru','bangalore','delhi','mumbai','surat','goa','gurgaon','gurugram','noida','hyderabad','chennai','kolkata','ahmedabad'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  bool get _isLocal => _tabController.index == 0;

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('jobs')
      .orderBy('postedAt', descending: true)
      .snapshots();

  bool _isUrgent(Map d) {
    if (d['urgent'] == true || d['isUrgent'] == true) return true;
    if (d['postedAt'] == null) return false;
    try {
      final dt = (d['postedAt'] as Timestamp).toDate();
      return DateTime.now().difference(dt).inHours < 24;
    } catch (_) { return false; }
  }

  bool _matchesTab(Map d) {
    // isLocal field hai toh use karo (website post karte waqt set karta hai)
    if (d.containsKey('isLocal')) {
      return _isLocal ? d['isLocal'] == true : d['isLocal'] == false;
    }
    // Fallback: location se detect karo
    final loc = (d['location'] ?? d['city'] ?? d['district'] ?? '').toString().toLowerCase();
    final isBaharLoc = _baharCities.any((c) => loc.contains(c));
    return _isLocal ? !isBaharLoc : isBaharLoc;
  }

  bool _matchCategory(String cat, String filter) {
    if (filter == 'सभी') return true;
    final c = cat.toLowerCase();
    final f = filter.toLowerCase();
    if (c.contains(f)) return true;
    const engMap = {
      'निर्माण': ['construction','nirman','mason','carpenter','painter','rod','tiles','bar bending','building'],
      'ड्राइवर': ['driver','cab','truck','ड्राइवर'],
      'सिक्योरिटी': ['security','guard','watchman','सिक्योरिटी','chowkidar'],
      'दुकान': ['shop','retail','store','दुकान','sales','counter'],
      'इलेक्ट्रीशियन': ['electrician','electric','plumber','ac','mechanic','welder','mobile repair'],
      'फैक्ट्री': ['factory','manufacturing','packing','helper','फैक्ट्री','warehouse'],
      'डिलीवरी': ['delivery','courier','डिलीवरी','logistics'],
      'होटल': ['hotel','cook','kitchen','restaurant','होटल','chef','waiter'],
      'अन्य': ['other','अन्य'],
    };
    final keys = engMap[filter] ?? [];
    return keys.any((k) => c.contains(k));
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      if (!_matchesTab(data)) return false;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final loc = (data['location'] ?? data['city'] ?? data['district'] ?? '').toString().toLowerCase();
      final cat = (data['category'] ?? '').toString();
      final company = (data['company'] ?? data['employer'] ?? data['postedBy'] ?? '').toString().toLowerCase();
      if (_searchText.isNotEmpty && !title.contains(_searchText) && !loc.contains(_searchText) && !cat.toLowerCase().contains(_searchText) && !company.contains(_searchText)) return false;
      if (!_matchCategory(cat, _filter)) return false;
      return true;
    }).toList();
  }

  void _applyWhatsApp(Map d) async {
    final phone = (d['phone'] ?? d['contactPhone'] ?? '').toString();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact number nahi hai')));
      return;
    }
    final title = d['title'] ?? 'Job';
    final msg = Uri.encodeComponent('Namaste! Aapke "$title" job ke liye apply karna chahta hoon. KaamDhanda.in se dekha.');
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/91$cleanPhone?text=$msg';
    if (await canLaunchUrl(Uri.parse(url))) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
      if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
      if (diff.inDays < 7) return '${diff.inDays} din pehle';
      return '${(diff.inDays / 7).floor()} hafte pehle';
    } catch (_) { return ''; }
  }

  List<String> _getPerks(Map d) {
    final perks = <String>[];
    // Agar perks array hai (jobs.html se save hota hai)
    if (d['perks'] is List) {
      perks.addAll((d['perks'] as List).map((e) => e.toString()));
    } else {
      // Individual boolean fields
      if (d['accommodation'] == true || d['rhana'] == true || d['stay'] == true) perks.add('🏠 रहना मुफ्त');
      if (d['food'] == true || d['khana'] == true || d['meals'] == true) perks.add('🍽️ खाना मुफ्त');
      if (d['trainTicket'] == true || d['train'] == true) perks.add('🚆 ट्रेन टिकट');
      if (d['bike'] == true || d['vehicle'] == true) perks.add('🛵 बाइक मिलेगी');
      if (d['insurance'] == true) perks.add('✅ Insurance');
      if (d['ot'] == true || d['overtime'] == true) perks.add('💰 OT अलग');
    }
    return perks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(children: [
        // Header
        Container(
          color: _blue,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(children: [
                  const Text('नौकरी ढूंढें', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.work_outline, color: Colors.white70),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Job title, company ya city...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchText.isNotEmpty ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () { _search.clear(); setState(() => _searchText = ''); }) : null,
                    filled: true, fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
                ),
              ),
              // Local / Bahar tabs — website jaisa
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('🏠', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text('लोकल जॉब', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('✈️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text('बाहर की जॉब', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ])),
                ],
              ),
            ]),
          ),
        ),
        // Category chips
        Container(
          color: Colors.white, height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _cats.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_cats[i], style: TextStyle(
                  fontSize: 12,
                  color: _filter == _cats[i] ? Colors.white : Colors.black87,
                  fontWeight: _filter == _cats[i] ? FontWeight.bold : FontWeight.normal,
                )),
                selected: _filter == _cats[i],
                onSelected: (_) => setState(() => _filter = _cats[i]),
                selectedColor: _blue, backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _blue));
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = _filterDocs(snap.data?.docs ?? []);
              if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Koi job nahi mili', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                const SizedBox(height: 4),
                Text(_isLocal ? 'Local area mein koi job nahi' : 'Bahar ki koi job nahi', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                if (_searchText.isNotEmpty || _filter != 'सभी') TextButton(
                  onPressed: () { _search.clear(); setState(() { _searchText = ''; _filter = 'सभी'; }); },
                  child: const Text('Filter reset karo')),
              ]));
              return ListView.builder(
                padding: const EdgeInsets.all(12), itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final urgent = _isUrgent(d);
                  final salary = (d['salary'] ?? d['salaryRange'] ?? '').toString();
                  final loc = (d['location'] ?? d['city'] ?? d['district'] ?? '').toString();
                  final type = (d['type'] ?? d['jobType'] ?? '').toString();
                  final company = (d['company'] ?? d['employer'] ?? d['postedBy'] ?? '').toString();
                  final cat = (d['category'] ?? '').toString();
                  final vacancies = (d['vacancies'] ?? d['posts'] ?? d['seats'] ?? '').toString();
                  final perks = _getPerks(d);
                  final accentColor = _isLocal ? _blue : _orange;

                  return Card(
                    elevation: 2, margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: urgent ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                    ),
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            if (urgent) Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text('🚨 URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(child: Text(d['title']?.toString() ?? 'Job',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          ]),
                          if (company.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(company, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ])),
                        if (cat.isNotEmpty) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(cat, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 12, runSpacing: 4, children: [
                        if (loc.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(loc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ]),
                        if (salary.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.currency_rupee, size: 14, color: Colors.green[700]),
                          Text(salary, style: TextStyle(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('/माह', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ]),
                        if (vacancies.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.people, size: 14, color: Colors.blue[600]),
                          const SizedBox(width: 3),
                          Text('$vacancies पद खाली', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                        ]),
                        if (type.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(type, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ]),
                      ]),
                      // Perks — website jaisa green chips
                      if (perks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 4, children: perks.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p, style: TextStyle(color: Colors.green[800], fontSize: 11)),
                        )).toList()),
                      ],
                      const SizedBox(height: 4),
                      Text(_timeAgo(d['postedAt']), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('WhatsApp से Apply करें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: () => _applyWhatsApp(d),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ])),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
