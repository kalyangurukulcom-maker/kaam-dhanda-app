// ============================================================
// Feature #123: Budget Filter Widget
// File: lib/widgets/budget_filter_widget.dart
// Kaam Dhanda App — Flutter
//
// 3 Components:
//
// 1. BudgetFilterBar — compact horizontal quick-select slabs
//    (no bottom sheet needed, inline in Worker Marketplace)
//    Usage:
//      BudgetFilterBar(
//        minRate: _minRate,
//        maxRate: _maxRate,
//        onChanged: (min, max) => setState(() { _minRate = min; _maxRate = max; }),
//      )
//
// 2. BudgetSliderCard — expanded card with RangeSlider + slabs
//    Usage:
//      BudgetSliderCard(
//        minRate: _minRate,
//        maxRate: _maxRate,
//        onChanged: (min, max) => setState(() { ... }),
//      )
//
// 3. BudgetBadge — compact badge showing active budget filter
//    BudgetBadge(minRate: 500, maxRate: 1000, onClear: () { ... })
//
// Worker filter helper:
//    BudgetFilter.matches(workerDailyRate, minRate, maxRate) → bool
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// Data & Logic
// ============================================================
class BudgetFilter {
  static const slabs = [
    _Slab(null, null, '💰 सभी', 'Any budget'),
    _Slab(0, 500, '₹0–500', 'Entry level'),
    _Slab(500, 800, '₹500–800', 'Mid range'),
    _Slab(800, 1200, '₹800–1200', 'Skilled'),
    _Slab(1200, 1800, '₹1200–1800', 'Expert'),
    _Slab(1800, null, '₹1800+', 'Premium'),
  ];

  static bool matches(int workerRate, int? minRate, int? maxRate) {
    if (minRate != null && workerRate < minRate) return false;
    if (maxRate != null && workerRate > maxRate) return false;
    return true;
  }

  static String label(int? min, int? max) {
    if (min == null && max == null) return 'Any Budget';
    if (min != null && max != null) return '₹$min – ₹$max/day';
    if (min != null) return '₹$min+/day';
    if (max != null) return 'Up to ₹$max/day';
    return 'Any Budget';
  }

  static bool isActive(int? min, int? max) => min != null || max != null;
}

class _Slab {
  final int? min;
  final int? max;
  final String label;
  final String desc;

  const _Slab(this.min, this.max, this.label, this.desc);
}

// ============================================================
// 1. BudgetFilterBar — inline horizontal chips
// ============================================================
class BudgetFilterBar extends StatelessWidget {
  final int? minRate;
  final int? maxRate;
  final void Function(int? min, int? max) onChanged;
  final EdgeInsetsGeometry padding;

  const BudgetFilterBar({
    Key? key,
    required this.minRate,
    required this.maxRate,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  bool _isSelected(_Slab slab) =>
      slab.min == minRate && slab.max == maxRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: padding,
          child: Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              const Text(
                'Budget Filter',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const Spacer(),
              if (BudgetFilter.isActive(minRate, maxRate))
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChanged(null, null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.close, size: 12, color: Colors.red),
                        SizedBox(width: 3),
                        Text('Clear',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Chips
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: BudgetFilter.slabs.length,
            itemBuilder: (_, i) {
              final slab = BudgetFilter.slabs[i];
              final sel = _isSelected(slab);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(slab.min, slab.max);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF1565C0)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: sel
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade300,
                        width: sel ? 2 : 1,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: const Color(0xFF1565C0)
                                      .withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ]
                          : [],
                    ),
                    child: Text(
                      slab.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: sel ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 2. BudgetSliderCard — Expanded card with RangeSlider
// ============================================================
class BudgetSliderCard extends StatefulWidget {
  final int? minRate;
  final int? maxRate;
  final void Function(int? min, int? max) onChanged;

  const BudgetSliderCard({
    Key? key,
    required this.minRate,
    required this.maxRate,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<BudgetSliderCard> createState() => _BudgetSliderCardState();
}

class _BudgetSliderCardState extends State<BudgetSliderCard> {
  late RangeValues _range;
  static const double _max = 2500;

  @override
  void initState() {
    super.initState();
    _range = RangeValues(
      (widget.minRate ?? 0).toDouble(),
      (widget.maxRate ?? _max).toDouble(),
    );
  }

  @override
  void didUpdateWidget(BudgetSliderCard old) {
    super.didUpdateWidget(old);
    if (widget.minRate != old.minRate || widget.maxRate != old.maxRate) {
      _range = RangeValues(
        (widget.minRate ?? 0).toDouble(),
        (widget.maxRate ?? _max).toDouble(),
      );
    }
  }

  String get _minLabel => '₹${_range.start.round()}';
  String get _maxLabel =>
      _range.end.round() >= _max ? '₹2500+' : '₹${_range.end.round()}';

  @override
  Widget build(BuildContext context) {
    final active = BudgetFilter.isActive(widget.minRate, widget.maxRate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? const Color(0xFF1565C0).withOpacity(0.5)
              : Colors.grey.shade200,
          width: active ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text('Daily Budget',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  active
                      ? '$_minLabel – $_maxLabel'
                      : 'कोई limit नहीं',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Range slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1565C0),
              inactiveTrackColor: Colors.blue.shade100,
              thumbColor: const Color(0xFF1565C0),
              overlayColor:
                  const Color(0xFF1565C0).withOpacity(0.15),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
            ),
            child: RangeSlider(
              values: _range,
              min: 0,
              max: _max,
              divisions: 50,
              labels: RangeLabels(_minLabel, _maxLabel),
              onChanged: (v) {
                setState(() => _range = v);
              },
              onChangeEnd: (v) {
                widget.onChanged(
                  v.start.round() == 0 ? null : v.start.round(),
                  v.end.round() >= _max ? null : v.end.round(),
                );
              },
            ),
          ),

          // Min / Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹0',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black38)),
                Text('₹2500+',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick slab pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BudgetFilter.slabs.skip(1).map((slab) {
              final sel = slab.min == widget.minRate &&
                  slab.max == widget.maxRate;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _range = RangeValues(
                      (slab.min ?? 0).toDouble(),
                      (slab.max ?? _max).toDouble(),
                    );
                  });
                  widget.onChanged(slab.min, slab.max);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF1565C0).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade300,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        slab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: sel
                              ? const Color(0xFF1565C0)
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        slab.desc,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black38),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Clear button
          if (active) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _range = const RangeValues(0, _max));
                widget.onChanged(null, null);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, size: 14, color: Colors.red),
                    SizedBox(width: 6),
                    Text(
                      'Budget Filter हटाएं',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// 3. BudgetBadge — compact active filter indicator
// ============================================================
class BudgetBadge extends StatelessWidget {
  final int? minRate;
  final int? maxRate;
  final VoidCallback onClear;

  const BudgetBadge({
    Key? key,
    required this.minRate,
    required this.maxRate,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!BudgetFilter.isActive(minRate, maxRate)) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onClear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              BudgetFilter.label(minRate, maxRate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.close, size: 13, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BudgetFilterSummaryRow — shows active filters as dismissible chips
// Useful in marketplace header to show what's filtered
// ============================================================
class BudgetFilterSummaryRow extends StatelessWidget {
  final int? minRate;
  final int? maxRate;
  final bool availableOnly;
  final String? experienceLabel;
  final VoidCallback onClearBudget;
  final VoidCallback? onClearAvailable;
  final VoidCallback? onClearExperience;
  final VoidCallback? onClearAll;

  const BudgetFilterSummaryRow({
    Key? key,
    required this.minRate,
    required this.maxRate,
    required this.availableOnly,
    this.experienceLabel,
    required this.onClearBudget,
    this.onClearAvailable,
    this.onClearExperience,
    this.onClearAll,
  }) : super(key: key);

  bool get hasAny =>
      BudgetFilter.isActive(minRate, maxRate) ||
      availableOnly ||
      (experienceLabel != null && experienceLabel != 'सभी');

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    return Container(
      color: Colors.blue.shade50,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Filters: ',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600),
            ),
            if (BudgetFilter.isActive(minRate, maxRate))
              _DismissChip(
                label: BudgetFilter.label(minRate, maxRate),
                icon: '💰',
                onDismiss: onClearBudget,
              ),
            if (availableOnly && onClearAvailable != null)
              _DismissChip(
                label: 'Available Now',
                icon: '✅',
                onDismiss: onClearAvailable!,
              ),
            if (experienceLabel != null &&
                experienceLabel != 'सभी' &&
                onClearExperience != null)
              _DismissChip(
                label: experienceLabel!,
                icon: '⏱️',
                onDismiss: onClearExperience!,
              ),
            if (onClearAll != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onClearAll!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Text(
                    'सब हटाएं',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DismissChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onDismiss;

  const _DismissChip(
      {required this.icon, required this.label, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onDismiss();
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1565C0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.close,
                  size: 11, color: Color(0xFF1565C0)),
            ],
          ),
        ),
      ),
    );
  }
}
