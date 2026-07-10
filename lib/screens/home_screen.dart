import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ── Screen imports ──────────────────────────────────────────
import 'worker_marketplace_screen.dart';
import 'jobs_screen.dart';
import 'nearby_workers_screen.dart';
import 'grameen_sathi_screen.dart';
import 'gurkul_screen.dart';
import 'gurkul_dashboard_screen.dart';
import 'field_staff_screen.dart';
import 'employer_screen.dart';
import 'daily_checkin_screen.dart';
import 'monthly_target_screen.dart';
import 'candidate_status_screen.dart';

// ── Design tokens ─────────────────────────────────────────────
class _C {
  static const navy       = Color(0xFF0D1B6B);
  static const navyLight  = Color(0xFF1A2F8A);
  static const orange     = Color(0xFFFF6B00);
  static const orangeL    = Color(0xFFFF8C00);
  static const bg         = Color(0xFFF4F5FA);
  static const card       = Color(0xFFFFFFFF);
  static const text1      = Color(0xFF0F172A);
  static const text2      = Color(0xFF475569);
  static const text3      = Color(0xFF94A3B8);
  // Gurukul Sathi brand
  static const teal       = Color(0xFF0D9488);
  static const tealLight  = Color(0xFF14B8A6);
  static const tealBg     = Color(0xFFE6FFFC);
  // Field Staff brand
  static const purple     = Color(0xFF6D28D9);
  static const purpleBg   = Color(0xFFEDE9FE);
  // Local / Bahar badges
  static const green      = Color(0xFF16A34A);
  static const greenBg    = Color(0xFFDCFCE7);
  static const violet     = Color(0xFF7C3AED);
  static const violetBg   = Color(0xFFF5F3FF);
}

// ── Root Shell ──────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  final _pages = const [
    _DashboardPage(),
    _WorkerHubPage(),
    _JobsHubPage(),
    _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: IndexedStack(index: _idx, children: _pages),
        bottomNavigationBar: _BottomNav(
          index: _idx,
          onTap: (i) { HapticFeedback.selectionClick(); setState(() => _idx = i); },
        ),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded,     label: 'होम',      idx: 0, cur: index, onTap: onTap),
              _NavItem(icon: Icons.people_rounded,   label: 'मजदूर',    idx: 1, cur: index, onTap: onTap),
              _NavItem(icon: Icons.work_rounded,     label: 'नौकरी',    idx: 2, cur: index, onTap: onTap),
              _NavItem(icon: Icons.person_rounded,   label: 'प्रोफाइल', idx: 3, cur: index, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final int idx, cur;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.label, required this.idx, required this.cur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = idx == cur;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: active ? _C.orange.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: active ? _C.orange : _C.text3, size: 24),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? _C.orange : _C.text3,
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DASHBOARD PAGE
// ══════════════════════════════════════════════════════════════
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── HERO APPBAR ─────────────────────────────────────
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          stretch: true,
          backgroundColor: _C.navy,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _HeroBanner(),
          ),
          title: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('क', style: TextStyle(
                color: _C.navy, fontSize: 16, fontWeight: FontWeight.w900,
              )),
            ),
            const SizedBox(width: 8),
            RichText(text: const TextSpan(
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              children: [
                TextSpan(text: 'काम ', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'धंधा', style: TextStyle(color: _C.orange)),
              ],
            )),
          ]),
          actions: [
            IconButton(
              icon: Stack(children: [
                const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                Positioned(right: 2, top: 2,
                  child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: _C.orange, shape: BoxShape.circle))),
              ]),
              onPressed: () {},
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {},
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: _C.orange,
                  child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),

        // ── SEARCH BAR ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SearchBar(),
          ),
        ),

        // ── STATS ROW ───────────────────────────────────────
        SliverToBoxAdapter(child: _StatsRow()),

        // ── QUICK ACTIONS ────────────────────────────────────
        const SliverToBoxAdapter(child: _SectionHeader(title: '🚀 सेवाएं', subtitle: 'सब कुछ एक जगह')),
        SliverToBoxAdapter(child: _QuickActionsGrid()),

        // ── GURUKUL SATHI (SEPARATE SECTION) ────────────────
        SliverToBoxAdapter(child: _GurukulSathiSection()),

        // ── FEATURED JOBS ────────────────────────────────────
        const SliverToBoxAdapter(child: _SectionHeader(title: '🔥 ताज़ी नौकरियाँ', subtitle: 'आज पोस्ट की गई')),
        SliverToBoxAdapter(child: _FeaturedJobs()),

        // ── FIELD STAFF SECTION ─────────────────────────────
        SliverToBoxAdapter(child: _FieldStaffBanner()),

        // ── CATEGORIES ──────────────────────────────────────
        const SliverToBoxAdapter(child: _SectionHeader(title: '📂 श्रेणियाँ', subtitle: 'काम के हिसाब से खोजें')),
        SliverToBoxAdapter(child: _CategoriesGrid()),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Hero Banner ────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1260), Color(0xFF1A2F8A), Color(0xFF0D1B6B)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -30, top: -30, child: _Circle(120, Colors.white.withOpacity(0.04))),
          Positioned(right: 60, bottom: 20, child: _Circle(60, _C.orange.withOpacity(0.15))),
          Positioned(left: -20, bottom: -20, child: _Circle(100, Colors.white.withOpacity(0.03))),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.orange.withOpacity(0.4)),
                  ),
                  child: const Text('⭐ झारखंड का नंबर 1 जॉब प्लेटफॉर्म',
                    style: TextStyle(color: _C.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                RichText(text: const TextSpan(
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.3),
                  children: [
                    TextSpan(text: 'लोकल ', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'और बाहर\n', style: TextStyle(color: _C.orange)),
                    TextSpan(text: 'दोनों की नौकरी!', style: TextStyle(color: Colors.white)),
                  ],
                )),
                const SizedBox(height: 6),
                const Text('राँची, धनबाद, जमशेदपुर — या पुणे, दिल्ली, मुंबई',
                  style: TextStyle(color: Color(0xFFB0BAD4), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size; final Color color;
  const _Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) =>
    Container(width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

// ── Search Bar ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 नौकरी, कंपनी या जगह लिखें...',
              hintStyle: const TextStyle(color: _C.text3, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: _C.orange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text('खोजें', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        _StatChip(value: '15,000+', label: 'नौकरियाँ'),
        const SizedBox(width: 10),
        _StatChip(value: '500+', label: 'कंपनियाँ'),
        const SizedBox(width: 10),
        _StatChip(value: '₹0', label: 'कोई दलाली नहीं', accent: true),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label; final bool accent;
  const _StatChip({required this.value, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: accent ? _C.orange.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent ? _C.orange.withOpacity(0.3) : const Color(0xFFE8EAF6)),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
        ),
        child: Column(children: [
          Text(value, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900,
            color: accent ? _C.orange : _C.navy,
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: _C.text2), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.text1)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: _C.text2)),
        ]),
        TextButton(
          onPressed: () {},
          child: const Text('सभी देखें →', style: TextStyle(color: _C.orange, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Quick Actions Grid ─────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final _actions = const [
    _Action('🏘️', 'लोकल जॉब',    'अपने शहर में',   _C.navy,   '/jobs'),
    _Action('✈️', 'बाहर की जॉब', 'दूसरे राज्य',    Color(0xFF7C3AED), '/jobs'),
    _Action('👷', 'मजदूर ढूंढें', 'हायर करें',      _C.green,  '/hire'),
    _Action('🏢', 'नियोक्ता',     'जॉब पोस्ट करें', Color(0xFF0369A1), '/employer'),
    _Action('📍', 'नज़दीकी',      'पास के कारीगर',   Color(0xFFB45309), '/nearby'),
    _Action('📊', 'ग्रामीण साथी', 'कमाई ट्रैकर',    Color(0xFF0F766E), '/grameen'),
  ];

  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemCount: _actions.length,
        itemBuilder: (c, i) => _ActionCard(action: _actions[i]),
      ),
    );
  }
}

class _Action {
  final String emoji, title, sub, route; final Color color;
  const _Action(this.emoji, this.title, this.sub, this.color, this.route);
}

class _ActionCard extends StatelessWidget {
  final _Action action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(action.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(action.title, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: _C.text1,
          ), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(action.sub, style: const TextStyle(
            fontSize: 10, color: _C.text2,
          ), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// GURUKUL SATHI — COMPLETELY SEPARATE SECTION
// ══════════════════════════════════════════════════════════════
class _GurukulSathiSection extends StatelessWidget {
  const _GurukulSathiSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D4A45), Color(0xFF0D9488), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _C.teal.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(right: -20, top: -20, child: _Circle(100, Colors.white.withOpacity(0.05))),
          Positioned(right: 30, bottom: -10, child: _Circle(60, Colors.white.withOpacity(0.07))),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Text('🎓', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('GURUKUL SATHI PROGRAM', style: TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                      )),
                    ]),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('✨ नया', style: TextStyle(
                      color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w800,
                    )),
                  ),
                ]),

                const SizedBox(height: 14),

                // Main content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Text content
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('गुरुकुल साथी\nबनें — कमाएं', style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          )),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('₹30,000/माह तक', style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            )),
                          ),
                          const SizedBox(height: 8),
                          const Text('अपने नेटवर्क से\nस्टूडेंट्स जोड़ें, कमाएं', style: TextStyle(
                            color: Color(0xFFB2EBE8),
                            fontSize: 12,
                            height: 1.4,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right: Stats box
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(children: [
                          _GuruStat('2,400+', 'साथी'),
                          const Divider(color: Colors.white24, height: 16),
                          _GuruStat('₹28K', 'avg/माह'),
                          const Divider(color: Colors.white24, height: 16),
                          _GuruStat('5⭐', 'रेटिंग'),
                        ]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GurkulScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🎓 Apply करें', style: TextStyle(
                          color: _C.teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GurkulDashboardScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('📊 Dashboard', style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        )),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuruStat extends StatelessWidget {
  final String val, lbl;
  const _GuruStat(this.val, this.lbl);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
    Text(lbl, style: const TextStyle(color: Color(0xFFB2EBE8), fontSize: 10)),
  ]);
}

// ── Featured Jobs ─────────────────────────────────────────
class _FeaturedJobs extends StatelessWidget {
  final _jobs = const [
    _Job('इलेक्ट्रीशियन',  'राँची, झारखंड',  '₹18,000', true,  'ITI कंपनी'),
    _Job('फैक्ट्री वर्कर', 'पुणे, महाराष्ट्र', '₹22,000', false, 'ABC Textiles'),
    _Job('सिक्योरिटी गार्ड', 'जमशेदपुर',     '₹14,000', true,  'Safe Guard'),
    _Job('डिलीवरी बॉय',   'बेंगलुरु',        '₹25,000', false, 'Swiggy'),
    _Job('ड्राइवर',        ' धनबाद',          '₹20,000', true,  'Ola Fleet'),
    _Job('वेल्डर',         'सूरत, गुजरात',    '₹28,000', false, 'Steel Corp'),
  ];

  const _FeaturedJobs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (c, i) => _JobCard(job: _jobs[i]),
      ),
    );
  }
}

class _Job {
  final String title, loc, salary, company; final bool isLocal;
  const _Job(this.title, this.loc, this.salary, this.isLocal, this.company);
}

class _JobCard extends StatelessWidget {
  final _Job job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: job.isLocal ? _C.greenBg : _C.violetBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              job.isLocal ? '🏘️ लोकल' : '✈️ बाहर',
              style: TextStyle(
                color: job.isLocal ? _C.green : _C.violet,
                fontSize: 10, fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(job.title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: _C.text1,
          )),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_rounded, size: 12, color: _C.text3),
            const SizedBox(width: 2),
            Expanded(child: Text(job.loc, style: const TextStyle(fontSize: 11, color: _C.text2),
              overflow: TextOverflow.ellipsis)),
          ]),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(job.salary, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900, color: _C.orange,
            )),
            Text('/माह', style: const TextStyle(fontSize: 10, color: _C.text3)),
          ]),
          const SizedBox(height: 4),
          Text(job.company, style: const TextStyle(fontSize: 10, color: _C.text3)),
        ],
      ),
    );
  }
}

// ── Field Staff Banner ─────────────────────────────────────
class _FieldStaffBanner extends StatelessWidget {
  const _FieldStaffBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF3B0764), Color(0xFF6D28D9), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('🏆 फील्ड स्टाफ', style: TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700,
                )),
              ),
              const SizedBox(height: 8),
              const Text('Supervisor / Leader\nबनें — ₹25,000+', style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1.3,
              )),
              const SizedBox(height: 12),
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldStaffScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Register करें', style: TextStyle(
                      color: _C.purple, fontWeight: FontWeight.w800, fontSize: 12,
                    )),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCheckinScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Text('Check-in', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12,
                    )),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          // Illustration
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👔', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Daily Check-in\nTarget Tracker', style: TextStyle(
                color: Colors.white70, fontSize: 9, height: 1.4,
              ), textAlign: TextAlign.center),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Categories Grid ─────────────────────────────────────────
class _CategoriesGrid extends StatelessWidget {
  final _cats = const [
    ['🔧', 'मैकेनिक'],  ['⚡', 'इलेक्ट्रीशियन'], ['🏗️', 'कारपेंटर'],
    ['🚛', 'ड्राइवर'],  ['🍳', 'कुक/बावर्ची'],    ['🔐', 'सिक्योरिटी'],
    ['🏭', 'फैक्ट्री'], ['📦', 'डिलीवरी'],        ['🧹', 'सफाई कर्मी'],
  ];

  const _CategoriesGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemCount: _cats.length,
        itemBuilder: (c, i) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_cats[i][0], style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(_cats[i][1], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.text1)),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WORKER HUB TAB
// ══════════════════════════════════════════════════════════════
class _WorkerHubPage extends StatelessWidget {
  const _WorkerHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.navy,
        title: const Text('मजदूर / Worker Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubCard(emoji: '👷', title: 'मजदूर ढूंढें', sub: 'Hire a Worker Now',
            color: _C.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerMarketplaceScreen()))),
          const SizedBox(height: 12),
          _HubCard(emoji: '📍', title: 'नज़दीकी कारीगर', sub: 'Nearby Workers Map',
            color: Color(0xFFB45309), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyWorkersScreen()))),
          const SizedBox(height: 12),
          _HubCard(emoji: '📊', title: 'Candidate Status', sub: 'Track Applications',
            color: Color(0xFF0369A1), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CandidateStatusScreen()))),
          const SizedBox(height: 12),
          _HubCard(emoji: '📅', title: 'Monthly Target', sub: 'Target Tracker',
            color: Color(0xFF7C3AED), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyTargetScreen()))),
          const SizedBox(height: 12),
          _HubCard(emoji: '🌾', title: 'ग्रामीण साथी', sub: 'Lead & Earnings',
            color: _C.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrameenSathiScreen()))),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String emoji, title, sub; final Color color; final VoidCallback onTap;
  const _HubCard({required this.emoji, required this.title, required this.sub,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _C.text1)),
            Text(sub, style: const TextStyle(fontSize: 12, color: _C.text2)),
          ]),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// JOBS HUB TAB
// ══════════════════════════════════════════════════════════════
class _JobsHubPage extends StatelessWidget {
  const _JobsHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.navy,
        title: const Text('नौकरी ढूंढें', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const JobsScreen()),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROFILE TAB (placeholder)
// ══════════════════════════════════════════════════════════════
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: _C.navy,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1260), Color(0xFF1A2F8A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 50),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: _C.orange,
                  child: Text('R', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                const Text('Ramesh Kumar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const Text('+91 9876543210', style: TextStyle(color: Color(0xFFB0BAD4), fontSize: 12)),
              ]),
            ),
          ),
        ),
        SliverList(delegate: SliverChildListDelegate([
          const SizedBox(height: 16),
          _ProfileItem(icon: Icons.work_outline, title: 'मेरी नौकरियाँ', sub: '5 Saved Jobs', color: _C.navy),
          _ProfileItem(icon: Icons.star_outline, title: 'मेरी Ratings', sub: '4.8 ⭐', color: _C.orange),
          _ProfileItem(icon: Icons.payment_outlined, title: 'Payment History', sub: '3 Payments', color: _C.green),
          _ProfileItem(icon: Icons.notifications_outlined, title: 'Job Alerts', sub: 'WhatsApp Subscribed', color: _C.violet),
          _ProfileItem(icon: Icons.school_outlined, title: 'Gurukul Status', sub: 'Active Sathi', color: _C.teal),
          _ProfileItem(icon: Icons.share_outlined, title: 'Refer & Earn', sub: '₹500 प्रति रेफरल', color: const Color(0xFFB45309)),
          const SizedBox(height: 80),
        ])),
      ]),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon; final String title, sub; final Color color;
  const _ProfileItem({required this.icon, required this.title, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.text1)),
          Text(sub, style: const TextStyle(fontSize: 12, color: _C.text2)),
        ]),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _C.text3),
      ]),
    );
  }
}
