import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerMarketplaceScreen extends StatefulWidget {
  const WorkerMarketplaceScreen({super.key});
  @override State<WorkerMarketplaceScreen> createState() => _WorkerMarketplaceScreenState();
}

class _WorkerMarketplaceScreenState extends State<WorkerMarketplaceScreen> {
  final _search = TextEditingController();
  String _searchText = '';
  String _catFilter = 'All';
  bool _availableOnly = false;

  static const _cats = ['All','Plumber','Electrician','Carpenter','Painter','Mason','Driver','Cook','Security','Helper','Other'];
  static const _blue = Color(0xFF1565C0);

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance.collection('workers').orderBy('createdAt', descending: true).snapshots();

  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    return docs.where((d) {
      final data = d.data() as Map<String,dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final skills = (data['skills'] ?? data['skill'] ?? '').toString().toLowerCase();
      final city = (data['city'] ?? data['location'] ?? '').toString().toLowerCase();
      final cat = (data['category'] ?? data['jobType'] ?? '').toString();
      final avail = data['available'] == true || data['available'] == 'true' || data['availability'] == 'available';

      if (_searchText.isNotEmpty && !name.contains(_searchText) && !skills.contains(_searchText) && !city.contains(_searchText)) return false;
      if (_catFilter != 'All' && !cat.toLowerCase().contains(_catFilter.toLowerCase())) return false;
      if (_availableOnly && !avail) return false;
      return true;
    }).toList();
  }

  void _whatsapp(String phone, String name) async {
    final msg = Uri.encodeComponent('Namaste! Mujhe aapki services chahiye. KaamDhanda.in se contact kar raha hoon.\nWorker: $name');
    final url = 'https://wa.me/91${phone.replaceAll(RegExp(r"[^0-9]"),"")}}?text=$msg';
    if (await canLaunchUrl(Uri.parse(url))) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mazdoor Dhundho', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
        actions: [
          IconButton(icon: Icon(_availableOnly ? Icons.toggle_on : Icons.toggle_off, size: 32,
              color: _availableOnly ? Colors.greenAccent : Colors.white70),
            tooltip: 'Available Today',
            onPressed: () => setState(() => _availableOnly = !_availableOnly)),
        ],
      ),
      body: Column(children: [
        // Blue header with search
        Container(color: _blue, padding: const EdgeInsets.fromLTRB(12,0,12,12),
          child: TextField(
            controller: _search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Naam, skill ya city se dhundho...',
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
        // Category filter chips
        Container(color: Colors.white, height: 46,
          child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _cats.length,
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_cats[i], style: TextStyle(fontSize: 12, color: _catFilter == _cats[i] ? Colors.white : Colors.black87, fontWeight: _catFilter == _cats[i] ? FontWeight.bold : FontWeight.normal)),
                selected: _catFilter == _cats[i],
                onSelected: (_) => setState(() => _catFilter = _cats[i]),
                selectedColor: _blue, backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 4),
              )),
          ),
        ),
        const Divider(height: 1),
        // Workers list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = _filter(snap.data?.docs ?? []);
              if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Koi worker nahi mila', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                if (_searchText.isNotEmpty || _catFilter != 'All' || _availableOnly) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: () { _search.clear(); setState(() { _searchText=''; _catFilter='All'; _availableOnly=false; }); }, child: const Text('Filter reset karo')),
                ],
              ]));
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String,dynamic>;
                  final name = d['name'] ?? 'Worker';
                  final phone = d['phone'] ?? '';
                  final skills = d['skills'] ?? d['skill'] ?? '';
                  final city = d['city'] ?? d['location'] ?? '';
                  final cat = d['category'] ?? d['jobType'] ?? '';
                  final exp = d['experience'] ?? '';
                  final rating = (d['rating'] ?? 0).toDouble();
                  final ratingCount = d['ratingCount'] ?? 0;
                  final avail = d['available'] == true || d['available'] == 'true' || d['availability'] == 'available';
                  final isNew = d['createdAt'] != null && DateTime.now().difference((d['createdAt'] as Timestamp).toDate()).inDays <= 7;
                  final initials = name.isNotEmpty ? name[0].toUpperCase() : 'W';

                  return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        // Avatar
                        CircleAvatar(radius: 28, backgroundColor: _blue,
                          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                            if (avail) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green[50], border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Available', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))),
                            if (!avail) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Busy', style: TextStyle(color: Colors.grey, fontSize: 11))),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            if (cat.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(cat, style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.bold))),
                            if (cat.isNotEmpty && isNew) const SizedBox(width: 4),
                            if (isNew) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange[50], border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(4)),
                              child: const Text('NEW', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
                          ]),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      if (skills.isNotEmpty) Row(children: [
                        const Icon(Icons.build, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(skills, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                      ]),
                      if (city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(city, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ]),
                      ],
                      if (exp.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.work, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Experience: $exp', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ]),
                      ],
                      // Rating
                      if (rating > 0) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          ...List.generate(5, (i) => Icon(i < rating.round() ? Icons.star : Icons.star_border, size: 16, color: Colors.amber)),
                          const SizedBox(width: 4),
                          Text('${rating.toStringAsFixed(1)} ($ratingCount)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      // Action buttons
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          icon: const Icon(Icons.phone, size: 16),
                          label: Text(phone.isNotEmpty ? phone : 'No number', style: const TextStyle(fontSize: 13)),
                          onPressed: phone.isNotEmpty ? () => launchUrl(Uri.parse('tel:$phone')) : null,
                          style: OutlinedButton.styleFrom(foregroundColor: _blue, side: BorderSide(color: _blue), padding: const EdgeInsets.symmetric(vertical: 8)),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('WhatsApp Hire', style: TextStyle(fontSize: 13)),
                          onPressed: phone.isNotEmpty ? () => _whatsapp(phone, name) : null,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
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