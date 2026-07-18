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
  final Map<String, dynamic>? args;
  const HomeScreen({Key? key, this.args}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userPhone = '';
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.args != null) {
      setState(() {
        _userName = widget.args!['name'] ?? '';
        _userPhone = widget.args!['phone'] ?? '';
        _userType = widget.args!['type'] ?? '';
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? '';
        _userPhone = prefs.getString('user_phone') ?? '';
        _userType = prefs.getString('user_type') ?? '';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String get _roleLabel {
    switch (_userType) {
      case 'field_staff': return 'Field Staff';
      case 'gurkul': return 'Gurkul Sathi';
      case 'worker': return 'Registered Worker';
      default: return 'Guest User';
    }
  }

  void _showRegisterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Register Karo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _RegisterOption(
              icon: Icons.construction,
              title: 'Mazdoor / Karigar Register',
              subtitle: 'Kaam dhundho — apna profile banao',
              url: 'https://kamdhanda.in/worker.html',
            ),
            _RegisterOption(
              icon: Icons.school,
              title: 'Gurkul Sathi Register',
              subtitle: 'Students ko training dilao, kamaao',
              url: 'https://kamdhanda.in/gurkul.html',
            ),
            _RegisterOption(
              icon: Icons.groups,
              title: 'Field Staff Register',
              subtitle: 'Field mein kaam karo, team banao',
              url: 'https://kamdhanda.in/field-staff.html',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(
        userName: _userName,
        userPhone: _userPhone,
        roleLabel: _roleLabel,
        onTabChange: (i) => setState(() => _selectedIndex = i),
        onRegister: _showRegisterSheet,
      ),
      const JobsScreen(),
      const WorkerMarketplaceScreen(),
      const NearbyWorkersScreen(),
      _ProfileTab(
        userName: _userName,
        userPhone: _userPhone,
        roleLabel: _roleLabel,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1565C0).withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Naukri'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Mazdoor'),
          NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'Paas Mein'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _RegisterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  const _RegisterOption({required this.icon, required this.title, required this.subtitle, required this.url});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
        child: Icon(icon, color: const Color(0xFF1565C0)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userName;
  final String userPhone;
  final String roleLabel;
  final void Function(int) onTabChange;
  final VoidCallback onRegister;

  const _HomeTab({
    required this.userName,
    required this.userPhone,
    required this.roleLabel,
    required this.onTabChange,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'K';
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF2196F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userName.isNotEmpty ? 'Namaste, $userName!' : 'Namaste! Swagat hai!',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              roleLabel,
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                            ),
                            if (userPhone.isNotEmpty)
                              Text('+91 $userPhone', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          title: const Text('Kaam Dhanda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatsRow(),
                const SizedBox(height: 20),
                const Text('Kya Dhundh Rahe Hain?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _QuickAction(
                      icon: Icons.people,
                      label: 'Mazdoor Dhundho',
                      subtitle: 'Hire skilled workers',
                      color: const Color(0xFF1565C0),
                      onTap: () => onTabChange(2),
                    ),
                    _QuickAction(
                      icon: Icons.work,
                      label: 'Naukri Dhundho',
                      subtitle: 'Find jobs near you',
                      color: const Color(0xFF2E7D32),
                      onTap: () => onTabChange(1),
                    ),
                    _QuickAction(
                      icon: Icons.location_on,
                      label: 'Paas ke Karigar',
                      subtitle: 'Nearby workers',
                      color: const Color(0xFFE65100),
                      onTap: () => onTabChange(3),
                    ),
                    _QuickAction(
                      icon: Icons.app_registration,
                      label: 'Register Karo',
                      subtitle: 'Join our platform',
                      color: const Color(0xFF6A1B9A),
                      onTap: onRegister,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Tazi Naukariyan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const _RecentJobs(),
                const SizedBox(height: 24),
                const Text('Naye Mazdoor / Karigar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const _RecentWorkers(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCard(collection: 'workers', label: 'Workers', icon: Icons.construction, color: Color(0xFF1565C0))),
        SizedBox(width: 8),
        Expanded(child: _StatCard(collection: 'jobs', label: 'Jobs', icon: Icons.work, color: Color(0xFF2E7D32))),
        SizedBox(width: 8),
        Expanded(child: _StatCard(collection: 'field_staff_registrations', label: 'Field Staff', icon: Icons.groups, color: Color(0xFFE65100))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String collection;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({required this.collection, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                snapshot.connectionState == ConnectionState.waiting ? '...' : '$count',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
            ],
          ),
        );
      },
    );
  }
}

class _RecentJobs extends StatelessWidget {
  const _RecentJobs();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('postedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Abhi koi job nahi hai', style: TextStyle(color: Colors.grey))),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isUrgent = data['urgent'] == true;
            final postedAt = data['postedAt'] as Timestamp?;
            final hoursAgo = postedAt != null
                ? DateTime.now().difference(postedAt.toDate()).inHours
                : 999;
            final urgent = isUrgent || hoursAgo < 24;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (urgent)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            Expanded(
                              child: Text(
                                data['title'] ?? 'Job',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(data['location'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (data['salary'] != null)
                          Text('Rs. ${data["salary"]}', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RecentWorkers extends StatelessWidget {
  const _RecentWorkers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .orderBy('createdAt', descending: true)
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Koi worker registered nahi hai', style: TextStyle(color: Colors.grey))),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Worker';
            final initials = name.isNotEmpty ? name[0].toUpperCase() : 'W';
            final isAvailable = data['available'] == true ||
                data['available'] == 'true' ||
                data['availability'] == 'available';
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1565C0).withOpacity(0.15),
                    child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ),
                  const SizedBox(height: 6),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(data['category'] ?? data['skill'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Busy',
                      style: TextStyle(fontSize: 9, color: isAvailable ? Colors.green[700] : Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String userName;
  final String userPhone;
  final String roleLabel;
  final VoidCallback onLogout;

  const _ProfileTab({required this.userName, required this.userPhone, required this.roleLabel, required this.onLogout});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'K';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meri Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(userName.isNotEmpty ? userName : 'Mehmaan User',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(roleLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                if (userPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('+91 $userPhone', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ProfileMenuItem(icon: Icons.home, label: 'Home — kamdhanda.in', onTap: () => _launchUrl('https://kamdhanda.in')),
          _ProfileMenuItem(icon: Icons.construction, label: 'Worker Register', onTap: () => _launchUrl('https://kamdhanda.in/worker.html')),
          _ProfileMenuItem(icon: Icons.school, label: 'Gurkul Sathi Register', onTap: () => _launchUrl('https://kamdhanda.in/gurkul.html')),
          _ProfileMenuItem(icon: Icons.groups, label: 'Field Staff Register', onTap: () => _launchUrl('https://kamdhanda.in/field-staff.html')),
          _ProfileMenuItem(icon: Icons.work, label: 'Naukri Dekho', onTap: () => _launchUrl('https://kamdhanda.in/jobs.html')),
          _ProfileMenuItem(icon: Icons.people, label: 'Karigar Dekho', onTap: () => _launchUrl('https://kamdhanda.in/hire.html')),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
