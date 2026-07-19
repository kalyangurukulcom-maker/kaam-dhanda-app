import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'employer_job_management_screen.dart';

class EmployerScreen extends StatefulWidget {
  const EmployerScreen({super.key});

  @override
  State<EmployerScreen> createState() => _EmployerScreenState();
}

class _EmployerScreenState extends State<EmployerScreen> {
  final _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _selectedJobType = 'सब';
  final List<String> _jobTypes = [
    'सब', 'मिस्त्री', 'प्लम्बर', 'इलेक्ट्रीशियन', 'पेंटर',
    'कारपेंटर', 'मजदूर', 'ड्राइवर', 'सिक्योरिटी गार्ड', 'कुक'
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      final snap = await _db.collection('workers').limit(100).get();
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        if (data['available'] == true) list.add(data);
      }
      if (mounted) {
        setState(() {
          _allWorkers = list;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (_selectedJobType == 'सब') {
      _filtered = List.from(_allWorkers);
    } else {
      _filtered = _allWorkers.where((w) {
        final jt = (w['jobType'] ?? w['category'] ?? '').toString();
        return jt == _selectedJobType;
      }).toList();
    }
  }

  Future<void> _callWhatsApp(Map<String, dynamic> w) async {
    final rawNum = (w['whatsapp'] ?? w['phone'] ?? '').toString().trim();
    if (rawNum.isEmpty) return;
    final num = rawNum.replaceAll(RegExp(r'[^0-9]'), '');
    final indNum = num.startsWith('91') ? num : '91$num';
    final name = (w['name'] ?? 'कारीगर').toString();
    final msg = Uri.encodeComponent('नमस्ते $name जी, काम धंधा ऐप से बात करना था।');
    final url = Uri.parse('https://wa.me/$indNum?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('कारीगर ढूंढें',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline, color: Colors.white),
            tooltip: 'मेरी नौकरियां',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployerJobManagementScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _jobTypes.map((jt) {
                  final sel = _selectedJobType == jt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(jt,
                          style: TextStyle(
                              color: sel ? const Color(0xFF1565C0) : Colors.white,
                              fontWeight: FontWeight.w600)),
                      selected: sel,
                      onSelected: (_) {
                        setState(() {
                          _selectedJobType = jt;
                          _applyFilter();
                        });
                      },
                      backgroundColor: Colors.white24,
                      selectedColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('कोई कारीगर उपलब्ध नहीं',
                            style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : RefreshIndicator(
                        onRefresh: _loadWorkers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final w = _filtered[i];
                            final name = (w['name'] ?? 'कारीगर').toString();
                            final jobType =
                                (w['jobType'] ?? w['category'] ?? 'अन्य').toString();
                            final district =
                                (w['district'] ?? w['city'] ?? '').toString();
                            final phone =
                                (w['whatsapp'] ?? w['phone'] ?? '').toString();
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFF1565C0),
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'क',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          Text(jobType,
                                              style: const TextStyle(
                                                  color: Color(0xFF1565C0),
                                                  fontSize: 13)),
                                          if (district.isNotEmpty)
                                            Text('📍 $district',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color:
                                                      Colors.green.shade200),
                                            ),
                                            child: const Text('✅ उपलब्ध',
                                                style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (phone.isNotEmpty)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                        ),
                                        onPressed: () => _callWhatsApp(w),
                                        icon: const Icon(Icons.chat, size: 16),
                                        label: const Text('WhatsApp',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
