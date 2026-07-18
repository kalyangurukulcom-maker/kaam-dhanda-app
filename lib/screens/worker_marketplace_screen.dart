import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerMarketplaceScreen extends StatefulWidget {
  const WorkerMarketplaceScreen({super.key});
  @override
  State<WorkerMarketplaceScreen> createState() => _WorkerMarketplaceScreenState();
}

class _WorkerMarketplaceScreenState extends State<WorkerMarketplaceScreen> {
  final _search = TextEditingController();
  String _searchText = '';
  String _catFilter = 'सभी';
  bool _availableOnly = false;

  // Website ke hire.html se match karte categories
  static const _cats = ['सभी','मजदूर','ड्राइवर','इलेक्ट्रीशियन','प्लम्बर','सिक्योरिटी','कारपेंटर','पेंटर','मिस्त्री','कुक','डिलीवरी','फैक्ट्री','अन्य'];
  static const _blue = Color(0xFF1565C0);

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('workers')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // Website jobType mein emojis hoti hain like "🚗 ड्राइवर (Driver)" — smart match karo
  bool _matchCategory(String storedCat, String filter) {
    if (filter == 'सभी') return true;
    final c = storedCat.toLowerCase();
    final f = filter.toLowerCase();
    if (c.contains(f)) return true;
    const catMap = <String, List<String>>{
      'मजदूर': ['mazdoor','labour','labor','helper','लेबर','मजदूर','bar bending','rod'],
      'ड्राइवर': ['driver','ड्राइवर','cab','truck','driving'],
      'इलेक्ट्रीशियन': ['electrician','electric','इलेक्ट्रीशियन','ac mechanic','ac tech'],
      'प्लम्बर': ['plumber','प्लम्बर','plumbing','pipe'],
      'सिक्योरिटी': ['security','guard','सिक्योरिटी','watchman','चौकीदार'],
      'कारपेंटर': ['carpenter','कारपेंटर','wood','furniture'],
      'पेंटर': ['painter','पेंटर','paint'],
      'मिस्त्री': ['mason','मिस्त्री','rajmistry','tiles','bricklayer'],
      'कुक': ['cook','कुक','chef','kitchen','restaurant','रसोइया'],
      'डिलीवरी': ['delivery','डिलीवरी','courier','bike'],
      'फैक्ट्री': ['factory','फैक्ट्री','packing','manufacturing','welder','tailor'],
      'अन्य': ['other','अन्य','barber','नाई','darzi','embroidery'],
    };
    final keys = catMap[filter] ?? [];
    return keys.any((k) => c.contains(k));
  }

  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      // skills ya jobType (website worker.html jobType save karta hai)
      final skills = (data['skills'] ?? data['skill'] ?? data['jobType'] ?? '').toString().toLowerCase();
      // district (website worker.html district save karta hai), city ya location bhi
      final city = (data['district'] ?? data['city'] ?? data['location'] ?? '').toString().toLowerCase();
      final cat = (data['category'] ?? data['jobType'] ?? '').toString();
      final avail = data['available'] == true || data['available'] == 'true' || data['availability'] == 'available';

      if (_searchText.isNotEmpty && !name.contains(_searchText) && !skills.contains(_searchText) && !city.contains(_searchText)) return false;
      if (!_matchCategory(cat, _catFilter)) return false;
      if (_availableOnly && !avail) return false;
      return true;
    }).toList();
  }

  void _whatsapp(Map d, String name) async {
    // whatsapp field pehle check karo, phir phone
    final waNum = (d['whatsapp'] ?? d['phone'] ?? '').toString();
    if (waNum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact number nahi hai')));
      return;
    }
    final msg = Uri.encodeComponent('Namaste $name ji! Mujhe aapki services chahiye. KaamDhanda.in se contact kar raha hoon.');
    final cleanNum = waNum.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/91$cleanNum?text=$msg';
    if (await canLaunchUrl(Uri.parse(url))) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _call(String phone) async {
    final cleanNum = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'tel:$cleanNum';
    if (await canLaunchUrl(Uri.parse(url))) launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(children: [
        Container(
          color: _blue,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(children: [
                  const Text('मजदूर ढूंढें', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Available Today toggle
                  GestureDetector(
                    onTap: () => setState(() => _availableOnly = !_availableOnly),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _availableOnly ? Colors.green : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_availableOnly ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        const Text('Available आज', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Naam, skill ya city se dhundho...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchText.isNotEmpty ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () { _search.clear(); setState(() => _searchText = ''); }) : null,
                    filled: true, fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
                ),
              ),
            ]),
          ),
        ),
        Container(
          color: Colors.white, height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _cats.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_cats[i], style: TextStyle(
                  fontSize: 12,
                  color: _catFilter == _cats[i] ? Colors.white : Colors.black87,
                  fontWeight: _catFilter == _cats[i] ? FontWeight.bold : FontWeight.normal,
                )),
                selected: _catFilter == _cats[i],
                onSelected: (_) => setState(() => _catFilter = _cats[i]),
                selectedColor: _blue, backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _blue));
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = _filter(snap.data?.docs ?? []);
              if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Koi worker nahi mila', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                const SizedBox(height: 4),
                Text('Filter change karke try karein', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                if (_searchText.isNotEmpty || _catFilter != 'सभी' || _availableOnly) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () { _search.clear(); setState(() { _searchText = ''; _catFilter = 'सभी'; _availableOnly = false; }); },
                    child: const Text('Filter reset karo')),
                ],
              ]));
              return ListView.builder(
                padding: const EdgeInsets.all(12), itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final name = (d['name'] ?? 'Worker').toString();
                  final phone = (d['phone'] ?? '').toString();
                  final waNum = (d['whatsapp'] ?? phone).toString();
                  final skills = (d['skills'] ?? d['skill'] ?? '').toString();
                  // District prefer karo (website worker.html mein district save hota hai)
                  final city = (d['district'] ?? d['city'] ?? d['location'] ?? '').toString();
                  final cat = (d['category'] ?? d['jobType'] ?? '').toString();
                  // Category display ke liye emojis strip karo
                  final catDisplay = cat.replaceAll(RegExp(r'[\u{1F300}-\u{1FFFF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '').trim();
                  final exp = (d['experience'] ?? '').toString();
                  final rating = ((d['rating'] ?? 0) as num).toDouble();
                  final ratingCount = (d['ratingCount'] ?? 0);
                  final avail = d['available'] == true || d['available'] == 'true' || d['availability'] == 'available';
                  final isNew = d['createdAt'] != null &&
                      DateTime.now().difference((d['createdAt'] as Timestamp).toDate()).inDays <= 7;
                  final initials = name.isNotEmpty ? name[0].toUpperCase() : 'W';

                  return Card(
                    elevation: 2, margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 28, backgroundColor: _blue,
                          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: avail ? Colors.green[50] : Colors.grey[100],
                                border: Border.all(color: avail ? Colors.green : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(avail ? '✅ Available' : 'Busy',
                                style: TextStyle(color: avail ? Colors.green[700] : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          const SizedBox(height: 5),
                          Row(children: [
                            if (catDisplay.isNotEmpty && catDisplay.length > 1) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(catDisplay.length > 22 ? catDisplay.substring(0, 22) : catDisplay,
                                style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange[50], border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(4)),
                                child: const Text('NEW', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
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
                          const Icon(Icons.work_history, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('अनुभव: $exp', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ]),
                      ],
                      if (rating > 0) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          ...List.generate(5, (j) => Icon(j < rating.round() ? Icons.star : Icons.star_border, size: 16, color: Colors.amber)),
                          const SizedBox(width: 4),
                          Text('${rating.toStringAsFixed(1)} ($ratingCount)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      Row(children: [
                        if (phone.isNotEmpty) ...[
                          Expanded(child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text('Call करें', style: TextStyle(fontSize: 13)),
                            onPressed: () => _call(phone),
                            style: OutlinedButton.styleFrom(foregroundColor: _blue, side: BorderSide(color: _blue), padding: const EdgeInsets.symmetric(vertical: 8)),
                          )),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: ElevatedButton.icon(
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('WhatsApp Hire', style: TextStyle(fontSize: 13)),
                          onPressed: waNum.isNotEmpty ? () => _whatsapp(d, name) : null,
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
