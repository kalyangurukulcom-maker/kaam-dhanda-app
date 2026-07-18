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

  static const List<String> _cats = [
    'सभी', 'निर्माण', 'ड्राइवर', 'सिक्योरिटी',
    'दुकान', 'इलेक्ट्रीशियन', 'फैक्ट्री', 'डिलीवरी', 'होटल', 'अन्य',
  ];

  static const Map<String, String> _emoji = {
    'सभी': '📂', 'निर्माण': '🏗️', 'ड्राइवर': '🚗',
    'सिक्योरिटी': '🛡️', 'दुकान': '🏪', 'इलेक्ट्रीशियन': '⚡',
    'फैक्ट्री': '🏭', 'डिलीवरी': '🛵', 'होटल': '🍽️', 'अन्य': '✨',
  };

  static const List<String> _baharCities = [
    'pune', 'bengaluru', 'bangalore', 'delhi', 'mumbai', 'surat',
    'goa', 'gurgaon', 'gurugram', 'noida', 'hyderabad', 'chennai',
    'kolkata', 'ahmedabad',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) setState(() {});
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
    final raw = (d['jobType'] ?? d['category'] ?? d['type'] ?? '')
        .toString().toLowerCase();
    if (raw.contains(_selectedCategory.toLowerCase())) return true;
    const Map<String, List<String>> kw = {
      'ड्राइवर': ['driver', 'cab', 'truck', 'driving'],
      'निर्माण': ['construction', 'building', 'civil', 'mason'],
      'सिक्योरिटी': ['security', 'guard', 'watchman'],
      'दुकान': ['shop', 'retail', 'sales'],
      'इलेक्ट्रीशियन': ['electric', 'electrician', 'wiring'],
      'फैक्ट्री': ['factory', 'manufacturing', 'production', 'packing'],
      'डिलीवरी': ['delivery', 'courier', 'logistics'],
      'होटल': ['hotel', 'cook', 'chef', 'waiter', 'kitchen'],
    };
    return (kw[_selectedCategory] ?? []).any((k) => raw.contains(k));
  }

  Future<void> _openWhatsApp(String rawPhone, String jobTitle) async {
    final ph = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (ph.isEmpty) return;
    final num = (ph.startsWith('91') && ph.length > 10) ? ph : '91' + ph;
    final msg = Uri.encodeComponent(
        'नमस्ते, मुझे ' + jobTitle + ' की नौकरी में रुचि है। काम धंधा ऐप से।');
    final uri = Uri.parse('https://wa.me/' + num + '?text=' + msg);
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
        foregroundColor: Colors.white,
        title: const Text('💼 नौकरी ढूंढें',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '🏠 लोकल जॉब'),
            Tab(text: '✈️ बाहर की जॉब'),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _cats.length,
              itemBuilder: (ctx, i) {
                final cat = _cats[i];
                final active = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF1565C0) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? const Color(0xFF1565C0) : Colors.grey.shade300,
                      ),
                      boxShadow: active ? [BoxShadow(
                        color: const Color(0xFF1565C0).withOpacity(0.3),
                        blurRadius: 6, offset: const Offset(0, 2),
                      )] : [],
                    ),
                    child: Text(
                      (_emoji[cat] ?? '') + ' ' + cat,
                      style: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.white : Colors.black87,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
                }
                if (snap.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error, color: Colors.red, size: 40),
                      const SizedBox(height: 8),
                      Text(snap.error.toString(), textAlign: TextAlign.center),
                    ]),
                  ));
                }
                final allDocs = snap.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _matchTab(d) && _matchCat(d);
                }).toList();
                if (docs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        allDocs.isEmpty ? 'अभी कोई नौकरी उपलब्ध नहीं है' : 'इस category में नौकरी नहीं मिली',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return _buildJobCard(d);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> d) {
    final title = (d['title'] ?? d['jobTitle'] ?? 'नौकरी').toString();
    final company = (d['company'] ?? d['employerName'] ?? '').toString();
    final location = (d['location'] ?? d['district'] ?? d['city'] ?? '').toString();
    final salary = (d['salary'] ?? d['salaryRange'] ?? '').toString();
    final jobType = (d['jobType'] ?? d['category'] ?? d['type'] ?? '').toString();
    final rawPhone = (d['whatsapp'] ?? d['phone'] ?? d['contact'] ?? '').toString();
    final List<String> perks = [];
    final perksStr = (d['perks'] ?? '').toString();
    if (d['accommodation'] == true || perksStr.contains('accommodation')) perks.add('🏠 रहना');
    if (d['food'] == true || perksStr.contains('food')) perks.add('🍱 खाना');
    if (d['trainTicket'] == true || perksStr.contains('train')) perks.add('🚂 टिकट');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work, color: Color(0xFF1565C0), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (company.isNotEmpty) Text(company, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ])),
            if (jobType.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(jobType.length > 12 ? jobType.substring(0, 12) : jobType, style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0))),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (location.isNotEmpty) ...[
              const Icon(Icons.location_on, size: 13, color: Colors.grey),
              const SizedBox(width: 3),
              Flexible(child: Text(location, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
              const SizedBox(width: 12),
            ],
            if (salary.isNotEmpty) ...[
              const Icon(Icons.currency_rupee, size: 13, color: Colors.green),
              Flexible(child: Text(salary, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600))),
            ],
          ]),
          if (perks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: perks.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade200)),
              child: Text(p, style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
            )).toList()),
          ],
          const SizedBox(height: 12),
          if (rawPhone.isNotEmpty)
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _openWhatsApp(rawPhone, title),
              icon: const Text('💬', style: TextStyle(fontSize: 16)),
              label: const Text('WhatsApp पर संपर्क करें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('📞 संपर्क जानकारी उपलब्ध नहीं', style: TextStyle(fontSize: 12, color: Colors.grey))),
            ),
        ]),
      ),
    );
  }
}