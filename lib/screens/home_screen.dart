import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'jobs_screen.dart';
import 'worker_marketplace_screen.dart';
import 'nearby_workers_screen.dart';
import 'employer_screen.dart';
import 'web_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  int _totalWorkers = 0;
  int _totalJobs = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    JobsScreen(),
    NearbyWorkersScreen(),
    WorkerMarketplaceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final w = await _db.collection('workers').get();
      final j = await _db.collection('jobs').get();
      if (mounted) {
        setState(() {
          _totalWorkers = w.docs.length;
          _totalJobs = j.docs.length;
        });
      }
    } catch (e) {
      // ignore stats error
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'घर'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'नौकरी'),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: 'पास में'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'कारीगर'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Future<void> _openWhatsApp(BuildContext context) async {
    const uri =
        'https://wa.me/919999999999?text=नमस्ते, काम धंधा ऐप से मदद चाहिए।';
    final url = Uri.parse(uri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text(
          'काम धंधा',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildStats(context),
            _buildQuickActions(context),
            _buildCategories(context),
            _buildEmployerCard(context),
            _buildWebFeatures(context),
            _buildWhatsAppHelp(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '';
    return Container(
      color: const Color(0xFF1565C0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'नमस्ते! 👋',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
          Text(
            phone.isNotEmpty ? phone : 'काम धंधा ऐप',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'आपके लिए सही नौकरी खोजें',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(icon: Icons.people, label: 'कारीगर', value: '500+'),
          const SizedBox(width: 12),
          _StatCard(icon: Icons.work, label: 'नौकरियां', value: '200+'),
          const SizedBox(width: 12),
          _StatCard(icon: Icons.location_city, label: 'शहर', value: '30+'),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'जल्दी करें',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuickBtn(
                icon: Icons.work_outline,
                label: 'नौकरी खोजें',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobsScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _QuickBtn(
                icon: Icons.people_outline,
                label: 'कारीगर ढूंढें',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WorkerMarketplaceScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _QuickBtn(
                icon: Icons.location_on_outlined,
                label: 'पास में',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NearbyWorkersScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final cats = [
      {'emoji': '🧱', 'name': 'राजमिस्त्री'},
      {'emoji': '🔧', 'name': 'प्लंबर'},
      {'emoji': '⚡', 'name': 'इलेक्ट्रिशियन'},
      {'emoji': '🎨', 'name': 'पेंटर'},
      {'emoji': '🪚', 'name': 'कारपेंटर'},
      {'emoji': '🧵', 'name': 'दर्जी'},
      {'emoji': '👨‍🍳', 'name': 'रसोइया'},
      {'emoji': '🏠', 'name': 'घरेलू'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'श्रेणियां',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              itemBuilder: (ctx, i) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cats[i]['emoji']!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cats[i]['name']!,
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployerCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployerScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.business_center, color: Colors.white, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'मालिक हैं? कारीगर ढूंढें',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'उपलब्ध कारीगर देखें और सीधे WhatsApp करें',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFeatures(BuildContext context) {
    final features = [
      {
        'icon': Icons.app_registration,
        'label': 'काम पर रखें',
        'sub': 'कारीगर hire करें',
        'url': 'https://kamdhanda.in/hire.html',
        'color': const Color(0xFF0D47A1),
      },
      {
        'icon': Icons.school,
        'label': 'गुरुकुल साथी',
        'sub': 'Training & Skill',
        'url': 'https://kamdhanda.in/gurkul.html',
        'color': const Color(0xFF1B5E20),
      },
      {
        'icon': Icons.agriculture,
        'label': 'ग्रामीण साथी',
        'sub': 'गांव में काम',
        'url': 'https://kamdhanda.in/grameen-sathi.html',
        'color': const Color(0xFF4A148C),
      },
      {
        'icon': Icons.engineering,
        'label': 'Field Staff',
        'sub': 'फील्ड जॉब्स',
        'url': 'https://kamdhanda.in/field-staff.html',
        'color': const Color(0xFFBF360C),
      },
      {
        'icon': Icons.calculate,
        'label': 'Salary Calculator',
        'sub': 'वेतन जानें',
        'url': 'https://kamdhanda.in/salary-calculator.html',
        'color': const Color(0xFF006064),
      },
      {
        'icon': Icons.description,
        'label': 'Resume Builder',
        'sub': 'CV बनाएं',
        'url': 'https://kamdhanda.in/resume-builder.html',
        'color': const Color(0xFF33691E),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌐 और Features',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (ctx, i) {
              final f = features[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebViewScreen(
                      url: f['url'] as String,
                      title: f['label'] as String,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(f['icon'] as IconData,
                          color: f['color'] as Color, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        f['label'] as String,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        f['sub'] as String,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppHelp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _openWhatsApp(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF25D366).withOpacity(0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.chat, color: Color(0xFF25D366), size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WhatsApp सहायता',
                      style: TextStyle(
                        color: Color(0xFF25D366),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'कोई समस्या? हमसे बात करें',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
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

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1565C0),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
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

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF1565C0), size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
