import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jobs_screen.dart';
import 'grameen_sathi_screen.dart';
import 'nearby_workers_screen.dart';
import 'worker_marketplace_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const HomeScreen({super.key, this.args});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _phone = '';
  String _userType = 'guest';
  String _docId = '';
  String _name = '';
  Map<String, dynamic>? _profileData;
  bool _loadingProfile = true;

  @override
  void initState() { super.initState(); _initUser(); }

  Future<void> _initUser() async {
    if (widget.args != null && (widget.args!['phone'] as String? ?? '').isNotEmpty) {
      _phone = widget.args!['phone'] ?? '';
      _userType = widget.args!['userType'] ?? 'guest';
      _docId = widget.args!['docId'] ?? '';
      _name = widget.args!['name'] ?? '';
    } else {
      final prefs = await SharedPreferences.getInstance();
      _phone = prefs.getString('user_phone') ?? '';
      _userType = prefs.getString('user_type') ?? 'guest';
      _docId = prefs.getString('user_doc_id') ?? '';
      _name = prefs.getString('user_name') ?? '';
    }
    if (_docId.isNotEmpty && _userType != 'guest') {
      final col = _userType == 'field_staff' ? 'field_staff_registrations'
                : _userType == 'gurkul' ? 'gurkul_applications'
                : 'workers';
      try {
        final d = await FirebaseFirestore.instance.collection(col).doc(_docId).get();
        if (d.exists) _profileData = d.data();
      } catch (_) {}
    }
    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1565C0).withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF1565C0)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work, color: Color(0xFF1565C0)), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: Color(0xFF1565C0)), label: 'Workers'),
          NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on, color: Color(0xFF1565C0)), label: 'Nearby'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF1565C0)), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1: return const JobsScreen();
      case 2: return const WorkerMarketplaceScreen();
      case 3: return const NearbyWorkersScreen();
      case 4: return _profileTab();
      default: return _homeTab();
    }
  }

  Widget _homeTab() {
    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 150, pinned: true, backgroundColor: const Color(0xFF1565C0),
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(_name.isNotEmpty ? 'Namaste, $_name!' : 'Namaste!',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('KaamDhanda', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Rozgaar Ka Sahi Platform', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            )),
          ),
        ),
        actions: [
          if (_userType != 'guest')
            IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout)
          else
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(delegate: SliverChildListDelegate([
          if (_userType != 'guest') ...[_roleCard(), const SizedBox(height: 16)],
          const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 10), _quickActions(), const SizedBox(height: 20),
          const Text('Latest Jobs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 10), _latestJobs(), const SizedBox(height: 20),
          _statsCard(), const SizedBox(height: 24),
        ])),
      ),
    ]);
  }

  Widget _roleCard() {
    final color = _userType == 'gurkul' ? Colors.purple
        : _userType == 'field_staff' ? const Color(0xFF1565C0)
        : Colors.green;
    final label = _userType == 'gurkul' ? 'Gurkul Sathi'
        : _userType == 'field_staff' ? 'Field Staff'
        : 'Worker';
    return GestureDetector(
      onTap: () {
        if (_userType == 'gurkul') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => GrameenSathiScreen(userId: _docId)));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_name.isNotEmpty ? _name : 'My Profile',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            if (_phone.isNotEmpty)
              Text('+91 $_phone', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        ]),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      {'icon': Icons.work, 'label': 'Jobs', 'color': const Color(0xFF1565C0), 'tab': 1},
      {'icon': Icons.people, 'label': 'Workers', 'color': Colors.green, 'tab': 2},
      {'icon': Icons.location_on, 'label': 'Nearby', 'color': Colors.orange, 'tab': 3},
      {'icon': Icons.person, 'label': 'Profile', 'color': Colors.purple, 'tab': 4},
    ];
    return Row(children: actions.map((a) => Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = a['tab'] as int),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: (a['color'] as Color).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (a['color'] as Color).withOpacity(0.2)),
          ),
          child: Column(children: [
            Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
            const SizedBox(height: 6),
            Text(a['label'] as String, style: TextStyle(color: a['color'] as Color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ))).toList());
  }

  Widget _latestJobs() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs')
          .where('status', isEqualTo: 'active')
          .orderBy('postedAt', descending: true)
          .limit(3).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No jobs yet — check back soon!')),
          );
        }
        return Column(children: [
          ...docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
              ),
              child: Row(children: [
                CircleAvatar(radius: 18, backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: const Icon(Icons.work, color: Color(0xFF1565C0), size: 16)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['title'] ?? 'Job', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Rs.${d['salary'] ?? 'Negotiable'} • ${d['location'] ?? 'India'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ])),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Apply', style: TextStyle(fontSize: 11)),
                ),
              ]),
            );
          }),
          TextButton(
            onPressed: () => setState(() => _selectedIndex = 1),
            child: const Text('Sab Jobs Dekhen', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
          ),
        ]);
      },
    );
  }

  Widget _statsCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _stat('15K+', 'Jobs'), _vdiv(), _stat('8K+', 'Workers'), _vdiv(), _stat('500+', 'Companies'), _vdiv(), _stat('FREE', 'Always'),
    ]),
  );

  Widget _stat(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);

  Widget _vdiv() => Container(height: 28, width: 1, color: Colors.white30);

  Widget _profileTab() {
    if (_userType == 'guest') {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.person_outline, size: 80, color: Color(0xFF90CAF9)),
          const SizedBox(height: 16),
          const Text('Login karein profile dekhne ke liye', style: TextStyle(fontSize: 15, color: Color(0xFF1565C0))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            child: const Text('Login / Register'),
          ),
        ])),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Text(_name.isNotEmpty ? _name : 'User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (_phone.isNotEmpty) Text('+91 $_phone', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _userType == 'gurkul' ? 'Gurkul Sathi' : _userType == 'field_staff' ? 'Field Staff' : 'Worker',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (_userType == 'gurkul') ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrameenSathiScreen(userId: _docId))),
              icon: const Icon(Icons.dashboard), label: const Text('Gurkul Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_profileData != null) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('My Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              ..._profileData!.entries
                .where((e) => !['createdAt','updatedAt','fcmToken'].contains(e.key))
                .take(10)
                .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    SizedBox(width: 100, child: Text('${e.key}:', style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                    Expanded(child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                  ]),
                )),
            ]),
          ),
        ]),
      ),
    );
  }
}