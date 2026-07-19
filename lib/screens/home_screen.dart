import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'jobs_screen.dart';
import 'worker_marketplace_screen.dart';
import 'employer_job_management_screen.dart';
import 'gurkul_screen.dart';
import 'field_staff_screen.dart';

const Color _kOrange = Color(0xFFF57C00);
const Color _kBlue   = Color(0xFF1565C0);
const Color _kBg     = Color(0xFFF5F7FA);

final _demoLocalJobs = <Map<String, dynamic>>[
  {'jobType': 'इलेक्ट्रीशियन', 'company': 'रांची कंस्ट्रक्शन', 'district': 'रांची', 'salary': '₹18,000/माह', 'emoji': '⚡'},
  {'jobType': 'सिक्योरिटी गार्ड', 'company': 'G4S Security', 'district': 'जमशेदपुर', 'salary': '₹14,500/माह', 'emoji': '🛡️'},
  {'jobType': 'ड्राइवर', 'company': 'Ola Cabs', 'district': 'धनबाद', 'salary': '₹22,000/माह', 'emoji': '🚗'},
];
final _demoBaharJobs = <Map<String, dynamic>>[
  {'jobType': 'फैक्ट्री वर्कर', 'company': 'Tata Motors', 'district': 'पुणे', 'salary': '₹22,000/माह + रहना', 'emoji': '🏭'},
  {'jobType': 'डिलीवरी पार्टनर', 'company': 'Zepto', 'district': 'बेंगलुरु', 'salary': '₹28,000/माह', 'emoji': '🛵'},
  {'jobType': 'वेयरहाउस हेल्पर', 'company': 'Amazon', 'district': 'दिल्ली NCR', 'salary': '₹20,000/माह + OT', 'emoji': '📦'},
];

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const HomeScreen({super.key, this.args});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        const _HomeTab(),
        JobsScreen(),
        const WorkerMarketplaceScreen(),
        const _ProfileTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: _kOrange.withOpacity(0.15),
        onDestinationSelected: (i) { HapticFeedback.selectionClick(); setState(() => _tab = i); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'होम'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'जॉब्स'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'कारीगर'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}
class _HomeTabState extends State<_HomeTab> {
  String _cat = 'सभी';
  static const _cats = ['सभी','🔨 मजदूर','🚗 ड्राइवर','🛡️ सिक्योरिटी','⚡ इलेक्ट्रीशियन','🏭 फैक्ट्री','🛵 डिलीवरी','🍽️ होटल','🏗️ निर्माण','📦 वेयरहाउस'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5, titleSpacing: 16,
        title: const Row(children: [
          Text('💼', style: TextStyle(fontSize: 22)),
          SizedBox(width: 6),
          Text('काम धंधा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: _kBlue)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _HeroBanner(
            onJobSearch: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobsScreen())),
            onRegister:  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen())),
          ),
          const _StatsRow(),
          const Padding(padding: EdgeInsets.fromLTRB(16,20,16,0), child: Text('क्या ढूंढ रहे हो?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          _QuickActions(
            onLocalJob: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobsScreen())),
            onBaharJob: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobsScreen())),
            onWorkers:  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen())),
            onEmployer: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployerJobManagementScreen())),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16,20,16,8), child: Text('Category चुनें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          _CategoryChips(categories: _cats, selected: _cat, onSelect: (c) => setState(() => _cat = c)),
          _SectionHeader(title: '🏠 लोकल नौकरियाँ', subtitle: 'अपने इलाके में काम',
            onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobsScreen()))),
          const _JobsList(isLocal: true),
          _SectionHeader(title: '✈️ बाहर की नौकरियाँ', subtitle: 'पुणे • दिल्ली • मुंबई • बेंगलुरु',
            onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobsScreen()))),
          const _JobsList(isLocal: false),
          const Padding(padding: EdgeInsets.fromLTRB(16,24,16,12), child: Text('📍 इन शहरों में काम मिलता है', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          const _CityGuide(),
          _EmployerCta(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployerJobManagementScreen()))),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onJobSearch, onRegister;
  const _HeroBanner({required this.onJobSearch, required this.onRegister});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.35), blurRadius: 14, offset: const Offset(0,5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⭐ झारखंड का नंबर 1 जॉब प्लेटफॉर्म', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        const Text('लोकल और बाहर\nदोनों की नौकरी\nएक जगह मिलेगी!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 6),
        const Text('कोई दलाली नहीं — बिल्कुल मुफ़्त', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 18),
        Row(children: [
          _HeroBtn(label: '🔍 जॉब ढूंढें', bgColor: _kOrange, onTap: onJobSearch),
          const SizedBox(width: 10),
          _HeroBtn(label: '👷 Register करें', bgColor: Colors.white24, textColor: Colors.white, onTap: onRegister),
        ]),
      ]),
    );
  }
}
class _HeroBtn extends StatelessWidget {
  final String label; final Color bgColor, textColor; final VoidCallback onTap;
  const _HeroBtn({required this.label, required this.bgColor, required this.onTap, this.textColor = Colors.white});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _StatItem(value: '15,000+', label: 'नौकरियाँ'),
      Container(width: 1, height: 40, color: Colors.grey.shade200),
      _StatItem(value: '500+', label: 'कंपनियाँ'),
      Container(width: 1, height: 40, color: Colors.grey.shade200),
      _StatItem(value: 'ZERO', label: 'दलाली'),
    ]),
  );
}
class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kBlue)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
  ]);
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onLocalJob, onBaharJob, onWorkers, onEmployer;
  const _QuickActions({required this.onLocalJob, required this.onBaharJob, required this.onWorkers, required this.onEmployer});
  @override
  Widget build(BuildContext context) {
    final items = [
      ('🏠', 'लोकल जॉब', 'अपने इलाके में', _kBlue, onLocalJob),
      ('✈️', 'बाहर की जॉब', 'पुणे, दिल्ली, मुंबई', _kOrange, onBaharJob),
      ('👷', 'कारीगर ढूंढें', 'Worker Marketplace', const Color(0xFF2E7D32), onWorkers),
      ('📢', 'जॉब पोस्ट करें', 'Employer — Free', const Color(0xFF6A1B9A), onEmployer),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16,14,16,0),
      child: GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.0,
        children: items.map((a) => GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); a.$5(); },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: a.$4.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: a.$4.withOpacity(0.2))),
            child: Row(children: [
              Text(a.$1, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(a.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: a.$4), maxLines: 1),
                Text(a.$3, style: TextStyle(fontSize: 10, color: a.$4.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories; final String selected; final ValueChanged<String> onSelect;
  const _CategoryChips({required this.categories, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final cat = categories[i]; final isSel = cat == selected;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? _kOrange : Colors.white, borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isSel ? _kOrange : Colors.grey.shade300),
              boxShadow: isSel ? [BoxShadow(color: _kOrange.withOpacity(0.3), blurRadius: 6)] : [],
            ),
            child: Text(cat, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          ),
        );
      },
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle; final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.subtitle, required this.onSeeAll});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16,24,8,10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ])),
      TextButton(onPressed: onSeeAll, child: const Text('सभी →', style: TextStyle(color: _kOrange, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _JobsList extends StatelessWidget {
  final bool isLocal;
  const _JobsList({required this.isLocal});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').where('isLocal', isEqualTo: isLocal).limit(5).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kOrange)));
        }
        final docs = snap.data?.docs ?? [];
        final List<Map<String,dynamic>> items = docs.isEmpty ? (isLocal ? _demoLocalJobs : _demoBaharJobs) : docs.map((d) => d.data() as Map<String,dynamic>).toList();
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: items.length,
          itemBuilder: (_, i) => _JobCard(data: items[i]),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String,dynamic> data;
  const _JobCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final jobType = (data['jobType'] ?? data['category'] ?? 'Job') as String;
    final company  = (data['company'] ?? data['employerName'] ?? 'Company') as String;
    final district = (data['district'] ?? data['city'] ?? 'Location') as String;
    final salary   = (data['salary'] ?? '') as String;
    final emoji    = (data['emoji'] ?? '💼') as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0,2))]),
      child: Row(children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(color: _kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(jobType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(company, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 12, color: Colors.black38),
            const SizedBox(width: 2),
            Flexible(child: Text(district, style: const TextStyle(fontSize: 11, color: Colors.black45), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (salary.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(child: Text(salary, style: const TextStyle(fontSize: 11, color: _kBlue, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ]),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Apply kiya!'), backgroundColor: Colors.green, duration: const Duration(seconds: 2))); },
          style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 12)),
          child: const Text('Apply'),
        ),
      ]),
    );
  }
}

class _CityGuide extends StatelessWidget {
  const _CityGuide();
  static const _cities = [
    ['🏙️','पुणे','₹18K-28K','2,100+ jobs'],
    ['🌆','बेंगलुरु','₹22K-35K','1,800+ jobs'],
    ['🏛️','दिल्ली NCR','₹15K-25K','3,200+ jobs'],
    ['🌃','मुंबई','₹16K-30K','950+ jobs'],
    ['🏭','सूरत','₹14K-22K','1,200+ jobs'],
  ];
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 130,
    child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _cities.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final c = _cities[i];
        return Container(width: 130, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(c[0], style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(c[1], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(c[2], style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
            Text(c[3], style: const TextStyle(color: Colors.black45, fontSize: 11)),
          ]),
        );
      },
    ),
  );
}

class _EmployerCta extends StatelessWidget {
  final VoidCallback onTap;
  const _EmployerCta({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16,24,16,0), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🏢 Employer हो?', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('मजदूर / कर्मचारी ढूंढ रहे हो?\nFREE में जॉब पोस्ट करो!', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: const Text('📢 जॉब पोस्ट करें ->', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ])),
        const Text('👷', style: TextStyle(fontSize: 52)),
      ]),
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0.5, title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kBlue, Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            CircleAvatar(radius: 32, backgroundColor: Colors.white.withOpacity(0.2),
              child: const Text('K', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(width: 16),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('काम धंधा User', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('झारखंड, भारत', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('कोई दलाली नहीं — बिल्कुल मुफ़्त', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        _MenuItem(icon: '💼', label: 'जॉब्स देखें',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobsScreen()))),
        _MenuItem(icon: '👷', label: 'Worker Marketplace',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen()))),
        _MenuItem(icon: '📢', label: 'Job Post करें (Employer)',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployerJobManagementScreen()))),
        _MenuItem(icon: '🎓', label: 'Gurkul Sathi',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GurkulScreen()))),
        _MenuItem(icon: '🏢', label: 'Field Staff Login',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldStaffScreen()))),
        _MenuItem(icon: '💬', label: 'WhatsApp: 7004856587',
          onTap: () async { final u = Uri.parse('https://wa.me/917004856587'); if (await canLaunchUrl(u)) launchUrl(u); }),
        _MenuItem(icon: '🌐', label: 'Website: kamdhanda.in',
          onTap: () async { final u = Uri.parse('https://kamdhanda.in'); if (await canLaunchUrl(u)) launchUrl(u); }),
        const SizedBox(height: 20),
        const Center(child: Text('💼 काम धंधा\nझारखंड का नंबर 1 जॉब पोर्टल\nकोई दलाली नहीं — हमेशा मुफ़्त', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black38))),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon, label; final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]),
    child: ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
    ),
  );
}
