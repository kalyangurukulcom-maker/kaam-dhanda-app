import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
// Demo credentials — apne real app mein Auth se replace karo
// ============================================================
const _kDemoWorkerId   = 'W001';
const _kDemoWorkerName = 'Ramesh Kumar';
const _kDemoWorkerPhone = '9876543210';
const _kDemoEmployerId  = 'E001';
const _kDemoEmployerName = 'Ravi Enterprises';
const _kDemoStaffId    = 'GS001';
const _kDemoStaffName  = 'Field Staff 1';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    _HomePage(),
    _WorkerPage(),
    _JobsPage(),
    _StaffPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people), label: 'Workers'),
          NavigationDestination(icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person), label: 'My Profile'),
        ],
      ),
    );
  }
}

// ============================================================
// Home Tab
// ============================================================
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🌾', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('Kaam Dhanda',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => JobAlertSubscriptionScreen(
                workerId: _kDemoWorkerId,
                workerName: _kDemoWorkerName,
                workerPhone: _kDemoWorkerPhone,
              ))),
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
              workerId: _kDemoWorkerId,
              workerName: _kDemoWorkerName,
            ),
            const SizedBox(height: 16),

            // Live Stats
            const LiveStatsWidget(),
            const SizedBox(height: 20),

            // Available Now strip
            AvailableTodaySection(
              onSeeAll: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AvailableNowScreen())),
              onHire: (id, data) => Navigator.push(context,
                MaterialPageRoute(builder: (_) => WorkerProfileScreen(workerId: id))),
            ),

            // Quick Actions Grid
            const SizedBox(height: 16),
            const Text('Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _QuickActionsGrid(),

            // Job Alert Banner
            const SizedBox(height: 16),
            JobAlertBannerCard(
              workerId: _kDemoWorkerId,
              workerName: _kDemoWorkerName,
              workerPhone: _kDemoWorkerPhone,
            ),
            const SizedBox(height: 16),

            // Testimonials
            const Text('Success Stories 🌟',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TestimonialsCarousel(),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: QuickCtaBar(
        onWorkerRegister: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => WorkerCvScreen(workerId: _kDemoWorkerId))),
        onJobSearch: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => JobsScreen(currentUserId: _kDemoWorkerId))),
        onHireWorker: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen())),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('🏪', 'Marketplace', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen()))),
      ('📍', 'Nearby', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NearbyWorkersScreen()))),
      ('💼', 'My Jobs', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => JobsScreen(currentUserId: _kDemoWorkerId)))),
      ('🌾', 'Grameen Sathi', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => GrameenSathiScreen(
            staffId: _kDemoStaffId, staffName: _kDemoStaffName)))),
      ('🏢', 'Post Job', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EmployerJobManagementScreen(
            employerId: _kDemoEmployerId, employerName: _kDemoEmployerName)))),
      ('📄', 'My CV', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => WorkerCvScreen(workerId: _kDemoWorkerId)))),
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
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
    return JobsScreen(currentUserId: _kDemoWorkerId);
  }
}

// ============================================================
// Staff / My Profile Tab
// ============================================================
class _StaffPage extends StatelessWidget {
  const _StaffPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Text('R', style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: Colors.white))),
                const SizedBox(width: 16),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_kDemoWorkerName, style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                    Text('Construction Worker', style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
                    Text('📍 Ranchi, Jharkhand', style: TextStyle(
                        color: Colors.white60, fontSize: 12)),
                  ],
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu items
          ..._menuItems(context).map((item) {
            final (icon, label, onTap) = item;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: ListTile(
                leading: Text(icon, style: const TextStyle(fontSize: 22)),
                title: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
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

  List<(String, String, VoidCallback Function(BuildContext))>
      _menuItems(BuildContext ctx) => [
    ('🔄', 'Availability Update',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => AvailabilityScreen(
                workerId: _kDemoWorkerId,
                workerName: _kDemoWorkerName)))),
    ('📄', 'My CV / Profile Share',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => WorkerCvScreen(workerId: _kDemoWorkerId)))),
    ('🔔', 'Job Alert Settings',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => JobAlertSubscriptionScreen(
                workerId: _kDemoWorkerId,
                workerName: _kDemoWorkerName,
                workerPhone: _kDemoWorkerPhone)))),
    ('✅', 'Daily Check-in',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => DailyCheckinScreen(
                userId: _kDemoWorkerId,
                userName: _kDemoWorkerName,
                userType: 'field_staff')))),
    ('📊', 'Monthly Target',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => MonthlyTargetScreen(
                userId: _kDemoWorkerId, userType: 'field_staff')))),
    ('👥', 'My Candidates',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => CandidateStatusScreen(staffId: _kDemoStaffId)))),
    ('🌾', 'Grameen Sathi',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => GrameenSathiScreen(
                staffId: _kDemoStaffId,
                staffName: _kDemoStaffName)))),
    ('🏢', 'My Job Posts (Employer)',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => EmployerJobManagementScreen(
                employerId: _kDemoEmployerId,
                employerName: _kDemoEmployerName)))),
    ('🌟', 'Testimonials',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => const TestimonialsScreen()))),
    ('📈', 'Platform Stats',
        (c) => () => Navigator.push(c, MaterialPageRoute(
            builder: (_) => const PlatformStatsScreen()))),
  ].map((e) => (e.$1, e.$2, e.$3(ctx))).toList();
}
