import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import 'worker_marketplace_screen.dart';
import 'jobs_screen.dart';
import 'nearby_workers_screen.dart';
import 'testimonials_screen.dart';
import 'grameen_sathi_screen.dart';
import 'job_alert_subscription.dart';
import 'employer_job_management_screen.dart';
import 'daily_checkin_screen.dart';
import 'monthly_target_screen.dart';
import 'candidate_status_screen.dart';
import 'worker_cv_screen.dart';
import 'worker_profile_screen.dart';

// Widgets
import '../widgets/live_stats_widget.dart';
import '../widgets/quick_cta_bar.dart';
import '../widgets/worker_availability_widget.dart';
import '../widgets/available_today_filter.dart';

// ============================================================
// User profile — Firebase Auth se real data
// ============================================================
class _UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String skill;
  final String city;

  const _UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    this.skill = '',
    this.city = '',
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'U';
}

// ============================================================
// HomeScreen — Firebase Auth se real user data load karo
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  _UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _profile = const _UserProfile(
            uid: 'guest',
            name: 'Guest User',
            phone: '',
          );
          _loading = false;
        });
      }
      return;
    }

    final uid = user.uid;
    final phone = (user.phoneNumber ?? '').replaceFirst('+91', '');

    // Try workers collection first
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workers')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        if (mounted) {
          setState(() {
            _profile = _UserProfile(
              uid: uid,
              name: d['name'] ?? phone,
              phone: d['phone'] ?? phone,
              skill: d['skill'] ?? d['category'] ?? '',
              city: d['city'] ?? d['district'] ?? '',
            );
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Try field_staff_registrations
    try {
      final snap = await FirebaseFirestore.instance
          .collection('field_staff_registrations')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        if (mounted) {
          setState(() {
            _profile = _UserProfile(
              uid: uid,
              name: d['name'] ?? phone,
              phone: d['phone'] ?? phone,
              skill: d['skill'] ?? 'Field Staff',
              city: d['district'] ?? '',
            );
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Try gurkul_applications
    try {
      final snap = await FirebaseFirestore.instance
          .collection('gurkul_applications')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        if (mounted) {
          setState(() {
            _profile = _UserProfile(
              uid: uid,
              name: d['name'] ?? phone,
              phone: d['phone'] ?? phone,
              skill: 'Gurkul Sathi',
              city: d['address'] ?? '',
            );
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Logged in but no Firestore profile — use phone as name
    if (mounted) {
      setState(() {
        _profile = _UserProfile(
          uid: uid,
          name: phone.isNotEmpty ? '+91 $phone' : 'User',
          phone: phone,
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _profile!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomePage(profile: profile),
          const _WorkerPage(),
          const _JobsPage(),
          _StaffPage(profile: profile),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Workers'),
          NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Jobs'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'My Profile'),
        ],
      ),
    );
  }
}

// ============================================================
// Home Tab
// ============================================================
class _HomePage extends StatelessWidget {
  final _UserProfile profile;
  const _HomePage({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🌾', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Kaam Dhanda',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobAlertSubscriptionScreen(
                  workerId: profile.uid,
                  workerName: profile.name,
                  workerPhone: profile.phone,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Availability card
            AvailabilityToggleCard(
              workerId: profile.uid,
              workerName: profile.name,
            ),
            const SizedBox(height: 16),

            // Live Stats
            const LiveStatsWidget(),
            const SizedBox(height: 20),

            // Available Today strip
            AvailableTodaySection(
              onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WorkerMarketplaceScreen())),
              onHire: (id, data) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => WorkerProfileScreen(workerId: id))),
            ),

            // Quick Actions Grid
            const SizedBox(height: 16),
            const Text('Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _QuickActionsGrid(profile: profile),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: QuickCtaBar(
        onWorkerRegister: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => WorkerCvScreen(workerId: profile.uid))),
        onJobSearch: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const JobsScreen())),
        onHireWorker: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen())),
      ),
    );
  }
}

// ============================================================
// Quick Actions Grid
// ============================================================
class _QuickActionsGrid extends StatelessWidget {
  final _UserProfile profile;
  const _QuickActionsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        '🏪',
        'Marketplace',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen()))
      ),
      (
        '📍',
        'Nearby',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NearbyWorkersScreen()))
      ),
      (
        '💼',
        'My Jobs',
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const JobsScreen()))
      ),
      (
        '🌾',
        'Grameen Sathi',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GrameenSathiScreen()))
      ),
      (
        '🏢',
        'Post Job',
        () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EmployerJobManagementScreen(
                    employerId: profile.uid, employerName: profile.name)))
      ),
      (
        '📄',
        'My CV',
        () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => WorkerCvScreen(workerId: profile.uid)))
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: actions.map((a) {
        final (icon, label, onTap) = a;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// Workers Tab
// ============================================================
class _WorkerPage extends StatelessWidget {
  const _WorkerPage();

  @override
  Widget build(BuildContext context) {
    return const WorkerMarketplaceScreen();
  }
}

// ============================================================
// Jobs Tab
// ============================================================
class _JobsPage extends StatelessWidget {
  const _JobsPage();

  @override
  Widget build(BuildContext context) {
    return const JobsScreen();
  }
}

// ============================================================
// My Profile Tab — real data dikhao
// ============================================================
class _StaffPage extends StatelessWidget {
  final _UserProfile profile;
  const _StaffPage({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout?'),
                  content: const Text('Kya aap logout karna chahte hain?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card — real data
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    profile.initial,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      if (profile.skill.isNotEmpty)
                        Text(
                          profile.skill,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      if (profile.phone.isNotEmpty)
                        Text(
                          '📞 +91 ${profile.phone}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      if (profile.city.isNotEmpty)
                        Text(
                          '📍 ${profile.city}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu items
          ..._buildMenuItems(context).map((item) {
            final (icon, label, onTap) = item;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ],
              ),
              child: ListTile(
                leading: Text(icon, style: const TextStyle(fontSize: 22)),
                title: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  List<(String, String, VoidCallback)> _buildMenuItems(BuildContext ctx) => [
        (
          '📄',
          'My CV / Profile Share',
          () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => WorkerCvScreen(workerId: profile.uid)))
        ),
        (
          '🔔',
          'Job Alert Settings',
          () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => JobAlertSubscriptionScreen(
                      workerId: profile.uid,
                      workerName: profile.name,
                      workerPhone: profile.phone)))
        ),
        (
          '✅',
          'Daily Check-in',
          () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const DailyCheckinScreen()))
        ),
        (
          '📊',
          'Monthly Target',
          () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const MonthlyTargetScreen()))
        ),
        (
          '👥',
          'My Candidates',
          () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const CandidateStatusScreen()))
        ),
        (
          '🌾',
          'Grameen Sathi',
          () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const GrameenSathiScreen()))
        ),
        (
          '🏢',
          'My Job Posts (Employer)',
          () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => EmployerJobManagementScreen(
                      employerId: profile.uid, employerName: profile.name)))
        ),
        (
          '🌟',
          'Testimonials',
          () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const TestimonialsScreen()))
        ),
      ];
}
