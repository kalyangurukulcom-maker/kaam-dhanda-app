import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'jobs_screen.dart';
import 'worker_marketplace_screen.dart';
import 'nearby_workers_screen.dart';
import 'employer_screen.dart';
import 'login_screen.dart';
import 'web_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Screens defined once — _LazyIndexedStack builds each only on first visit.
  static const _screens = [
    _HomeTab(),
    JobsScreen(),
    NearbyWorkersScreen(),
    WorkerMarketplaceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _LazyIndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'होम'),
          BottomNavigationBarItem(icon: Icon(Icons.work_rounded), label: 'नौकरी'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_rounded), label: 'पास में'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'कारीगर'),
        ],
      ),
    );
  }
}

/// Lazy IndexedStack — only builds a child widget the first time its tab is visited.
/// Once built, the widget is kept alive (state preserved on tab switch).
class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _LazyIndexedStack({required this.index, required this.children});

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    // Only the first/current tab is built on startup.
    _activated = List.generate(
      widget.children.length,
      (i) => i == widget.index,
    );
  }

  @override
  void didUpdateWidget(_LazyIndexedStack old) {
    super.didUpdateWidget(old);
    // Activate the new tab if not yet built.
    if (!_activated[widget.index]) {
      setState(() => _activated[widget.index] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(
        widget.children.length,
        (i) => _activated[i] ? widget.children[i] : const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with AutomaticKeepAliveClientMixin {
  // Keep state alive when switching bottom nav tabs
  @override
  bool get wantKeepAlive => true;

  String _phone = '';
  String _userName = '';
  String _userType = 'guest';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone') ?? '';
    final name = prefs.getString('user_name') ?? '';
    final userType = prefs.getString('user_type') ?? 'guest';
    if (mounted) {
      setState(() {
        _phone = phone;
        _userName = name;
        _userType = userType;
        _isLoggedIn = phone.isNotEmpty && userType != 'guest';
      });
    }
  }

  Future<void> _openWhatsApp() async {
    const uri =
        'https://wa.me/919999999999?text=नमस्ते, मुझे काम धंधा ऐप से मदद चाहिए।';
    final url = Uri.parse(uri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('क्या आप logout करना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('नहीं'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('हाँ, Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildUserBanner(),
                _buildSearchBar(),
                _buildStats(),
                _buildQuickActions(),
                _buildCategories(),
                _buildEmployerCard(),
                _buildWebFeatures(),
                _buildWhatsAppHelp(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFF1565C0),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.work_rounded,
                color: Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'काम धंधा',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: Colors.white, size: 24),
          onPressed: () {},
        ),
        GestureDetector(
          onTap: _isLoggedIn
              ? _logout
              : () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                  _loadUserData();
                },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isLoggedIn ? 'Logout' : 'Login',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child:
          _isLoggedIn ? _buildLoggedInBanner() : _buildLoginPrompt(),
    );
  }

  Widget _buildLoggedInBanner() {
    final typeLabel = _userType == 'worker'
        ? 'कारीगर'
        : _userType == 'employer'
            ? 'नियोक्ता'
            : 'सदस्य';
    final typeColor = _userType == 'worker'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);
    final initial = _userName.isNotEmpty
        ? _userName[0]
        : _phone.isNotEmpty
            ? _phone[_phone.length - 1]
            : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            initial.toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'नमस्ते, ${_userName.isNotEmpty ? _userName : 'दोस्त'}! 👋',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(typeLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  if (_phone.isNotEmpty)
                    Text(_phone,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('नमस्ते! 👋',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 6),
              const Text(
                'अपना काम धंधा\nशुरू करें',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2),
              ),
              const SizedBox(height: 6),
              const Text(
                'Login करें और हजारों नौकरियां खोजें',
                style:
                    TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                      _loadUserData();
                    },
                    child: const Text('Login करें',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                      _loadUserData();
                    },
                    child: const Text('Register',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.work_history_rounded,
            size: 90, color: Colors.white12),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded,
                  color: Color(0xFF1565C0), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const JobsScreen())),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'नौकरी या कारीगर खोजें...',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const JobsScreen())),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('खोजें',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: const [
          _StatTile(
              value: '500+',
              label: 'कारीगर',
              icon: Icons.people_rounded,
              color: Color(0xFF1565C0)),
          SizedBox(width: 10),
          _StatTile(
              value: '200+',
              label: 'नौकरियां',
              icon: Icons.work_rounded,
              color: Color(0xFFE65100)),
          SizedBox(width: 10),
          _StatTile(
              value: '30+',
              label: 'शहर',
              icon: Icons.location_city_rounded,
              color: Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('क्या करना है?',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionCard(
                icon: Icons.search_rounded,
                label: 'नौकरी\nखोजें',
                color: const Color(0xFF1565C0),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const JobsScreen())),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.people_rounded,
                label: 'कारीगर\nढूंढें',
                color: const Color(0xFFE65100),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const WorkerMarketplaceScreen())),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.location_on_rounded,
                label: 'पास में\nकारीगर',
                color: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NearbyWorkersScreen())),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.post_add_rounded,
                label: 'नौकरी\nदें',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmployerScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    const cats = [
      {'emoji': '🧱', 'name': 'राजमिस्त्री', 'color': 0xFFFF5722},
      {'emoji': '🔧', 'name': 'प्लंबर', 'color': 0xFF2196F3},
      {'emoji': '⚡', 'name': 'इलेक्ट्रि.', 'color': 0xFFFF9800},
      {'emoji': '🎨', 'name': 'पेंटर', 'color': 0xFF9C27B0},
      {'emoji': '🪚', 'name': 'कारपेंटर', 'color': 0xFF795548},
      {'emoji': '🧹', 'name': 'सफाई', 'color': 0xFF00BCD4},
      {'emoji': '👨‍🍳', 'name': 'रसोइया', 'color': 0xFFE91E63},
      {'emoji': '🚗', 'name': 'ड्राइवर', 'color': 0xFF607D8B},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('श्रेणियां',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              itemBuilder: (ctx, i) {
                final c = cats[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const WorkerMarketplaceScreen())),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Color(c['color'] as int)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Color(c['color'] as int)
                                    .withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text(c['emoji'] as String,
                                style:
                                    const TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(c['name'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF444444))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EmployerScreen())),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_center_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('मालिक हैं? कारीगर ढूंढें',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                        'अभी कारीगर भेजें और WhatsApp से बात करें',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFeatures() {
    const features = [
      {
        'icon': Icons.app_registration,
        'label': 'काम पर रखें',
        'sub': 'Hire करें',
        'url': 'https://kamdhanda.in/hire.html',
        'color': Color(0xFF0D47A1)
      },
      {
        'icon': Icons.school,
        'label': 'गुरुकुल साथी',
        'sub': 'Training',
        'url': 'https://kamdhanda.in/gur{ul.html',
        'color': Color(0xFF1B5E20)
      },
      {
        'icon': Icons.agriculture,
        'label': 'ग्रामीण साथी',
        'sub': 'गांव में काम',
        'url': 'https://kamdhanda.in/grameen-sathi.html',
        'color': Color(0xFF4A148C)
      },
      {
        'icon': Icons.engineering,
        'label': 'Field Staff',
        'sub': 'फील्ड जॉब्स',
        'url': 'https://kamdhanda.in/field-staff.html',
        'color': Color(0xFFBF360C)
      },
      {
        'icon': Icons.calculate,
        'label': 'Salary Calc',
        'sub': 'वेतन जानें',
        'url': 'https://kamdhanda.in/salary-calculator.html',
        'color': Color(0xFF006064)
      },
      {
        'icon': Icons.description,
        'label': 'Resume Builder',
        'sub': 'CV बनाएं',
        'url': 'https://kamdhanda.in/resume-builder.html',
        'color': Color(0xFF33691E)
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.public_rounded,
                    color: Color(0xFF1565C0), size: 18),
              ),
              const SizedBox(width: 8),
              const Text('और Features',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (f['color'] as Color)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f['icon'] as IconData,
                            color: f['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f['label'] as String,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        f['sub'] as String,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
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

  Widget _buildWhatsAppHelp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GestureDetector(
        onTap: _openWhatsApp,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF25D366).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_rounded,
                    color: Color(0xFF25D366), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WhatsApp सहायता',
                        style: TextStyle(
                            color: Color(0xFF25D366),
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    Text('कोई समस्या? हमसे बात करें',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets (all const-constructible for zero rebuild cost)
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333)),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
