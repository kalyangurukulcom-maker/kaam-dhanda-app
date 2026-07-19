import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'jobs_screen.dart';
import 'worker_marketplace_screen.dart';
import 'nearby_workers_screen.dart';
import 'employer_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const HomeScreen({super.key, this.args});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Quick stats
  int _totalWorkers = 0;
  int _totalJobs = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final ws = await _db.collection('workers').count().get();
      final js = await _db.collection('jobs').count().get();
      if (mounted) {
        setState(() {
          _totalWorkers = ws.count ?? 0;
          _totalJobs = js.count ?? 0;
          _statsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/918779937845?text=${Uri.encodeComponent('नमस्ते, काम धंधा ऐप से बात करना चाहता हूं।')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          JobsScreen(),
          NearbyWorkersScreen(),
          WorkerMarketplaceScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'होम',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'नौकरी',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'पास में',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'कारीगर',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('नमस्ते! 🙏',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            Text('काम धंधा',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                            Text('रोजगार का सबसे आसान तरीका',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.work,
                            color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick action buttons
                  Row(
                    children: [
                      _QuickBtn(
                        icon: Icons.work,
                        label: 'नौकरी खोजें',
                        onTap: () {
                          final state = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          state?.setState(() => state._currentIndex = 1);
                        },
                      ),
                      const SizedBox(width: 12),
                      _QuickBtn(
                        icon: Icons.person_search,
                        label: 'कारीगर खोजें',
                        onTap: () {
                          final state = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          state?.setState(() => state._currentIndex = 3);
                        },
                      ),
                      const SizedBox(width: 12),
                      _QuickBtn(
                        icon: Icons.location_on,
                        label: 'पास में',
                        onTap: () {
                          final state = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          state?.setState(() => state._currentIndex = 2);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.people,
                    label: 'कारीगर',
                    value: '500+',
                    color: const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.work,
                    label: 'नौकरियां',
                    value: '200+',
                    color: const Color(0xFF25D366),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.location_city,
                    label: 'जिले',
                    value: '30+',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Category section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('काम के प्रकार',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _CatItem(emoji: '🚗', label: 'ड्राइवर'),
                  _CatItem(emoji: '🏗️', label: 'निर्माण'),
                  _CatItem(emoji: '🛡️', label: 'सिक्योरिटी'),
                  _CatItem(emoji: '🏪', label: 'दुकान'),
                  _CatItem(emoji: '⚡', label: 'इलेक्ट्रीशियन'),
                  _CatItem(emoji: '🏭', label: 'फैक्ट्री'),
                  _CatItem(emoji: '🛵', label: 'डिलीवरी'),
                  _CatItem(emoji: '🍽️', label: 'होटल'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Post job / Register worker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Employer card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EmployerScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.business,
                                  color: Color(0xFF1565C0), size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('💼 नौकरी पोस्ट करें',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  Text('काम देने वाले के लिए',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // WhatsApp help
                  Card(
                    elevation: 2,
                    color: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final uri = Uri.parse(
                            'https://wa.me/918779937845?text=${Uri.encodeComponent('नमस्ते, काम धंधा ऐप से मदद चाहिए।')}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.chat, color: Colors.white, size: 28),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('WhatsApp पर मदद',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  Text('किसी भी सवाल के लिए संपर्क करें',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatItem extends StatelessWidget {
  final String emoji;
  final String label;
  const _CatItem({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
