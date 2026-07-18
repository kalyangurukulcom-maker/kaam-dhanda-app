import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'worker_marketplace_screen.dart';
import 'jobs_screen.dart';
import 'nearby_workers_screen.dart';
import 'grameen_sathi_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String,dynamic>? args;
  const HomeScreen({super.key, this.args});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _phone = '', _userType = 'guest', _name = '';
  static const _blue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.args != null) {
      setState(() {
        _phone = widget.args!['phone'] ?? '';
        _userType = widget.args!['userType'] ?? 'guest';
        _name = widget.args!['name'] ?? '';
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _phone = prefs.getString('user_phone') ?? '';
        _userType = prefs.getString('user_type') ?? 'guest';
        _name = prefs.getString('user_name') ?? '';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(phone: _phone, name: _name, userType: _userType, onTabChange: (i) => setState(() => _tab = i)),
      const JobsScreen(),
      const WorkerMarketplaceScreen(),
      const NearbyWorkersScreen(),
      _ProfileTab(phone: _phone, name: _name, userType: _userType, onLogout: _logout),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: _blue.withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF1565C0)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work, color: Color(0xFF1565C0)), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: Color(0xFF1565C0)), label: 'Workers'),
          NavigationDestination(icon: Icon(Icons.near_me_outlined), selectedIcon: Icon(Icons.near_me, color: Color(0xFF1565C0)), label: 'Nearby'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF1565C0)), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String phone, name, userType;
  final ValueChanged<int> onTabChange;
  const _HomeTab({required this.phone, required this.name, required this.userType, required this.onTabChange});
  static const _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Namaste, ${name.isNotEmpty ? name : "User"}!', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_roleLabel(userType), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ])),
                ]),
                const SizedBox(height: 8),
                const Text('KaamDhanda — Rozgaar Ka Sahi Platform', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ]))),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Live Stats
          _StatsRow(),
          const SizedBox(height: 20),
          // Quick Actions
          const Text('Kya karna hai?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _QuickAction(icon: Icons.people, label: 'Mazdoor\nDhundho', color: _blue, onTap: () => onTabChange(2))),
            const SizedBox(width: 12),
            Expanded(child: _QuickAction(icon: Icons.work, label: 'Naukri\nDhundho', color: Colors.green[700]!, onTap: () => onTabChange(1))),
            const SizedBox(width: 12),
            Expanded(child: _QuickAction(icon: Icons.near_me, label: 'Paas ke\nKaarigar', color: Colors.orange[700]!, onTap: () => onTabChange(3))),
            const SizedBox(width: 12),
            Expanded(child: _QuickAction(icon: Icons.app_registration, label: 'Register\nKaro', color: Colors.purple[700]!, onTap: () => _openRegister(context))),
          ]),
          const SizedBox(height: 24),
          // Recent Jobs
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Latest Naukri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => onTabChange(1), child: const Text('Sabhi dekho →')),
          ]),
          const SizedBox(height: 8),
          _RecentJobs(),
          const SizedBox(height: 24),
          // Recent Workers
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Naye Mazdoor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => onTabChange(2), child: const Text('Sabhi dekho →')),
          ]),
          const SizedBox(height: 8),
          _RecentWorkers(),
          const SizedBox(height: 20),
          // Register CTA
          Container(width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Icon(Icons.work_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              const Text('Apna Profile Register Karo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text('Free mein register karo aur lakho employers tak pahuncho', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => _openRegister(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _blue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
                child: const Text('Free Register Karo', style: TextStyle(fontWeight: FontWeight.bold))),
            ]),
          ),
          const SizedBox(height: 16),
        ]))),
      ]),
    );
  }

  String _roleLabel(String t) {
    if (t=='field_staff') return 'Field Staff';
    if (t=='gurkul') return 'Gurkul Sathi';
    if (t=='worker') return 'Registered Worker';
    return 'Guest User';
  }

  void _openRegister(BuildContext ctx) {
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Register Karo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(leading: const Icon(Icons.construction, color: Color(0xFF1565C0)), title: const Text('Mazdoor Register Karo'),
        onTap: () { Navigator.pop(ctx); launchUrl(Uri.parse('https://kamdhanda.in/worker.html')); }),
      ListTile(leading: const Icon(Icons.school, color: Colors.green), title: const Text('Gurkul Sathi Bano'),
        onTap: () { Navigator.pop(ctx); launchUrl(Uri.parse('https://kamdhanda.in/gurkul.html')); }),
      ListTile(leading: const Icon(Icons.people, color: Colors.orange), title: const Text('Field Staff Register Karo'),
        onTap: () { Navigator.pop(ctx); launchUrl(Uri.parse('https://kamdhanda.in/field-staff.html')); }),
      const SizedBox(height: 8),
    ])));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override Widget build(BuildContext c) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0,2))]),
      child: Column(children: [
        CircleAvatar(radius: 22, backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ));
}

class _StatsRow extends StatelessWidget {
  @override Widget build(BuildContext c) => Row(children: [
    Expanded(child: _StatCard(collection: 'workers', label: 'Registered\nWorkers', icon: Icons.people, color: const Color(0xFF1565C0))),
    const SizedBox(width: 12),
    Expanded(child: _StatCard(collection: 'jobs', label: 'Active\nJobs', icon: Icons.work, color: Colors.green[700]!)),
    const SizedBox(width: 12),
    Expanded(child: _StatCard(collection: 'field_staff_registrations', label: 'Field\nStaff', icon: Icons.badge, color: Colors.orange[700]!)),
  ]);
}

class _StatCard extends StatelessWidget {
  final String collection, label; final IconData icon; final Color color;
  const _StatCard({required this.collection, required this.label, required this.icon, required this.color});
  @override Widget build(BuildContext c) => StreamBuilder<AggregateQuerySnapshot>(
    stream: FirebaseFirestore.instance.collection(collection).count().snapshots(),
    builder: (_, snap) {
      final count = snap.data?.count ?? 0;
      return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0,2))]),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text('$count+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ]));
    });
}

class _RecentJobs extends StatelessWidget {
  @override Widget build(BuildContext c) => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('jobs').orderBy('postedAt', descending: true).limit(3).snapshots(),
    builder: (_, snap) {
      if (!snap.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1565C0))));
      final docs = snap.data!.docs;
      if (docs.isEmpty) return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: const Text('Abhi koi job nahi hai. Jaldi aayegi!', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center));
      return Column(children: docs.map((d) {
        final data = d.data() as Map<String,dynamic>;
        final urgent = data['urgent'] == true;
        return Card(margin: const EdgeInsets.only(bottom: 8), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: urgent ? const BorderSide(color: Colors.red) : BorderSide.none),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: urgent ? Colors.red[50] : const Color(0xFF1565C0).withOpacity(0.1),
              child: Icon(Icons.work, color: urgent ? Colors.red : const Color(0xFF1565C0), size: 20)),
            title: Row(children: [
              if (urgent) Container(margin: const EdgeInsets.only(right: 4), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(3)),
                child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              Expanded(child: Text(data['title'] ?? 'Job', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ]),
            subtitle: Text('${data['location'] ?? ''} • ${data['salary'] ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ));
      }).toList());
    });
}

class _RecentWorkers extends StatelessWidget {
  @override Widget build(BuildContext c) => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('workers').orderBy('createdAt', descending: true).limit(4).snapshots(),
    builder: (_, snap) {
      if (!snap.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1565C0))));
      final docs = snap.data!.docs;
      if (docs.isEmpty) return const SizedBox.shrink();
      return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: docs.length, itemBuilder: (_, i) {
          final d = docs[i].data() as Map<String,dynamic>;
          final avail = d['available'] == true || d['available'] == 'true';
          return Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: const Color(0xFF1565C0),
                child: Text((d['name'] ?? 'W')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['name'] ?? 'Worker', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(d['category'] ?? d['skills'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                if (avail) const Text('Available', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
              ])),
            ])));
        });
    });
}

// ─── PROFILE TAB ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String phone, name, userType;
  final VoidCallback onLogout;
  const _ProfileTab({required this.phone, required this.name, required this.userType, required this.onLogout});
  static const _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Mera Profile', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Profile card
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Text(name.isNotEmpty ? name : 'Guest User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (phone.isNotEmpty) Text('+91 $phone', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(_roleLabel(userType), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ]),
        ),
        const SizedBox(height: 20),
        // Menu items
        _MenuItem(icon: Icons.language, title: 'Website Kholo', subtitle: 'kamdhanda.in', color: _blue,
          onTap: () => launchUrl(Uri.parse('https://kamdhanda.in'))),
        _MenuItem(icon: Icons.people, title: 'Mazdoor Dhundho', subtitle: 'Hire workers ke liye', color: Colors.blue[600]!,
          onTap: () => launchUrl(Uri.parse('https://kamdhanda.in/hire.html'))),
        _MenuItem(icon: Icons.work, title: 'Jobs Dekho', subtitle: 'Naukri dhundhne ke liye', color: Colors.green[600]!,
          onTap: () => launchUrl(Uri.parse('https://kamdhanda.in/jobs.html'))),
        _MenuItem(icon: Icons.app_registration, title: 'Worker Register Karo', subtitle: 'Free mein apna profile banao', color: Colors.orange[600]!,
          onTap: () => launchUrl(Uri.parse('https://kamdhanda.in/worker.html'))),
        if (userType == 'worker' || userType == 'guest') ...[
          _MenuItem(icon: Icons.school, title: 'Gurkul Sathi Bano', subtitle: 'Kamaai karo referral se', color: Colors.purple[600]!,
            onTap: () => launchUrl(Uri.parse('https://kamdhanda.in/gurkul.html'))),
        ],
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Logout Karo'),
          onPressed: onLogout,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }

  String _roleLabel(String t) {
    if (t=='field_staff') return 'Field Staff';
    if (t=='gurkul') return 'Gurkul Sathi';
    if (t=='worker') return 'Registered Worker';
    return 'Guest User';
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color color; final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override Widget build(BuildContext c) => Card(elevation: 1, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(leading: CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap));
}