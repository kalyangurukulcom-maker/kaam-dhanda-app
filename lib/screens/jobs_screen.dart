import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class JobsScreen extends StatefulWidget {
  final Map<String,dynamic>? userArgs;
  const JobsScreen({super.key, this.userArgs});
  @override State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String _filter = 'All';
  final _search = TextEditingController();
  String _searchText = '';
  static const _blue = Color(0xFF1565C0);
  static const _cats = ['All','Urgent','Plumber','Electrician','Carpenter','Driver','Cook','Security','Helper','Other'];

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance.collection('jobs').orderBy('postedAt', descending: true).snapshots();

  bool _isUrgent(Map d) {
    if (d['urgent'] == true) return true;
    if (d['postedAt'] == null) return false;
    final dt = (d['postedAt'] as Timestamp).toDate();
    return DateTime.now().difference(dt).inHours < 24;
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    return docs.where((d) {
      final data = d.data() as Map<String,dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final loc = (data['location'] ?? data['city'] ?? '').toString().toLowerCase();
      final cat = (data['category'] ?? '').toString().toLowerCase();
      if (_searchText.isNotEmpty && !title.contains(_searchText) && !loc.contains(_searchText) && !cat.contains(_searchText)) return false;
      if (_filter == 'Urgent') return _isUrgent(data);
      if (_filter != 'All') return cat.contains(_filter.toLowerCase());
      return true;
    }).toList();
  }

  void _applyWhatsApp(Map d) async {
    final phone = d['phone'] ?? d['contactPhone'] ?? '';
    if (phone.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact number nahi hai'))); return; }
    final title = d['title'] ?? 'Job';
    final msg = Uri.encodeComponent('Namaste! Aapke "$title" job ke liye apply karna chahta hoon. KaamDhanda.in se dekha.');
    final url = 'https://wa.me/91${phone.replaceAll(RegExp(r"[^0-9]"),"")}}?text=$msg';
    if (await canLaunchUrl(Uri.parse(url))) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
    if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
    if (diff.inDays < 7) return '${diff.inDays} din pehle';
    return '${(diff.inDays/7).floor()} hafte pehle';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Naukri Dhundho', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Column(children: [
        Container(color: _blue, padding: const EdgeInsets.fromLTRB(12,0,12,12),
          child: TextField(
            controller: _search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Job title ya location se dhundho...',
              hintStyle: TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _searchText.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () { _search.clear(); setState(() => _searchText = ''); }) : null,
              filled: true, fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
          ),
        ),
        Container(color: Colors.white, height: 46,
          child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _cats.length,
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_cats[i], style: TextStyle(fontSize: 12, color: _filter==_cats[i] ? Colors.white : Colors.black87, fontWeight: _filter==_cats[i] ? FontWeight.bold : FontWeight.normal)),
                selected: _filter==_cats[i], onSelected: (_) => setState(() => _filter=_cats[i]),
                selectedColor: _cats[i]=='Urgent' ? Colors.red : _blue,
                backgroundColor: _cats[i]=='Urgent' ? Colors.red[50] : Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 4),
              )),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _blue));
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = _filterDocs(snap.data?.docs ?? []);
              if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Koi job nahi mili', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                if (_searchText.isNotEmpty || _filter != 'All') TextButton(
                  onPressed: () { _search.clear(); setState(() { _searchText=''; _filter='All'; }); },
                  child: const Text('Filter reset karo')),
              ]));
              return ListView.builder(
                padding: const EdgeInsets.all(12), itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String,dynamic>;
                  final urgent = _isUrgent(d);
                  final salary = d['salary'] ?? d['salaryRange'] ?? '';
                  final loc = d['location'] ?? d['city'] ?? '';
                  final type = d['type'] ?? d['jobType'] ?? '';
                  final company = d['company'] ?? d['employer'] ?? d['postedBy'] ?? '';
                  final cat = d['category'] ?? '';
                  final desc = d['description'] ?? '';

                  return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: urgent ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                    ),
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            if (urgent) Container(margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(child: Text(d['title'] ?? 'Job', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          ]),
                          if (company.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(company, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ])),
                        if (cat.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(cat, style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.bold))),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 12, runSpacing: 6, children: [
                        if (loc.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(loc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ]),
                        if (salary.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.currency_rupee, size: 14, color: Colors.green[600]),
                          Text(salary, style: TextStyle(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.bold)),
                        ]),
                        if (type.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(type, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ]),
                      ]),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(desc.length > 100 ? desc.substring(0,100) + '...' : desc, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                      const SizedBox(height: 4),
                      Text(_timeAgo(d['postedAt']), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: ElevatedButton.icon(
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('WhatsApp Apply', style: TextStyle(fontSize: 13)),
                          onPressed: () => _applyWhatsApp(d),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        )),
                      ]),
                    ])),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}