import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String workerId;
  const WorkerProfileScreen({super.key, required this.workerId});
  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _db = FirebaseFirestore.instance;
  Map<String, dynamic>? _worker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    setState(() => _loading = true);
    try {
      final doc = await _db.collection('workers').doc(widget.workerId).get();
      if (doc.exists) {
        _worker = {...doc.data()!, 'id': doc.id};
      }
    } catch (e) {
      _worker = null;
    }
    setState(() => _loading = false);
  }

  String get _jobType => ((_worker?['jobType'] ?? _worker?['category'] ?? '')).toString();
  String get _location => ((_worker?['district'] ?? _worker?['city'] ?? _worker?['location'] ?? '')).toString();
  String get _phone {
    final raw = (_worker?['whatsapp'] ?? _worker?['phone'] ?? '').toString();
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool get _isAvailable {
    final a = _worker?['available'];
    if (a == null) return true;
    if (a is bool) return a;
    return a.toString().toLowerCase() == 'true';
  }

  Future<void> _openWhatsApp() async {
    if (_phone.isEmpty) return;
    final num = _phone.startsWith('91') && _phone.length > 10 ? _phone : '91$_phone';
    final name = _worker?['name'] ?? 'कारीगर';
    final msg = Uri.encodeComponent(
        'नमस्ते $name जी, मुझे आपसे काम के बारे में बात करनी है। (काम धंधा ऐप से)');
    final uri = Uri.parse('https://wa.me/$num?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareProfile() async {
    final name = _worker?['name'] ?? 'कारीगर';
    final jt = _jobType;
    await Share.share(
      '$name — $jt\nकाम धंधा ऐप पर उपलब्ध!\nhttps://kamdhanda.in',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
      );
    }
    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('प्रोफाइल'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('कारीगर नहीं मिला')),
      );
    }

    final name = (_worker!['name'] ?? 'कारीगर').toString();
    final jt = _jobType;
    final loc = _location;
    final rating = double.tryParse(_worker!['rating']?.toString() ?? '') ?? 0;
    final exp = (_worker!['experience'] ?? _worker!['experience_years'] ?? '').toString();
    final verified = _worker!['verified'] == true;
    final pic = (_worker!['profilePic'] ?? _worker!['photo'] ?? '').toString();
    final bio = (_worker!['bio'] ?? _worker!['about'] ?? '').toString();
    final skills = (_worker!['skills'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareProfile,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF1565C0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage:
                          pic.isNotEmpty ? NetworkImage(pic) : null,
                      child: pic.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'क',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isAvailable
                            ? const Color(0xFF25D366)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isAvailable ? '✅ उपलब्ध है' : '⏸ व्यस्त है',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (jt.isNotEmpty)
                            _infoRow(Icons.work, 'काम का प्रकार', jt),
                          if (loc.isNotEmpty)
                            _infoRow(Icons.location_on, 'जगह', loc),
                          if (exp.isNotEmpty)
                            _infoRow(
                                Icons.timeline, 'अनुभव', '$exp साल का अनुभव'),
                          if (rating > 0)
                            _infoRow(Icons.star, 'रेटिंग',
                                '${rating.toStringAsFixed(1)} / 5.0 ⭐'),
                        ],
                      ),
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('अपने बारे में',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(bio,
                                style: const TextStyle(
                                    color: Colors.grey, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('कौशल (Skills)',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills
                                  .map((s) => Chip(
                                        label: Text(s,
                                            style: const TextStyle(
                                                fontSize: 12)),
                                        backgroundColor: const Color(0xFF1565C0)
                                            .withOpacity(0.1),
                                        labelStyle: const TextStyle(
                                            color: Color(0xFF1565C0)),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // WhatsApp button
                  if (_phone.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat, size: 20),
                        label: const Text('WhatsApp पर संपर्क करें',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
