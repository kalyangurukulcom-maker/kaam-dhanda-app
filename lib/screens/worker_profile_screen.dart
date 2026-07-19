import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String? workerId;
  const WorkerProfileScreen({super.key, this.workerId});

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
    if (widget.workerId == null || widget.workerId!.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final doc = await _db.collection('workers').doc(widget.workerId).get();
      if (mounted) {
        setState(() {
          _worker = doc.exists ? Map<String, dynamic>.from(doc.data()!) : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWhatsApp() async {
    if (_worker == null) return;
    final rawNum = (_worker!['whatsapp'] ?? _worker!['phone'] ?? '').toString().trim();
    if (rawNum.isEmpty) return;
    final num = rawNum.replaceAll(RegExp(r'[^0-9]'), '');
    final indNum = num.startsWith('91') ? num : '91$num';
    final name = (_worker!['name'] ?? 'कारीगर').toString();
    final msg = Uri.encodeComponent('नमस्ते $name जी, काम धंधा ऐप से संपर्क कर रहे हैं।');
    final url = Uri.parse('https://wa.me/$indNum?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Worker Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _worker == null
              ? const Center(
                  child: Text('प्रोफाइल नहीं मिली',
                      style: TextStyle(color: Colors.grey, fontSize: 16)))
              : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final w = _worker!;
    final name = (w['name'] ?? 'कारीगर').toString();
    final jobType = (w['jobType'] ?? w['category'] ?? 'अन्य').toString();
    final district = (w['district'] ?? w['city'] ?? '').toString();
    final phone = (w['phone'] ?? '').toString();
    final whatsapp = (w['whatsapp'] ?? phone).toString();
    final available = w['available'] == true;
    final experience = (w['experience'] ?? '').toString();
    final salary = (w['salary'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'क',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(jobType,
                      style: const TextStyle(
                          color: Color(0xFF1565C0), fontSize: 15)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: available
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: available
                              ? Colors.green.shade200
                              : Colors.red.shade200),
                    ),
                    child: Text(
                      available ? '✅ उपलब्ध' : '❌ अभी उपलब्ध नहीं',
                      style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('विवरण',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  if (district.isNotEmpty) _InfoTile('📍 जिला/शहर', district),
                  if (phone.isNotEmpty) _InfoTile('📞 फोन', phone),
                  if (whatsapp.isNotEmpty && whatsapp != phone)
                    _InfoTile('💬 WhatsApp', whatsapp),
                  if (experience.isNotEmpty) _InfoTile('🛠️ अनुभव', experience),
                  if (salary.isNotEmpty) _InfoTile('💰 सैलरी', '₹$salary/माह'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (whatsapp.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _openWhatsApp,
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp पर बात करें',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14))),
        ],
      ),
    );
  }
}
