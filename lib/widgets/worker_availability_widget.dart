// ============================================================
// Feature #96: Worker Availability Self-Update
// File: lib/widgets/worker_availability_widget.dart
// Kaam Dhanda App — Flutter
//
// 3 components:
//
// 1. AvailabilityToggleCard — home screen card (worker apna status set kare)
//    Usage:
//      AvailabilityToggleCard(workerId: 'W001', workerName: 'Ramesh')
//
// 2. AvailabilityBadge — small badge for listings/profiles
//    Usage:
//      AvailabilityBadge(isAvailable: true)
//      AvailabilityBadge.fromStatus('available')
//
// 3. AvailabilityScreen — full-page availability management
//    Usage:
//      Navigator.push(context, MaterialPageRoute(
//        builder: (_) => AvailabilityScreen(
//          workerId: 'W001',
//          workerName: 'Ramesh Kumar',
//        ),
//      ));
//
// Firestore: workers/{workerId} mein yeh fields update hote hain:
//   - availability: 'available' | 'busy' | 'on_leave'
//   - availabilityNote: String (optional custom note)
//   - availabilityUpdatedAt: Timestamp
//   - nextAvailableDate: String (optional, for busy/leave)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ============================================================
// Availability Status Model
// ============================================================
class AvailabilityStatus {
  static const available = 'available';
  static const busy = 'busy';
  static const onLeave = 'on_leave';

  static String label(String status) {
    switch (status) {
      case available:
        return 'उपलब्ध हूँ';
      case busy:
        return 'Busy हूँ';
      case onLeave:
        return 'छुट्टी पर हूँ';
      default:
        return 'Unknown';
    }
  }

  static String emoji(String status) {
    switch (status) {
      case available:
        return '✅';
      case busy:
        return '🔴';
      case onLeave:
        return '🏖️';
      default:
        return '❓';
    }
  }

  static Color color(String status) {
    switch (status) {
      case available:
        return const Color(0xFF2E7D32);
      case busy:
        return const Color(0xFFC62828);
      case onLeave:
        return const Color(0xFFE65100);
      default:
        return Colors.grey;
    }
  }

  static Color bgColor(String status) {
    switch (status) {
      case available:
        return const Color(0xFFE8F5E9);
      case busy:
        return const Color(0xFFFFEBEE);
      case onLeave:
        return const Color(0xFFFFF3E0);
      default:
        return Colors.grey.shade100;
    }
  }

  static String hint(String status) {
    switch (status) {
      case available:
        return 'नया काम मिल सकता है';
      case busy:
        return 'अभी काम पर हैं';
      case onLeave:
        return 'कुछ दिन बाद उपलब्ध होंगे';
      default:
        return '';
    }
  }
}

// ============================================================
// 1. AvailabilityToggleCard — Home Screen Card
// ============================================================
class AvailabilityToggleCard extends StatefulWidget {
  final String workerId;
  final String workerName;
  final VoidCallback? onTap;

  const AvailabilityToggleCard({
    Key? key,
    required this.workerId,
    required this.workerName,
    this.onTap,
  }) : super(key: key);

  @override
  State<AvailabilityToggleCard> createState() =>
      _AvailabilityToggleCardState();
}

class _AvailabilityToggleCardState extends State<AvailabilityToggleCard>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('workers').doc(widget.workerId).snapshots(),
      builder: (context, snap) {
        String status = AvailabilityStatus.available;
        String note = '';
        String updatedAt = '';

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          status = data['availability'] ?? AvailabilityStatus.available;
          note = data['availabilityNote'] ?? '';
          final ts = data['availabilityUpdatedAt'];
          if (ts != null) {
            final dt = (ts as Timestamp).toDate();
            updatedAt = DateFormat('hh:mm a, dd MMM').format(dt);
          }
        }

        final isAvailable = status == AvailabilityStatus.available;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AvailabilityScreen(
                    workerId: widget.workerId,
                    workerName: widget.workerName,
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AvailabilityStatus.bgColor(status),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AvailabilityStatus.color(status).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AvailabilityStatus.color(status).withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pulsing dot (only when available)
                if (isAvailable)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Transform.scale(
                      scale: _pulse.value,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AvailabilityStatus.color(status),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AvailabilityStatus.color(status)
                                  .withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    AvailabilityStatus.emoji(status),
                    style: const TextStyle(fontSize: 20),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'आपकी Availability: ${AvailabilityStatus.label(status)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AvailabilityStatus.color(status),
                        ),
                      ),
                      Text(
                        note.isNotEmpty
                            ? note
                            : AvailabilityStatus.hint(status),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              AvailabilityStatus.color(status).withOpacity(0.7),
                        ),
                      ),
                      if (updatedAt.isNotEmpty)
                        Text(
                          'Updated: $updatedAt',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black38),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AvailabilityStatus.color(status),
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
// 2. AvailabilityBadge — Small Badge
// ============================================================
class AvailabilityBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const AvailabilityBadge({
    Key? key,
    required this.status,
    this.compact = false,
  }) : super(key: key);

  /// Convenience: from boolean
  factory AvailabilityBadge.fromBool(bool isAvailable) {
    return AvailabilityBadge(
      status: isAvailable
          ? AvailabilityStatus.available
          : AvailabilityStatus.busy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = AvailabilityStatus.color(status);
    final bg = AvailabilityStatus.bgColor(status);
    final emoji = AvailabilityStatus.emoji(status);
    final label = AvailabilityStatus.label(status);

    if (compact) {
      // Dot only
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. AvailabilityScreen — Full Page
// ============================================================
class AvailabilityScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  const AvailabilityScreen({
    Key? key,
    required this.workerId,
    required this.workerName,
  }) : super(key: key);

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final _db = FirebaseFirestore.instance;
  String _currentStatus = AvailabilityStatus.available;
  String _selectedStatus = AvailabilityStatus.available;
  String _note = '';
  String _nextDate = '';
  bool _saving = false;
  bool _loaded = false;

  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final doc =
          await _db.collection('workers').doc(widget.workerId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final status =
            data['availability'] ?? AvailabilityStatus.available;
        final note = data['availabilityNote'] ?? '';
        final nextDate = data['nextAvailableDate'] ?? '';
        setState(() {
          _currentStatus = status;
          _selectedStatus = status;
          _note = note;
          _nextDate = nextDate;
          _noteCtrl.text = note;
          _dateCtrl.text = nextDate;
          _loaded = true;
        });
      } else {
        setState(() {
          _loaded = true;
        });
      }
    } catch (_) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveStatus() async {
    setState(() => _saving = true);
    try {
      await _db.collection('workers').doc(widget.workerId).set(
        {
          'availability': _selectedStatus,
          'availabilityNote': _noteCtrl.text.trim(),
          'availabilityUpdatedAt': FieldValue.serverTimestamp(),
          'nextAvailableDate': _selectedStatus != AvailabilityStatus.available
              ? _dateCtrl.text.trim()
              : '',
        },
        SetOptions(merge: true),
      );

      HapticFeedback.mediumImpact();
      setState(() => _currentStatus = _selectedStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AvailabilityStatus.emoji(_selectedStatus)} Status update हो गया!',
            ),
            backgroundColor: AvailabilityStatus.color(_selectedStatus),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '🔄 Availability Update',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _loaded
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Worker info header
                  _WorkerHeader(
                    name: widget.workerName,
                    currentStatus: _currentStatus,
                  ),
                  const SizedBox(height: 24),

                  // Status options
                  const Text(
                    'अपनी Availability चुनें',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _StatusOption(
                    status: AvailabilityStatus.available,
                    selected: _selectedStatus == AvailabilityStatus.available,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() =>
                          _selectedStatus = AvailabilityStatus.available);
                    },
                  ),
                  const SizedBox(height: 10),
                  _StatusOption(
                    status: AvailabilityStatus.busy,
                    selected: _selectedStatus == AvailabilityStatus.busy,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(
                          () => _selectedStatus = AvailabilityStatus.busy);
                    },
                  ),
                  const SizedBox(height: 10),
                  _StatusOption(
                    status: AvailabilityStatus.onLeave,
                    selected: _selectedStatus == AvailabilityStatus.onLeave,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() =>
                          _selectedStatus = AvailabilityStatus.onLeave);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Optional note
                  const Text(
                    'Note (optional)',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: _selectedStatus ==
                              AvailabilityStatus.available
                          ? 'जैसे: Call करें, तुरंत Join कर सकता हूँ'
                          : _selectedStatus == AvailabilityStatus.busy
                              ? 'जैसे: Project में busy हूँ, 2 हफ्ते बाद Free होऊंगा'
                              : 'जैसे: गांव गया हूँ, 10 दिन बाद वापस',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      counterStyle:
                          const TextStyle(color: Colors.black38, fontSize: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AvailabilityStatus.color(_selectedStatus),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  // Next available date (busy / on_leave)
                  if (_selectedStatus != AvailabilityStatus.available) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'अगली Availability Date',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dateCtrl,
                          decoration: InputDecoration(
                            hintText: 'Date चुनें (optional)',
                            hintStyle:
                                const TextStyle(color: Colors.black38),
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AvailabilityStatus.color(_selectedStatus),
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
                                Text(
                                  AvailabilityStatus.emoji(_selectedStatus),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Status Save करें',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Info box
                  _InfoBox(),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1565C0)),
            ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AvailabilityStatus.color(_selectedStatus),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateCtrl.text = DateFormat('dd MMM yyyy').format(picked);
    }
  }
}

// Worker Header
class _WorkerHeader extends StatelessWidget {
  final String name;
  final String currentStatus;

  const _WorkerHeader(
      {required this.name, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                AvailabilityStatus.bgColor(currentStatus),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AvailabilityStatus.color(currentStatus),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Current: ',
                        style: TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    AvailabilityBadge(status: currentStatus),
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

// Status Option Card
class _StatusOption extends StatelessWidget {
  final String status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AvailabilityStatus.color(status);
    final bg = AvailabilityStatus.bgColor(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? bg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              AvailabilityStatus.emoji(status),
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AvailabilityStatus.label(status),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    AvailabilityStatus.hint(status),
                    style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? color.withOpacity(0.7)
                            : Colors.black45),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 22)
            else
              Icon(Icons.radio_button_unchecked,
                  color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}

// Info Box
class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'यह जानना ज़रूरी है',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blue),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• ✅ उपलब्ध होने पर ही Employers आपसे contact करेंगे\n'
            '• 🔴 Busy रहने पर भी Profile दिखेगी, पर Hire नहीं होंगे\n'
            '• 🏖️ छुट्टी पर आपका नाम search results में नहीं आएगा\n'
            '• Status change होने पर सभी Employers को अपने आप notification जाती है',
            style: TextStyle(fontSize: 12, color: Colors.blue, height: 1.6),
          ),
        ],
      ),
    );
  }
}
