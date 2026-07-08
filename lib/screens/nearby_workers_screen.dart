// ============================================================
// Feature #121: Nearby Workers Screen
// File: lib/screens/nearby_workers_screen.dart
// Kaam Dhanda App — Flutter
//
// pubspec.yaml mein add karo:
//   geolocator: ^10.1.0
//   url_launcher: ^6.2.5
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyWorkersScreen extends StatefulWidget {
  const NearbyWorkersScreen({Key? key}) : super(key: key);

  @override
  State<NearbyWorkersScreen> createState() => _NearbyWorkersScreenState();
}

class _NearbyWorkersScreenState extends State<NearbyWorkersScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Position? _userPos;
  bool _locLoading = true;
  bool _dataLoading = false;
  String _locError = '';

  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filtered = [];
  String _activeCategory = 'सभी';
  double _maxDistanceKm = 10.0; // default radius

  static const List<String> _categories = [
    'सभी', 'इलेक्ट्रीशियन', 'प्लम्बर', 'कारपेंटर',
    'पेंटर', 'मजदूर', 'ड्राइवर', 'सिक्योरिटी', 'Cook', 'Welder',
  ];

  static const List<Map<String, dynamic>> _radiusOptions = [
    {'label': '2 km', 'value': 2.0},
    {'label': '5 km', 'value': 5.0},
    {'label': '10 km', 'value': 10.0},
    {'label': '20 km', 'value': 20.0},
    {'label': 'सभी', 'value': 9999.0},
  ];

  // Demo workers with geo-coords near Ranchi
  static final List<Map<String, dynamic>> _demoWorkers = [
    {
      'id': 'n1', 'name': 'राजेश कुमार', 'category': 'इलेक्ट्रीशियन',
      'emoji': '⚡', 'city': 'रांची', 'rating': 4.8,
      'dailyRate': 800, 'available': true, 'phone': '9876543210',
      'verified': true, 'lat': 23.3441, 'lng': 85.3096,
      'experience': '5 साल', 'completedJobs': 142,
    },
    {
      'id': 'n2', 'name': 'सुनील मिस्त्री', 'category': 'प्लम्बर',
      'emoji': '🔧', 'city': 'रांची', 'rating': 4.5,
      'dailyRate': 700, 'available': true, 'phone': '9876543211',
      'verified': true, 'lat': 23.3500, 'lng': 85.3200,
      'experience': '3 साल', 'completedJobs': 89,
    },
    {
      'id': 'n3', 'name': 'मोहन कारपेंटर', 'category': 'कारपेंटर',
      'emoji': '🪵', 'city': 'रांची', 'rating': 4.7,
      'dailyRate': 900, 'available': false, 'phone': '9876543212',
      'verified': true, 'lat': 23.3380, 'lng': 85.3150,
      'experience': '7 साल', 'completedJobs': 203,
    },
    {
      'id': 'n4', 'name': 'रमेश पेंटर', 'category': 'पेंटर',
      'emoji': '🎨', 'city': 'रांची', 'rating': 4.3,
      'dailyRate': 650, 'available': true, 'phone': '9876543213',
      'verified': false, 'lat': 23.3600, 'lng': 85.3050,
      'experience': '4 साल', 'completedJobs': 67,
    },
    {
      'id': 'n5', 'name': 'अजय ड्राइवर', 'category': 'ड्राइवर',
      'emoji': '🚗', 'city': 'रांची', 'rating': 4.9,
      'dailyRate': 1000, 'available': true, 'phone': '9876543214',
      'verified': true, 'lat': 23.3420, 'lng': 85.3300,
      'experience': '6 साल', 'completedJobs': 318,
    },
    {
      'id': 'n6', 'name': 'प्रकाश वेल्डर', 'category': 'Welder',
      'emoji': '🔩', 'city': 'रांची', 'rating': 4.6,
      'dailyRate': 950, 'available': true, 'phone': '9876543215',
      'verified': true, 'lat': 23.3550, 'lng': 85.3250,
      'experience': '8 साल', 'completedJobs': 177,
    },
    {
      'id': 'n7', 'name': 'गीता Cook', 'category': 'Cook',
      'emoji': '🍽️', 'city': 'रांची', 'rating': 4.7,
      'dailyRate': 750, 'available': true, 'phone': '9876543216',
      'verified': true, 'lat': 23.3460, 'lng': 85.3180,
      'experience': '5 साल', 'completedJobs': 124,
    },
    {
      'id': 'n8', 'name': 'संजय मजदूर', 'category': 'मजदूर',
      'emoji': '🏗️', 'city': 'रांची', 'rating': 4.2,
      'dailyRate': 500, 'available': true, 'phone': '9876543217',
      'verified': false, 'lat': 23.3490, 'lng': 85.3120,
      'experience': '2 साल', 'completedJobs': 45,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _locLoading = true;
      _locError = '';
    });
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _locError = 'Location सेवा बंद है। चालू करें।';
          _locLoading = false;
        });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _locError = 'Location permission नहीं मिली।';
          _locLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _userPos = pos;
        _locLoading = false;
      });
      _loadWorkers();
    } catch (e) {
      setState(() {
        _locError = 'Location नहीं मिली: ${e.toString()}';
        _locLoading = false;
      });
      // Load demo data anyway
      _loadWorkers();
    }
  }

  Future<void> _loadWorkers() async {
    setState(() => _dataLoading = true);
    try {
      final snap = await _db
          .collection('workers')
          .where('isActive', isEqualTo: true)
          .limit(80)
          .get();

      if (snap.docs.isNotEmpty) {
        _allWorkers = snap.docs
            .map((d) => {...d.data(), 'id': d.id})
            .where((w) => w['lat'] != null && w['lng'] != null)
            .toList();
      }
    } catch (_) {}

    if (_allWorkers.isEmpty) _allWorkers = _demoWorkers;

    // Calculate distances
    if (_userPos != null) {
      for (final w in _allWorkers) {
        final lat = (w['lat'] as num?)?.toDouble();
        final lng = (w['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          w['distanceKm'] = _haversine(
            _userPos!.latitude, _userPos!.longitude, lat, lng);
        }
      }
      _allWorkers.sort((a, b) =>
          ((a['distanceKm'] as double?) ?? 9999)
              .compareTo((b['distanceKm'] as double?) ?? 9999));
    } else {
      // No GPS — assign random demo distances
      final rng = math.Random(42);
      for (final w in _allWorkers) {
        w['distanceKm'] = 0.5 + rng.nextDouble() * 9;
      }
      _allWorkers.sort((a, b) =>
          (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    }

    _applyFilters();
    setState(() => _dataLoading = false);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_allWorkers);

    if (_activeCategory != 'सभी') {
      list = list
          .where((w) => (w['category'] as String? ?? '') == _activeCategory)
          .toList();
    }

    list = list
        .where((w) =>
            ((w['distanceKm'] as double?) ?? 9999) <= _maxDistanceKm)
        .toList();

    setState(() => _filtered = list);
  }

  String _distLabel(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📍 पास के कारीगर',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (_userPos != null)
              Text(
                'आपकी location मिल गई ✅',
                style:
                    const TextStyle(fontSize: 11, color: Colors.white70),
              )
            else if (_locError.isNotEmpty)
              const Text('Demo data दिखाया जा रहा है',
                  style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Location refresh',
            onPressed: _getLocation,
          ),
        ],
      ),
      body: _locLoading
          ? _buildLocLoading()
          : Column(
              children: [
                // Radius + category filters
                _buildFilters(),
                // Content
                Expanded(
                  child: _dataLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF1565C0)))
                      : _buildContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildLocLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
                color: Color(0xFF1565C0), strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          const Text('📍 आपकी location ढूंढी जा रही है...',
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text('पास के कारीगर अभी दिखेंगे',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Radius selector
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _radiusOptions.length,
              itemBuilder: (_, i) {
                final opt = _radiusOptions[i];
                final active = _maxDistanceKm == opt['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() =>
                        _maxDistanceKm = opt['value'] as double);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFE53935)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active)
                          const Text('📍 ',
                              style: TextStyle(fontSize: 11)),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: active ? Colors.white : Colors.black87,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Category chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final active = _activeCategory == _categories[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeCategory = _categories[i]);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      _categories[i],
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            active ? Colors.white : Colors.black87,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_locError.isNotEmpty && _userPos == null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_locError,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800)),
                ),
                TextButton(
                  onPressed: _getLocation,
                  child: const Text('Retry',
                      style: TextStyle(
                          color: Color(0xFF1565C0), fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      );
    }
    return _buildList();
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              '${_maxDistanceKm.toInt()} km के अंदर कोई नहीं मिला',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _maxDistanceKm = 9999);
                _applyFilters();
              },
              child: const Text('Range बढ़ाएं',
                  style: TextStyle(color: Color(0xFF1565C0))),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkers,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
        itemCount: _filtered.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${_filtered.length} कारीगर मिले — ${_maxDistanceKm >= 9999 ? "सभी range" : "${_maxDistanceKm.toInt()} km के अंदर"}',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
            );
          }
          final w = _filtered[i - 1];
          return _NearbyCard(
            worker: w,
            distLabel: _distLabel(w['distanceKm'] as double?),
            onCall: () async {
              final uri = Uri.parse('tel:${w['phone']}');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
            onWhatsApp: () async {
              final uri = Uri.parse(
                  'https://wa.me/91${w['phone']}?text=नमस्ते, मुझे ${w['category']} चाहिए');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          );
        },
      ),
    );
  }
}

// ---- Nearby Worker Card ----
class _NearbyCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final String distLabel;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _NearbyCard({
    required this.worker,
    required this.distLabel,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (worker['rating'] as num? ?? 0).toDouble();
    final available = worker['available'] as bool? ?? false;
    final verified = worker['verified'] as bool? ?? false;
    final distKm = worker['distanceKm'] as double?;

    // Distance color: green < 2km, orange < 5km, red otherwise
    Color distColor = Colors.red.shade600;
    if (distKm != null) {
      if (distKm < 2) distColor = const Color(0xFF43A047);
      else if (distKm < 5) distColor = const Color(0xFFFF8F00);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + availability dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      const Color(0xFF1565C0).withOpacity(0.1),
                  child: Text(
                    worker['emoji'] ?? '👷',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                if (available)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          worker['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Distance badge
                      if (distLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: distColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: distColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📍',
                                  style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 2),
                              Text(
                                distLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: distColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          worker['category'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (verified)
                        const Text('✅',
                            style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFC107), size: 13),
                      Text(
                        ' ${rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFC107)),
                      ),
                      Text(
                        '  •  ${worker['experience'] ?? ''}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600),
                      ),
                      Text(
                        '  •  ₹${worker['dailyRate']}/दिन',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.call, size: 14),
                          label: const Text('Call',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1565C0),
                            side: const BorderSide(
                                color: Color(0xFF1565C0)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onWhatsApp,
                          icon: const Text('💬',
                              style: TextStyle(fontSize: 14)),
                          label: const Text('WhatsApp',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
