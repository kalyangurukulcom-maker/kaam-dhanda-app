// ============================================================
// Feature #125: Grameen Sathi Screen
// File: lib/screens/grameen_sathi_screen.dart
// Kaam Dhanda App — Flutter
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => GrameenSathiScreen(
//       staffId: 'GS001',
//       staffName: 'Ramesh Kumar',
//     ),
//   ));
//
// pubspec.yaml mein yeh add karo:
//   dependencies:
//     cloud_firestore: ^4.13.6
//     intl: ^0.18.1
//     url_launcher: ^6.2.5
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// Payout Calculator Logic
// ============================================================
class _PayoutCalc {
  // Data lead payout slabs
  static int calcDataPayout(int leadCount) {
    if (leadCount <= 0) return 0;
    if (leadCount < 100) return (leadCount * 8).toInt();
    if (leadCount < 250) return 800 + ((leadCount - 100) * 9).toInt();
    if (leadCount < 500) return 2150 + ((leadCount - 250) * 10).toInt();
    if (leadCount < 750) return 4650 + ((leadCount - 500) * 11).toInt();
    if (leadCount < 1000) return 7400 + ((leadCount - 750) * 12).toInt();
    return 10400 + ((leadCount - 1000) * 13).toInt();
  }

  // Gurukul student payout slabs
  static int calcGurukulPayout(int studentCount) {
    if (studentCount <= 0) return 0;
    if (studentCount == 1) return 2500;
    if (studentCount == 2) return 5000;
    if (studentCount == 3) return 7500;
    if (studentCount <= 5) return 7500 + ((studentCount - 3) * 2500);
    if (studentCount <= 8) return 12500 + ((studentCount - 5) * 3000);
    if (studentCount <= 12) return 21500 + ((studentCount - 8) * 3500);
    return 35500 + ((studentCount - 12) * 4000);
  }

  static String formatRs(int amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '₹$amount';
  }
}

// ============================================================
// Main Screen
// ============================================================
class GrameenSathiScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const GrameenSathiScreen({
    Key? key,
    required this.staffId,
    required this.staffName,
  }) : super(key: key);

  @override
  State<GrameenSathiScreen> createState() => _GrameenSathiScreenState();
}

class _GrameenSathiScreenState extends State<GrameenSathiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌾 Grameen Sathi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.staffName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '📊 Dashboard'),
            Tab(text: '➕ Lead जोड़ें'),
            Tab(text: '💰 Calculator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _DashboardTab(staffId: widget.staffId, staffName: widget.staffName, db: _db),
          _AddLeadTab(staffId: widget.staffId, staffName: widget.staffName, db: _db),
          const _CalculatorTab(),
        ],
      ),
    );
  }
}

// ============================================================
// Tab 1: Dashboard
// ============================================================
class _DashboardTab extends StatelessWidget {
  final String staffId;
  final String staffName;
  final FirebaseFirestore db;

  const _DashboardTab({
    required this.staffId,
    required this.staffName,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('grameen_leads')
          .where('staffId', isEqualTo: staffId)
          .snapshots(),
      builder: (context, snap) {
        List<Map<String, dynamic>> leads = [];
        if (snap.hasData) {
          leads = snap.data!.docs
              .map((d) => {...d.data() as Map<String, dynamic>, 'docId': d.id})
              .toList();
        }

        // Stats
        final totalLeads = leads.length;
        final dataLeads =
            leads.where((l) => l['leadType'] == 'data').length;
        final gurukulLeads =
            leads.where((l) => l['leadType'] == 'gurukul').length;
        final convertedLeads =
            leads.where((l) => l['status'] == 'converted').length;

        // Current month leads
        final now = DateTime.now();
        final thisMonthLeads = leads.where((l) {
          final ts = l['createdAt'];
          if (ts == null) return false;
          final dt = (ts as Timestamp).toDate();
          return dt.year == now.year && dt.month == now.month;
        }).toList();

        final monthData =
            thisMonthLeads.where((l) => l['leadType'] == 'data').length;
        final monthGurukul =
            thisMonthLeads.where((l) => l['leadType'] == 'gurukul').length;

        final dataPayout = _PayoutCalc.calcDataPayout(monthData);
        final gurukulPayout = _PayoutCalc.calcGurukulPayout(monthGurukul);
        final totalPayout = dataPayout + gurukulPayout;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Card
              _EarningsCard(
                monthData: monthData,
                monthGurukul: monthGurukul,
                dataPayout: dataPayout,
                gurukulPayout: gurukulPayout,
                totalPayout: totalPayout,
              ),
              const SizedBox(height: 16),

              // Stats Grid
              _StatsGrid(
                totalLeads: totalLeads,
                dataLeads: dataLeads,
                gurukulLeads: gurukulLeads,
                convertedLeads: convertedLeads,
              ),
              const SizedBox(height: 20),

              // Recent Leads
              const Text(
                'हाल के Leads',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 10),

              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20)),
                  ),
                )
              else if (leads.isEmpty)
                _EmptyLeadsCard()
              else
                ...leads.take(20).map((lead) => _LeadTile(lead: lead, db: db)),
            ],
          ),
        );
      },
    );
  }
}

// Earnings Card
class _EarningsCard extends StatelessWidget {
  final int monthData, monthGurukul, dataPayout, gurukulPayout, totalPayout;

  const _EarningsCard({
    required this.monthData,
    required this.monthGurukul,
    required this.dataPayout,
    required this.gurukulPayout,
    required this.totalPayout,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM yyyy').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$month की कमाई',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🌾 Grameen Sathi',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(totalPayout)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PayoutChip(
                label: '📊 Data',
                count: monthData,
                payout: dataPayout,
                color: Colors.blue.shade200,
              ),
              const SizedBox(width: 10),
              _PayoutChip(
                label: '🎓 Gurukul',
                count: monthGurukul,
                payout: gurukulPayout,
                color: Colors.amber.shade200,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutChip extends StatelessWidget {
  final String label;
  final int count;
  final int payout;
  final Color color;

  const _PayoutChip({
    required this.label,
    required this.count,
    required this.payout,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '$count leads',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _PayoutCalc.formatRs(payout),
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Stats Grid
class _StatsGrid extends StatelessWidget {
  final int totalLeads, dataLeads, gurukulLeads, convertedLeads;

  const _StatsGrid({
    required this.totalLeads,
    required this.dataLeads,
    required this.gurukulLeads,
    required this.convertedLeads,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: [
        _StatCard('कुल Leads', '$totalLeads', '📋', const Color(0xFF1565C0)),
        _StatCard('Data Leads', '$dataLeads', '📊', const Color(0xFF6A1B9A)),
        _StatCard('Gurukul', '$gurukulLeads', '🎓', const Color(0xFFE65100)),
        _StatCard('Converted', '$convertedLeads', '✅', const Color(0xFF2E7D32)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

// Lead Tile
class _LeadTile extends StatelessWidget {
  final Map<String, dynamic> lead;
  final FirebaseFirestore db;

  const _LeadTile({required this.lead, required this.db});

  Color _statusColor(String? status) {
    switch (status) {
      case 'converted':
        return Colors.green;
      case 'interested':
        return Colors.blue;
      case 'not_interested':
        return Colors.red;
      case 'callback':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'converted':
        return '✅ Converted';
      case 'interested':
        return '👍 Interested';
      case 'not_interested':
        return '❌ Not Interested';
      case 'callback':
        return '📞 Callback';
      default:
        return '🆕 New';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = lead['candidateName'] ?? 'Unknown';
    final phone = lead['candidatePhone'] ?? '';
    final type = lead['leadType'] ?? 'data';
    final status = lead['status'] ?? 'new';
    final area = lead['area'] ?? '';
    final ts = lead['createdAt'];
    String timeStr = '';
    if (ts != null) {
      final dt = (ts as Timestamp).toDate();
      timeStr = DateFormat('dd MMM, hh:mm a').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: type == 'gurukul'
              ? Colors.amber.shade100
              : Colors.blue.shade100,
          child: Text(
            type == 'gurukul' ? '🎓' : '📊',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _statusColor(status).withOpacity(0.5)),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                    fontSize: 10,
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (area.isNotEmpty)
              Text('📍 $area',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            if (timeStr.isNotEmpty)
              Text(timeStr,
                  style: const TextStyle(fontSize: 11, color: Colors.black38)),
          ],
        ),
        trailing: phone.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.phone, color: Color(0xFF1B5E20)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  launchUrl(Uri.parse('tel:$phone'));
                },
              )
            : null,
        onTap: () => _showStatusSheet(context),
      ),
    );
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StatusUpdateSheet(
          lead: lead, db: db),
    );
  }
}

// Status Update Sheet
class _StatusUpdateSheet extends StatelessWidget {
  final Map<String, dynamic> lead;
  final FirebaseFirestore db;

  const _StatusUpdateSheet({required this.lead, required this.db});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'key': 'new', 'label': '🆕 New', 'color': Colors.grey},
      {'key': 'interested', 'label': '👍 Interested', 'color': Colors.blue},
      {'key': 'callback', 'label': '📞 Callback', 'color': Colors.orange},
      {'key': 'converted', 'label': '✅ Converted', 'color': Colors.green},
      {
        'key': 'not_interested',
        'label': '❌ Not Interested',
        'color': Colors.red
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lead['candidateName'] ?? ''} — Status Update',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...statuses.map((s) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor:
                      (s['color'] as Color).withOpacity(0.15),
                  radius: 16,
                  child: Text(
                    (s['label'] as String).split(' ')[0],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                title: Text(
                  (s['label'] as String).split(' ').skip(1).join(' '),
                  style: TextStyle(
                      color: s['color'] as Color,
                      fontWeight: FontWeight.w600),
                ),
                trailing: lead['status'] == s['key']
                    ? const Icon(Icons.check_circle,
                        color: Colors.green)
                    : null,
                onTap: () async {
                  await db
                      .collection('grameen_leads')
                      .doc(lead['docId'])
                      .update({
                    'status': s['key'],
                    'statusUpdatedAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

// Empty Card
class _EmptyLeadsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'अभी कोई Lead नहीं',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54),
          ),
          const SizedBox(height: 6),
          const Text(
            '"Lead जोड़ें" tab में पहला lead add करें',
            style: TextStyle(fontSize: 13, color: Colors.black38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Tab 2: Add Lead Form
// ============================================================
class _AddLeadTab extends StatefulWidget {
  final String staffId;
  final String staffName;
  final FirebaseFirestore db;

  const _AddLeadTab({
    required this.staffId,
    required this.staffName,
    required this.db,
  });

  @override
  State<_AddLeadTab> createState() => _AddLeadTabState();
}

class _AddLeadTabState extends State<_AddLeadTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _leadType = 'data'; // 'data' or 'gurukul'
  String _selectedSkill = 'Construction';
  bool _saving = false;

  final List<String> _skills = [
    'Construction', 'Painting', 'Plumbing', 'Electrical', 'Carpentry',
    'Welding', 'Cooking', 'Cleaning', 'Security', 'Driving', 'Tailoring',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLead() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await widget.db.collection('grameen_leads').add({
        'staffId': widget.staffId,
        'staffName': widget.staffName,
        'candidateName': _nameCtrl.text.trim(),
        'candidatePhone': _phoneCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'leadType': _leadType,
        'skill': _selectedSkill,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      HapticFeedback.mediumImpact();
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _areaCtrl.clear();
      _noteCtrl.clear();
      setState(() {
        _leadType = 'data';
        _selectedSkill = 'Construction';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Lead सफलतापूर्वक जोड़ा गया!'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lead Type Toggle
            _SectionHeader(
                icon: '📋', title: 'Lead Type चुनें'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TypeToggle(
                    icon: '📊',
                    label: 'Data Lead',
                    subtitle: 'Worker/candidate ka data',
                    selected: _leadType == 'data',
                    onTap: () => setState(() => _leadType = 'data'),
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeToggle(
                    icon: '🎓',
                    label: 'Gurukul Lead',
                    subtitle: 'Training ke liye student',
                    selected: _leadType == 'gurukul',
                    onTap: () => setState(() => _leadType = 'gurukul'),
                    color: const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Candidate Info
            _SectionHeader(icon: '👤', title: 'Candidate जानकारी'),
            const SizedBox(height: 10),
            _FormField(
              controller: _nameCtrl,
              label: 'पूरा नाम *',
              hint: 'जैसे: Ramesh Kumar',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'नाम जरूरी है' : null,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _phoneCtrl,
              label: 'मोबाइल नंबर *',
              hint: '10 अंक का नंबर',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'नंबर जरूरी है';
                if (v.trim().length != 10) return '10 अंक का नंबर डालें';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _areaCtrl,
              label: 'गांव / इलाका *',
              hint: 'जैसे: Ranchi, Jharkhand',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'इलाका जरूरी है' : null,
            ),
            const SizedBox(height: 20),

            // Skill (only for data leads)
            if (_leadType == 'data') ...[
              _SectionHeader(icon: '🔧', title: 'काम / Skill'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: DropdownButton<String>(
                  value: _selectedSkill,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _skills
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSkill = v ?? 'Construction'),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Note
            _SectionHeader(icon: '📝', title: 'Note (optional)'),
            const SizedBox(height: 10),
            _FormField(
              controller: _noteCtrl,
              label: 'कोई ज़रूरी बात',
              hint: 'जैसे: Interested, Call after 6pm...',
              icon: Icons.note_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submitLead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌾', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            _leadType == 'data'
                                ? 'Data Lead Submit करें'
                                : 'Gurukul Lead Submit करें',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Type Toggle Card
class _TypeToggle extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _TypeToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: selected ? Colors.white70 : Colors.black45,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tab 3: Earnings Calculator
// ============================================================
class _CalculatorTab extends StatefulWidget {
  const _CalculatorTab();

  @override
  State<_CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<_CalculatorTab> {
  double _dataSlider = 0;
  double _gurukulSlider = 0;

  int get dataCount => _dataSlider.round();
  int get gurukulCount => _gurukulSlider.round();

  int get dataPayout => _PayoutCalc.calcDataPayout(dataCount);
  int get gurukulPayout => _PayoutCalc.calcGurukulPayout(gurukulCount);
  int get totalPayout => dataPayout + gurukulPayout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Payout Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                const Text('💰 कुल संभावित कमाई',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '₹${NumberFormat('#,##,###').format(totalPayout)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'प्रति माह ($dataCount Data + $gurukulCount Gurukul)',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Leads Slider
          _CalcSection(
            icon: '📊',
            title: 'Data Leads',
            color: const Color(0xFF1565C0),
            count: dataCount,
            payout: dataPayout,
            slider: Slider(
              value: _dataSlider,
              min: 0,
              max: 500,
              divisions: 50,
              activeColor: const Color(0xFF1565C0),
              label: '$dataCount leads',
              onChanged: (v) => setState(() => _dataSlider = v),
            ),
            slabs: const [
              '1-99 → ₹8/lead',
              '100-249 → ₹9/lead',
              '250-499 → ₹10/lead',
              '500+ → ₹11/lead',
            ],
          ),
          const SizedBox(height: 20),

          // Gurukul Slider
          _CalcSection(
            icon: '🎓',
            title: 'Gurukul Students',
            color: const Color(0xFFE65100),
            count: gurukulCount,
            payout: gurukulPayout,
            slider: Slider(
              value: _gurukulSlider,
              min: 0,
              max: 20,
              divisions: 20,
              activeColor: const Color(0xFFE65100),
              label: '$gurukulCount students',
              onChanged: (v) => setState(() => _gurukulSlider = v),
            ),
            slabs: const [
              '1 student → ₹2,500',
              '2 students → ₹5,000',
              '5 students → ₹12,500',
              '10 students → ₹28,000',
            ],
          ),
          const SizedBox(height: 24),

          // Payout Table
          _PayoutTable(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CalcSection extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;
  final int count;
  final int payout;
  final Widget slider;
  final List<String> slabs;

  const _CalcSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.count,
    required this.payout,
    required this.slider,
    required this.slabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  Text(
                    _PayoutCalc.formatRs(payout),
                    style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          slider,
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: slabs
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// Payout reference table
class _PayoutTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      ['100 Data', '₹${NumberFormat('#,##,###').format(_PayoutCalc.calcDataPayout(100))}'],
      ['250 Data', '₹${NumberFormat('#,##,###').format(_PayoutCalc.calcDataPayout(250))}'],
      ['500 Data', '₹${NumberFormat('#,##,###').format(_PayoutCalc.calcDataPayout(500))}'],
      ['1000 Data', '₹${NumberFormat('#,##,###').format(_PayoutCalc.calcDataPayout(1000))}'],
      ['5 Gurukul', '₹${NumberFormat('#,##,###').format(_PayoutCalc.calcGurukulPayout(5))}'],
      ['10 Gurukul', '₹${NumberFormat('#,##,###').format(_PayoutCalc.calcGurukulPayout(10))}'],
      ['15 Gurukul', '₹${NumberFormat('#,##,###').format(_PayoutCalc.calcGurukulPayout(15))}'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: const [
                Text('📈', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Payout Reference Table',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.asMap().entries.map((e) => Container(
                color: e.key.isEven
                    ? Colors.grey.shade50
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.value[0],
                        style: const TextStyle(fontSize: 13)),
                    Text(
                      e.value[1],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ============================================================
// Shared Helpers
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1B5E20)),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
    );
  }
}
