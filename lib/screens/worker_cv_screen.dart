// ============================================================
// Feature #108: Share Profile + Download CV
// File: lib/screens/worker_cv_screen.dart
// Kaam Dhanda App — Flutter
//
// 3 Components:
//
// 1. WorkerCvScreen — full CV preview + share/download
//    Navigator.push(context, MaterialPageRoute(
//      builder: (_) => WorkerCvScreen(workerId: 'W001'),
//    ));
//
// 2. CvShareButton — small icon button for AppBar/Profile
//    CvShareButton(workerId: 'W001')
//
// 3. WorkerCvCard — the actual CV card widget (repaint boundary
//    captured as image for sharing)
//
// Features:
//   - CV ko image ke roop mein share karo (share_plus)
//   - WhatsApp pe share karo
//   - Profile link copy karo
//   - CV text format mein copy karo (clipboard)
//
// pubspec.yaml:
//   share_plus: ^7.2.1
//   cloud_firestore: ^4.13.6
//   path_provider: ^2.1.1
// ============================================================

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// Worker data model (from Firestore)
// ============================================================
class _WorkerData {
  final String name;
  final String phone;
  final String category;
  final List<String> skills;
  final String experience;
  final String location;
  final String about;
  final double rating;
  final int completedJobs;
  final int dailyRate;
  final bool available;
  final String education;
  final List<String> languages;
  final String idVerified;

  const _WorkerData({
    required this.name,
    required this.phone,
    required this.category,
    required this.skills,
    required this.experience,
    required this.location,
    required this.about,
    required this.rating,
    required this.completedJobs,
    required this.dailyRate,
    required this.available,
    required this.education,
    required this.languages,
    required this.idVerified,
  });

  factory _WorkerData.fromMap(Map<String, dynamic> d) => _WorkerData(
        name: d['name'] ?? d['workerName'] ?? 'Unknown',
        phone: d['phone'] ?? d['mobile'] ?? '',
        category: d['category'] ?? d['skill'] ?? 'Worker',
        skills: List<String>.from(d['skills'] ?? [d['category'] ?? 'Worker']),
        experience: d['experience'] ?? '1 साल',
        location: d['location'] ?? d['city'] ?? d['area'] ?? 'India',
        about: d['about'] ?? d['bio'] ?? '',
        rating: (d['rating'] ?? 4.0).toDouble(),
        completedJobs: d['completedJobs'] ?? d['jobsDone'] ?? 0,
        dailyRate: d['dailyRate'] ?? d['rate'] ?? 500,
        available: d['available'] ?? d['isAvailable'] ?? true,
        education: d['education'] ?? '10th Pass',
        languages: List<String>.from(d['languages'] ?? ['Hindi']),
        idVerified: d['idVerified'] ?? d['verified'] ?? 'Aadhaar',
      );

  // Demo fallback
  static _WorkerData demo(String workerId) => _WorkerData(
        name: 'Ramesh Kumar',
        phone: '9876543210',
        category: 'Construction',
        skills: ['Masonry', 'Plastering', 'Tile Work', 'Painting'],
        experience: '5 साल',
        location: 'Ranchi, Jharkhand',
        about:
            'मैं एक अनुभवी Construction Worker हूँ। Quality काम और समय पर delivery मेरी पहचान है।',
        rating: 4.5,
        completedJobs: 127,
        dailyRate: 800,
        available: true,
        education: '10th Pass',
        languages: ['Hindi', 'Bhojpuri', 'English'],
        idVerified: 'Aadhaar Verified',
      );
}

// ============================================================
// 1. WorkerCvScreen — Full Page
// ============================================================
class WorkerCvScreen extends StatefulWidget {
  final String workerId;
  final Map<String, dynamic>? initialData;

  const WorkerCvScreen({
    Key? key,
    required this.workerId,
    this.initialData,
  }) : super(key: key);

  @override
  State<WorkerCvScreen> createState() => _WorkerCvScreenState();
}

class _WorkerCvScreenState extends State<WorkerCvScreen> {
  final _db = FirebaseFirestore.instance;
  final _repaintKey = GlobalKey();
  _WorkerData? _worker;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    try {
      if (widget.initialData != null) {
        setState(() {
          _worker = _WorkerData.fromMap(widget.initialData!);
          _loading = false;
        });
        return;
      }
      final doc =
          await _db.collection('workers').doc(widget.workerId).get();
      if (doc.exists) {
        setState(() {
          _worker = _WorkerData.fromMap(
              doc.data() as Map<String, dynamic>);
          _loading = false;
        });
      } else {
        setState(() {
          _worker = _WorkerData.demo(widget.workerId);
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _worker = _WorkerData.demo(widget.workerId);
        _loading = false;
      });
    }
  }

  // Capture CV as image bytes
  Future<Uint8List?> _captureCvImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // Share CV as image
  Future<void> _shareCvImage() async {
    if (_worker == null) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureCvImage();
      if (bytes != null) {
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'image/png', name: 'cv_${widget.workerId}.png')],
          text:
              '${_worker!.name} — Kaam Dhanda Worker Profile\n⭐ ${_worker!.rating} | ${_worker!.completedJobs} Jobs | ₹${_worker!.dailyRate}/day',
        );
      } else {
        _shareText();
      }
    } catch (_) {
      _shareText();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  // Share CV as text
  void _shareText() {
    if (_worker == null) return;
    final w = _worker!;
    final text = '''
👷 *${w.name}* — Kaam Dhanda Worker

📋 *Profile*
• Skill: ${w.category}
• Experience: ${w.experience}
• Daily Rate: ₹${w.dailyRate}/day
• Location: ${w.location}
• Rating: ⭐ ${w.rating} (${w.completedJobs} jobs)
• Availability: ${w.available ? "✅ Available" : "🔴 Busy"}

🔧 *Skills:* ${w.skills.join(', ')}
🗣️ *Languages:* ${w.languages.join(', ')}
🎓 *Education:* ${w.education}
🆔 *Verified:* ${w.idVerified}

${w.about.isNotEmpty ? '📝 *About:*\n${w.about}\n' : ''}
📲 Kaam Dhanda App पर connect करें
''';
    Share.share(text, subject: '${w.name} — Worker Profile');
  }

  // Share on WhatsApp
  Future<void> _shareWhatsApp() async {
    if (_worker == null) return;
    final w = _worker!;
    final msg = Uri.encodeComponent(
      '👷 *${w.name}* — Kaam Dhanda Worker\n\n'
      '🔧 Skill: ${w.category}\n'
      '📍 Location: ${w.location}\n'
      '⭐ Rating: ${w.rating} (${w.completedJobs} jobs done)\n'
      '💰 Daily Rate: ₹${w.dailyRate}/day\n'
      '✅ Available: ${w.available ? "हाँ" : "नहीं"}\n\n'
      'Skills: ${w.skills.join(", ")}\n\n'
      'Kaam Dhanda App पर profile देखें।',
    );
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Copy profile link
  void _copyLink() {
    Clipboard.setData(
      ClipboardData(
          text: 'https://kamdhanda.in/worker/${widget.workerId}'),
    );
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Profile link copy हो गया!'),
        backgroundColor: const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Copy CV text to clipboard
  void _copyCvText() {
    if (_worker == null) return;
    final w = _worker!;
    Clipboard.setData(ClipboardData(
      text: '${w.name} | ${w.category} | ${w.experience} Experience | '
          '₹${w.dailyRate}/day | ⭐${w.rating} | ${w.location} | '
          'Skills: ${w.skills.join(", ")} | '
          'Languages: ${w.languages.join(", ")} | '
          '${w.idVerified}',
    ));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 CV Text copy हो गया!'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          '📄 CV / Profile Card',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          if (!_loading && _worker != null)
            IconButton(
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.share_outlined),
              onPressed: _sharing ? null : _shareCvImage,
              tooltip: 'Share CV',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _worker == null
              ? const Center(child: Text('Profile नहीं मिला'))
              : Column(
                  children: [
                    // CV Preview (scrollable)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Capture boundary
                            RepaintBoundary(
                              key: _repaintKey,
                              child: WorkerCvCard(worker: _worker!),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons
                    _ActionBar(
                      onShareImage: _shareCvImage,
                      onShareWhatsApp: _shareWhatsApp,
                      onCopyLink: _copyLink,
                      onCopyText: _copyCvText,
                      sharing: _sharing,
                    ),
                  ],
                ),
    );
  }
}

// ============================================================
// WorkerCvCard — The actual CV card (shareable)
// ============================================================
class WorkerCvCard extends StatelessWidget {
  final _WorkerData worker;

  const WorkerCvCard({Key? key, required this.worker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          // Header (blue gradient)
          _CvHeader(worker: worker),

          // Stats Row
          _StatsRow(worker: worker),

          const Divider(height: 1),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skills
                _CvSection(
                  icon: '🔧',
                  title: 'Skills',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: worker.skills
                        .map((s) => _SkillChip(s))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Experience & Rate
                _CvSection(
                  icon: '💼',
                  title: 'Experience & Rate',
                  child: Row(
                    children: [
                      _InfoPill(
                          icon: '⏱️',
                          label: worker.experience,
                          color: Colors.purple),
                      const SizedBox(width: 10),
                      _InfoPill(
                          icon: '💰',
                          label: '₹${worker.dailyRate}/day',
                          color: Colors.green.shade700),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Languages & Education
                _CvSection(
                  icon: '🗣️',
                  title: 'Languages',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: worker.languages
                        .map((l) => _SkillChip(l,
                            color: Colors.blue.shade700))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                _CvSection(
                  icon: '🎓',
                  title: 'Education',
                  child: Text(
                    worker.education,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // About
                if (worker.about.isNotEmpty) ...[
                  _CvSection(
                    icon: '📝',
                    title: 'About',
                    child: Text(
                      worker.about,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Verification
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Text('🆔',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        worker.idVerified,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.verified,
                          color: Colors.green.shade700, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer
          _CvFooter(),
        ],
      ),
    );
  }
}

class _CvHeader extends StatelessWidget {
  final _WorkerData worker;

  const _CvHeader({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              worker.name.isNotEmpty
                  ? worker.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  worker.category,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('📍',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        worker.location,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Availability badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: worker.available
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    worker.available ? '✅ उपलब्ध हूँ' : '🔴 Busy हूँ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _WorkerData worker;

  const _StatsRow({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FF),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _StatItem('⭐', '${worker.rating}', 'Rating'),
          _Divider(),
          _StatItem(
              '✅', '${worker.completedJobs}', 'Jobs Done'),
          _Divider(),
          _StatItem('💰', '₹${worker.dailyRate}', 'Per Day'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatItem(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }
}

class _CvSection extends StatelessWidget {
  final String icon;
  final String title;
  final Widget child;

  const _CvSection(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _SkillChip(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1565C0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, color: c, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _InfoPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CvFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: const [
          Text(
            '🌾 Kaam Dhanda',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
                fontSize: 14),
          ),
          SizedBox(height: 2),
          Text(
            'www.kamdhanda.in',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Action Bar at bottom
// ============================================================
class _ActionBar extends StatelessWidget {
  final VoidCallback onShareImage;
  final VoidCallback onShareWhatsApp;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyText;
  final bool sharing;

  const _ActionBar({
    required this.onShareImage,
    required this.onShareWhatsApp,
    required this.onCopyLink,
    required this.onCopyText,
    required this.sharing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary share as image
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: sharing ? null : onShareImage,
              icon: sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share_outlined),
              label: Text(
                sharing ? 'Sharing...' : 'CV Share करें (Image)',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary actions row
          Row(
            children: [
              Expanded(
                child: _SecondaryBtn(
                  icon: '💬',
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: onShareWhatsApp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryBtn(
                  icon: '🔗',
                  label: 'Link Copy',
                  color: const Color(0xFF6A1B9A),
                  onTap: onCopyLink,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryBtn(
                  icon: '📋',
                  label: 'Text Copy',
                  color: const Color(0xFFE65100),
                  onTap: onCopyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 2. CvShareButton — compact button for AppBar / Profile page
// ============================================================
class CvShareButton extends StatelessWidget {
  final String workerId;
  final Map<String, dynamic>? workerData;

  const CvShareButton({
    Key? key,
    required this.workerId,
    this.workerData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerCvScreen(
              workerId: workerId,
              initialData: workerData,
            ),
          ),
        );
      },
      icon: const Icon(Icons.document_scanner_outlined),
      tooltip: 'CV / Profile Share',
    );
  }
}

// ============================================================
// 3. Quick CV Share (no navigation — share text directly)
// ============================================================
Future<void> shareWorkerProfileText(Map<String, dynamic> workerData) async {
  final w = _WorkerData.fromMap(workerData);
  final text = '👷 *${w.name}* — Kaam Dhanda Worker\n\n'
      '🔧 ${w.category} | ⏱️ ${w.experience} Experience\n'
      '💰 ₹${w.dailyRate}/day | ⭐ ${w.rating} Rating\n'
      '📍 ${w.location}\n'
      '✅ ${w.completedJobs} Jobs Completed\n\n'
      'Skills: ${w.skills.join(", ")}\n'
      'Languages: ${w.languages.join(", ")}\n'
      '🆔 ${w.idVerified}\n\n'
      '${w.about.isNotEmpty ? w.about + "\n\n" : ""}'
      '📲 www.kamdhanda.in';
  await Share.share(text, subject: '${w.name} — Worker Profile');
}
