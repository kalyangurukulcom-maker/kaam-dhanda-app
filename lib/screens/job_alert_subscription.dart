// ============================================================
// Feature #107: Job Alert WhatsApp Subscription
// File: lib/screens/job_alert_subscription.dart
// Kaam Dhanda App — Flutter
//
// 2 Components:
//
// 1. JobAlertSubscriptionScreen — full page
//    Navigator.push(context, MaterialPageRoute(
//      builder: (_) => JobAlertSubscriptionScreen(
//        workerId: 'W001',
//        workerName: 'Ramesh Kumar',
//        workerPhone: '9876543210',
//      ),
//    ));
//
// 2. JobAlertBannerCard — small home screen promo card
//    JobAlertBannerCard(
//      workerId: 'W001',
//      workerName: 'Ramesh Kumar',
//      workerPhone: '9876543210',
//    )
//
// Firestore: job_alert_subscriptions collection
//   Fields: workerId, workerName, workerPhone, categories[], states[],
//           frequency, subscribed, subscribedAt, updatedAt
//
// pubspec.yaml:
//   url_launcher: ^6.2.5
//   cloud_firestore: ^4.13.6
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// Data
// ============================================================
const _kCategories = [
  {'icon': '🏗️', 'label': 'Construction'},
  {'icon': '🎨', 'label': 'Painting'},
  {'icon': '🔧', 'label': 'Plumbing'},
  {'icon': '⚡', 'label': 'Electrical'},
  {'icon': '🪵', 'label': 'Carpentry'},
  {'icon': '🔩', 'label': 'Welding'},
  {'icon': '🍳', 'label': 'Cooking'},
  {'icon': '🧹', 'label': 'Cleaning'},
  {'icon': '🛡️', 'label': 'Security'},
  {'icon': '🚗', 'label': 'Driving'},
  {'icon': '✂️', 'label': 'Tailoring'},
  {'icon': '👶', 'label': 'Babysitting'},
  {'icon': '🏥', 'label': 'Healthcare'},
  {'icon': '📦', 'label': 'Delivery'},
];

const _kStates = [
  {'icon': '⛏️', 'label': 'Jharkhand'},
  {'icon': '🏙️', 'label': 'Maharashtra'},
  {'icon': '🌆', 'label': 'Delhi'},
  {'icon': '🌴', 'label': 'Karnataka'},
  {'icon': '💎', 'label': 'Gujarat'},
  {'icon': '🌊', 'label': 'Tamil Nadu'},
  {'icon': '🌸', 'label': 'West Bengal'},
  {'icon': '🌾', 'label': 'Uttar Pradesh'},
  {'icon': '🏰', 'label': 'Rajasthan'},
  {'icon': '🌶️', 'label': 'Telangana'},
];

const _kFrequencies = [
  {'key': 'instant', 'label': 'तुरंत', 'desc': 'हर नई Job पर alert', 'icon': '⚡'},
  {'key': 'daily', 'label': 'रोज़', 'desc': 'हर सुबह 9 बजे digest', 'icon': '🌅'},
  {'key': 'weekly', 'label': 'साप्ताहिक', 'desc': 'हर सोमवार सुबह', 'icon': '📅'},
];

// WhatsApp number for job alerts
const _kAlertWhatsApp = '919876543210'; // Replace with actual number

// ============================================================
// 1. Full Screen
// ============================================================
class JobAlertSubscriptionScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String workerPhone;

  const JobAlertSubscriptionScreen({
    Key? key,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
  }) : super(key: key);

  @override
  State<JobAlertSubscriptionScreen> createState() =>
      _JobAlertSubscriptionScreenState();
}

class _JobAlertSubscriptionScreenState
    extends State<JobAlertSubscriptionScreen> {
  final _db = FirebaseFirestore.instance;

  Set<String> _selectedCategories = {};
  Set<String> _selectedStates = {};
  String _frequency = 'daily';
  bool _subscribed = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final doc = await _db
          .collection('job_alert_subscriptions')
          .doc(widget.workerId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _subscribed = data['subscribed'] ?? false;
          _selectedCategories =
              Set<String>.from(data['categories'] ?? []);
          _selectedStates =
              Set<String>.from(data['states'] ?? []);
          _frequency = data['frequency'] ?? 'daily';
        });
      }
    } catch (_) {}
    setState(() => _loaded = true);
  }

  Future<void> _saveAndActivate() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('कम से कम 1 Category चुनें'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _db
          .collection('job_alert_subscriptions')
          .doc(widget.workerId)
          .set({
        'workerId': widget.workerId,
        'workerName': widget.workerName,
        'workerPhone': widget.workerPhone,
        'categories': _selectedCategories.toList(),
        'states': _selectedStates.toList(),
        'frequency': _frequency,
        'subscribed': true,
        'subscribedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _subscribed = true);
      HapticFeedback.mediumImpact();

      // Open WhatsApp to join the group
      await _openWhatsApp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unsubscribe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alert बंद करें?'),
        content: const Text(
            'WhatsApp Job Alerts बंद हो जाएंगे। बाद में फिर subscribe कर सकते हैं।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('बंद करें',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    await _db
        .collection('job_alert_subscriptions')
        .doc(widget.workerId)
        .update({
      'subscribed': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    setState(() => _subscribed = false);
    HapticFeedback.lightImpact();
  }

  Future<void> _openWhatsApp() async {
    final cats = _selectedCategories.join(', ');
    final states = _selectedStates.isEmpty
        ? 'सभी राज्य'
        : _selectedStates.join(', ');
    final freq = _kFrequencies
        .firstWhere((f) => f['key'] == _frequency,
            orElse: () => _kFrequencies[1])['label'];

    final msg = Uri.encodeComponent(
      'नमस्ते! मैं Kaam Dhanda Job Alerts subscribe करना चाहता हूँ।\n\n'
      '👤 नाम: ${widget.workerName}\n'
      '📞 Phone: ${widget.workerPhone}\n'
      '🔧 Skills: $cats\n'
      '📍 Location: $states\n'
      '🔔 Frequency: $freq\n\n'
      'कृपया मुझे Job Alerts Group में add करें। 🙏',
    );

    final uri = Uri.parse('https://wa.me/$_kAlertWhatsApp?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '🔔 Job Alert Subscribe',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          if (_subscribed)
            TextButton(
              onPressed: _unsubscribe,
              child: const Text('Unsubscribe',
                  style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _subscribed
              ? _SubscribedView(
                  workerName: widget.workerName,
                  categories: _selectedCategories,
                  states: _selectedStates,
                  frequency: _frequency,
                  onEdit: () => setState(() => _subscribed = false),
                  onWhatsApp: _openWhatsApp,
                )
              : _SetupView(
                  selectedCategories: _selectedCategories,
                  selectedStates: _selectedStates,
                  frequency: _frequency,
                  saving: _saving,
                  onCategoryToggle: (cat) => setState(() {
                    _selectedCategories.contains(cat)
                        ? _selectedCategories.remove(cat)
                        : _selectedCategories.add(cat);
                  }),
                  onStateToggle: (st) => setState(() {
                    _selectedStates.contains(st)
                        ? _selectedStates.remove(st)
                        : _selectedStates.add(st);
                  }),
                  onFrequencyChange: (f) =>
                      setState(() => _frequency = f),
                  onSubscribe: _saveAndActivate,
                ),
    );
  }
}

// ============================================================
// Setup View (before subscribing)
// ============================================================
class _SetupView extends StatelessWidget {
  final Set<String> selectedCategories;
  final Set<String> selectedStates;
  final String frequency;
  final bool saving;
  final void Function(String) onCategoryToggle;
  final void Function(String) onStateToggle;
  final void Function(String) onFrequencyChange;
  final VoidCallback onSubscribe;

  const _SetupView({
    required this.selectedCategories,
    required this.selectedStates,
    required this.frequency,
    required this.saving,
    required this.onCategoryToggle,
    required this.onStateToggle,
    required this.onFrequencyChange,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          _HeroBanner(),
          const SizedBox(height: 24),

          // Category Selection
          _SectionTitle(
            icon: '🔧',
            title: 'आप किस काम की Job चाहते हैं? *',
            subtitle: 'एक या ज़्यादा चुनें',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kCategories.map((cat) {
              final label = cat['label']!;
              final selected = selectedCategories.contains(label);
              return _FilterChip(
                icon: cat['icon']!,
                label: label,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategoryToggle(label);
                },
                selectedColor: const Color(0xFF1565C0),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // State Selection
          _SectionTitle(
            icon: '📍',
            title: 'कहाँ की Job चाहिए?',
            subtitle: 'खाली छोड़ने पर सभी राज्यों के alerts मिलेंगे',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kStates.map((st) {
              final label = st['label']!;
              final selected = selectedStates.contains(label);
              return _FilterChip(
                icon: st['icon']!,
                label: label,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onStateToggle(label);
                },
                selectedColor: const Color(0xFF2E7D32),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Frequency
          _SectionTitle(
            icon: '🔔',
            title: 'Alert कितनी बार चाहिए?',
            subtitle: 'अपनी पसंद चुनें',
          ),
          const SizedBox(height: 10),
          ..._kFrequencies.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FrequencyOption(
                  icon: f['icon']!,
                  label: f['label']!,
                  desc: f['desc']!,
                  selected: frequency == f['key'],
                  onTap: () => onFrequencyChange(f['key']!),
                ),
              )),
          const SizedBox(height: 28),

          // Subscribe Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: saving ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('📲', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 10),
                        Text(
                          'WhatsApp पर Subscribe करें',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Free है • कभी भी Unsubscribe कर सकते हैं',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================================
// Subscribed View (after subscribing)
// ============================================================
class _SubscribedView extends StatelessWidget {
  final String workerName;
  final Set<String> categories;
  final Set<String> states;
  final String frequency;
  final VoidCallback onEdit;
  final VoidCallback onWhatsApp;

  const _SubscribedView({
    required this.workerName,
    required this.categories,
    required this.states,
    required this.frequency,
    required this.onEdit,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final freqLabel = _kFrequencies
        .firstWhere((f) => f['key'] == frequency,
            orElse: () => _kFrequencies[1])['label']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Success icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$workerName,\nआपके Job Alerts Active हैं! 🎉',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'WhatsApp पर Job Alerts मिलते रहेंगे',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('आपकी Preferences',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 20),
                _PrefRow(
                  icon: '🔧',
                  label: 'Skills',
                  value: categories.isEmpty
                      ? 'सभी'
                      : categories.join(', '),
                ),
                const SizedBox(height: 10),
                _PrefRow(
                  icon: '📍',
                  label: 'Location',
                  value: states.isEmpty ? 'सभी राज्य' : states.join(', '),
                ),
                const SizedBox(height: 10),
                _PrefRow(
                  icon: '🔔',
                  label: 'Frequency',
                  value: freqLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // WhatsApp button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onWhatsApp,
              icon: const Text('💬', style: TextStyle(fontSize: 20)),
              label: const Text('WhatsApp Group Join करें',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Edit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Preferences बदलें'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================================
// 2. JobAlertBannerCard — Home Screen Promo
// ============================================================
class JobAlertBannerCard extends StatelessWidget {
  final String workerId;
  final String workerName;
  final String workerPhone;

  const JobAlertBannerCard({
    Key? key,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_alert_subscriptions')
          .doc(workerId)
          .snapshots(),
      builder: (context, snap) {
        final subscribed = snap.hasData &&
            snap.data!.exists &&
            (snap.data!.data() as Map<String, dynamic>?)?['subscribed'] ==
                true;

        if (subscribed) {
          // Already subscribed — show small active badge
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF25D366).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Text('✅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Job Alerts Active हैं! WhatsApp पर Jobs मिल रहे हैं',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobAlertSubscriptionScreen(
                        workerId: workerId,
                        workerName: workerName,
                        workerPhone: workerPhone,
                      ),
                    ),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: Color(0xFF2E7D32), size: 20),
                ),
              ],
            ),
          );
        }

        // Not subscribed — show promo banner
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobAlertSubscriptionScreen(
                  workerId: workerId,
                  workerName: workerName,
                  workerPhone: workerPhone,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF075E54).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('📲',
                      style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp Job Alerts चालू करें',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'अपनी Skill की नई Jobs सीधे WhatsApp पर पाएं — Free!',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Subscribe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// Shared Widgets
// ============================================================
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075E54), Color(0xFF25D366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('📲', style: TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp Job Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'अपनी Skill की नई Jobs सीधे\nWhatsApp पर पाएं — बिल्कुल Free!',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    _Pill('✅ Free'),
                    SizedBox(width: 6),
                    _Pill('🚫 Spam नहीं'),
                    SizedBox(width: 6),
                    _Pill('🔕 Anytime Cancel'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _SectionTitle(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: selectedColor.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : Colors.black87,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final String icon;
  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.icon,
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF25D366).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF25D366)
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? const Color(0xFF075E54)
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF25D366), size: 22)
            else
              Icon(Icons.radio_button_unchecked,
                  color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _PrefRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
