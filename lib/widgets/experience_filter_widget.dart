// ============================================================
// Feature #112: Experience Filter Chips
// File: lib/widgets/experience_filter_widget.dart
// Kaam Dhanda App — Flutter
//
// 3 Components:
//
// 1. ExperienceFilterBar — horizontal scrollable chips
//    (drop-in replacement for Worker Marketplace top bar)
//    Usage:
//      ExperienceFilterBar(
//        selected: _expFilter,
//        onChanged: (v) => setState(() => _expFilter = v),
//      )
//
// 2. WorkerFilterBar — combined filter bar
//    (Experience + Availability + Budget — all in one row)
//    Usage:
//      WorkerFilterBar(
//        filters: _filters,
//        onChanged: (f) => setState(() => _filters = f),
//      )
//
// 3. WorkerFilterSheet — bottom sheet with ALL filters
//    WorkerFilterSheet.show(context, filters: _filters)
//        .then((result) { if (result != null) setState(...); });
//
// Filter logic helper:
//    WorkerFilters.matches(workerData, filters) → bool
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// Filter Model
// ============================================================
enum ExperienceLevel {
  all,
  fresher,   // 0 – <1 yr
  junior,    // 1 – 3 yr
  senior,    // 3+ yr
}

class WorkerFilters {
  final ExperienceLevel experience;
  final bool availableOnly;
  final int? minRate;
  final int? maxRate;
  final double? minRating;
  final String? sortBy; // 'rating' | 'price_low' | 'price_high' | 'newest'

  const WorkerFilters({
    this.experience = ExperienceLevel.all,
    this.availableOnly = false,
    this.minRate,
    this.maxRate,
    this.minRating,
    this.sortBy,
  });

  WorkerFilters copyWith({
    ExperienceLevel? experience,
    bool? availableOnly,
    int? minRate,
    int? maxRate,
    double? minRating,
    String? sortBy,
    bool clearMinRate = false,
    bool clearMaxRate = false,
    bool clearMinRating = false,
    bool clearSortBy = false,
  }) =>
      WorkerFilters(
        experience: experience ?? this.experience,
        availableOnly: availableOnly ?? this.availableOnly,
        minRate: clearMinRate ? null : (minRate ?? this.minRate),
        maxRate: clearMaxRate ? null : (maxRate ?? this.maxRate),
        minRating: clearMinRating ? null : (minRating ?? this.minRating),
        sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      );

  WorkerFilters reset() => const WorkerFilters();

  bool get hasActiveFilters =>
      experience != ExperienceLevel.all ||
      availableOnly ||
      minRate != null ||
      maxRate != null ||
      minRating != null ||
      sortBy != null;

  int get activeCount {
    int c = 0;
    if (experience != ExperienceLevel.all) c++;
    if (availableOnly) c++;
    if (minRate != null || maxRate != null) c++;
    if (minRating != null) c++;
    if (sortBy != null) c++;
    return c;
  }

  /// Match a worker map against this filter set
  static bool matches(Map<String, dynamic> worker, WorkerFilters f) {
    // Experience
    if (f.experience != ExperienceLevel.all) {
      final expStr = (worker['experience'] ?? '').toString().toLowerCase();
      final years = _parseYears(expStr);
      switch (f.experience) {
        case ExperienceLevel.fresher:
          if (years >= 1) return false;
          break;
        case ExperienceLevel.junior:
          if (years < 1 || years >= 3) return false;
          break;
        case ExperienceLevel.senior:
          if (years < 3) return false;
          break;
        default:
          break;
      }
    }

    // Availability
    if (f.availableOnly) {
      final avail = worker['available'] ?? worker['isAvailable'] ?? true;
      if (avail == false) return false;
    }

    // Daily rate
    final rate = (worker['dailyRate'] ?? worker['rate'] ?? 0) as num;
    if (f.minRate != null && rate < f.minRate!) return false;
    if (f.maxRate != null && rate > f.maxRate!) return false;

    // Rating
    if (f.minRating != null) {
      final rating =
          (worker['rating'] ?? 0.0) as double;
      if (rating < f.minRating!) return false;
    }

    return true;
  }

  static int _parseYears(String s) {
    // "3 साल", "2 years", "fresher", "6 months" etc.
    if (s.contains('fresher') || s.contains('नया') || s.contains('fresh')) {
      return 0;
    }
    if (s.contains('month') || s.contains('महीन')) return 0;
    final match = RegExp(r'(\d+)').firstMatch(s);
    if (match != null) return int.tryParse(match.group(1)!) ?? 0;
    return 0;
  }
}

// ============================================================
// 1. ExperienceFilterBar — Horizontal chips only
// ============================================================
class ExperienceFilterBar extends StatelessWidget {
  final ExperienceLevel selected;
  final ValueChanged<ExperienceLevel> onChanged;
  final EdgeInsetsGeometry padding;

  const ExperienceFilterBar({
    Key? key,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  static const _options = [
    (ExperienceLevel.all,     '👥',  'सभी',        'Any experience'),
    (ExperienceLevel.fresher, '🌱',  'Fresher',    '0 – 12 months'),
    (ExperienceLevel.junior,  '🔧',  '1-3 साल',   '1 to 3 years'),
    (ExperienceLevel.senior,  '⭐',  '3+ साल',    '3+ years'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: _options.map((opt) {
          final (level, icon, label, _) = opt;
          final sel = selected == level;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ExpChip(
              icon: icon,
              label: label,
              selected: sel,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(level);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExpChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExpChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1565C0);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 2. WorkerFilterBar — Combined one-line filter row
// ============================================================
class WorkerFilterBar extends StatelessWidget {
  final WorkerFilters filters;
  final ValueChanged<WorkerFilters> onChanged;
  final EdgeInsetsGeometry padding;

  const WorkerFilterBar({
    Key? key,
    required this.filters,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          // All Filters button (opens bottom sheet)
          _FilterIconBtn(
            icon: Icons.tune_rounded,
            label: 'Filters',
            badge: filters.activeCount,
            onTap: () async {
              final result = await WorkerFilterSheet.show(
                  context, filters: filters);
              if (result != null) onChanged(result);
            },
          ),
          const SizedBox(width: 8),

          // Experience quick chips
          _QuickChip(
            icon: '🌱',
            label: 'Fresher',
            active: filters.experience == ExperienceLevel.fresher,
            onTap: () => onChanged(filters.copyWith(
              experience: filters.experience == ExperienceLevel.fresher
                  ? ExperienceLevel.all
                  : ExperienceLevel.fresher,
            )),
          ),
          const SizedBox(width: 6),
          _QuickChip(
            icon: '🔧',
            label: '1-3 साल',
            active: filters.experience == ExperienceLevel.junior,
            onTap: () => onChanged(filters.copyWith(
              experience: filters.experience == ExperienceLevel.junior
                  ? ExperienceLevel.all
                  : ExperienceLevel.junior,
            )),
          ),
          const SizedBox(width: 6),
          _QuickChip(
            icon: '⭐',
            label: '3+ साल',
            active: filters.experience == ExperienceLevel.senior,
            onTap: () => onChanged(filters.copyWith(
              experience: filters.experience == ExperienceLevel.senior
                  ? ExperienceLevel.all
                  : ExperienceLevel.senior,
            )),
          ),
          const SizedBox(width: 6),

          // Available Today
          _QuickChip(
            icon: '✅',
            label: 'Available',
            active: filters.availableOnly,
            activeColor: Colors.green.shade700,
            onTap: () => onChanged(
                filters.copyWith(availableOnly: !filters.availableOnly)),
          ),
          const SizedBox(width: 6),

          // Top Rated
          _QuickChip(
            icon: '🏆',
            label: 'Top Rated',
            active: filters.minRating == 4.0,
            activeColor: Colors.amber.shade700,
            onTap: () => onChanged(
              filters.minRating == 4.0
                  ? filters.copyWith(clearMinRating: true)
                  : filters.copyWith(minRating: 4.0),
            ),
          ),
          const SizedBox(width: 6),

          // Sort
          _QuickChip(
            icon: '⬇️',
            label: 'Sasta Pehle',
            active: filters.sortBy == 'price_low',
            activeColor: Colors.purple.shade700,
            onTap: () => onChanged(
              filters.sortBy == 'price_low'
                  ? filters.copyWith(clearSortBy: true)
                  : filters.copyWith(sortBy: 'price_low'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _FilterIconBtn({
    required this.icon,
    required this.label,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: badge > 0
                  ? const Color(0xFF1565C0)
                  : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: badge > 0
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: badge > 0 ? Colors.white : Colors.black87),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: badge > 0 ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? const Color(0xFF1565C0);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? color : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
                color: active ? color : Colors.black87,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(Icons.close, size: 13, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 3. WorkerFilterSheet — Full bottom sheet
// ============================================================
class WorkerFilterSheet extends StatefulWidget {
  final WorkerFilters initialFilters;

  const WorkerFilterSheet({Key? key, required this.initialFilters})
      : super(key: key);

  /// Static helper to show the sheet and await result
  static Future<WorkerFilters?> show(BuildContext context,
      {required WorkerFilters filters}) {
    return showModalBottomSheet<WorkerFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerFilterSheet(initialFilters: filters),
    );
  }

  @override
  State<WorkerFilterSheet> createState() => _WorkerFilterSheetState();
}

class _WorkerFilterSheetState extends State<WorkerFilterSheet> {
  late WorkerFilters _f;

  // Budget slider
  RangeValues _budgetRange = const RangeValues(0, 2000);

  static const _budgetSlabs = [
    (0,    500,  '₹0 – ₹500'),
    (500,  1000, '₹500 – ₹1000'),
    (1000, 1500, '₹1000 – ₹1500'),
    (1500, 2000, '₹1500 – ₹2000'),
    (2000, 9999, '₹2000+'),
  ];

  static const _sortOptions = [
    ('rating',     '⭐', 'Rating (High → Low)'),
    ('price_low',  '💸', 'Price (Low → High)'),
    ('price_high', '💰', 'Price (High → Low)'),
    ('newest',     '🆕', 'Newest First'),
  ];

  static const _ratingOptions = [
    (3.0, '3+⭐'),
    (4.0, '4+⭐'),
    (4.5, '4.5+⭐'),
  ];

  @override
  void initState() {
    super.initState();
    _f = widget.initialFilters;
    _budgetRange = RangeValues(
      (_f.minRate ?? 0).toDouble(),
      (_f.maxRate ?? 2000).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🎛️ Filters',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () =>
                      setState(() => _f = const WorkerFilters()),
                  child: const Text('Reset',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Experience
                  _SheetSection(
                    icon: '⏱️',
                    title: 'Experience',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        (ExperienceLevel.all, '👥', 'सभी'),
                        (ExperienceLevel.fresher, '🌱', 'Fresher\n(0-1 साल)'),
                        (ExperienceLevel.junior, '🔧', '1-3 साल'),
                        (ExperienceLevel.senior, '⭐', '3+ साल'),
                      ].map((opt) {
                        final (level, icon, label) = opt;
                        final sel = _f.experience == level;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() =>
                                _f = _f.copyWith(experience: level));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF1565C0)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey.shade300,
                                width: sel ? 2 : 1,
                              ),
                              boxShadow: sel
                                  ? [BoxShadow(
                                      color: const Color(0xFF1565C0)
                                          .withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))]
                                  : [],
                            ),
                            child: Column(
                              children: [
                                Text(icon,
                                    style:
                                        const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Availability
                  _SheetSection(
                    icon: '✅',
                    title: 'Availability',
                    child: _ToggleRow(
                      label: 'सिर्फ Available Workers दिखाएं',
                      value: _f.availableOnly,
                      onChanged: (v) =>
                          setState(() =>
                              _f = _f.copyWith(availableOnly: v)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Budget
                  _SheetSection(
                    icon: '💰',
                    title:
                        'Daily Rate: ₹${_budgetRange.start.round()} – ₹${_budgetRange.end.round() == 2000 ? "2000+" : _budgetRange.end.round()}',
                    child: Column(
                      children: [
                        RangeSlider(
                          values: _budgetRange,
                          min: 0,
                          max: 2000,
                          divisions: 20,
                          activeColor: const Color(0xFF1565C0),
                          inactiveColor: Colors.blue.shade100,
                          labels: RangeLabels(
                            '₹${_budgetRange.start.round()}',
                            _budgetRange.end.round() == 2000
                                ? '₹2000+'
                                : '₹${_budgetRange.end.round()}',
                          ),
                          onChanged: (v) {
                            setState(() {
                              _budgetRange = v;
                              _f = _f.copyWith(
                                minRate: v.start.round() == 0
                                    ? null
                                    : v.start.round(),
                                maxRate: v.end.round() == 2000
                                    ? null
                                    : v.end.round(),
                                clearMinRate: v.start.round() == 0,
                                clearMaxRate: v.end.round() == 2000,
                              );
                            });
                          },
                        ),
                        // Quick slabs
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _budgetSlabs.map((slab) {
                            final (min, max, label) = slab;
                            final active = _f.minRate == (min == 0 ? null : min) &&
                                _f.maxRate == (max == 9999 ? null : max);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _f = _f.copyWith(
                                    minRate: min == 0 ? null : min,
                                    maxRate: max == 9999 ? null : max,
                                    clearMinRate: min == 0,
                                    clearMaxRate: max == 9999,
                                  );
                                  _budgetRange = RangeValues(
                                    min.toDouble(),
                                    (max == 9999 ? 2000 : max).toDouble(),
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFF1565C0)
                                          .withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: active
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: active
                                        ? const Color(0xFF1565C0)
                                        : Colors.black54,
                                    fontWeight: active
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Minimum Rating
                  _SheetSection(
                    icon: '⭐',
                    title: 'Minimum Rating',
                    child: Row(
                      children: [
                        _RatingBtn(
                          label: 'Any',
                          active: _f.minRating == null,
                          onTap: () => setState(
                              () => _f = _f.copyWith(clearMinRating: true)),
                        ),
                        const SizedBox(width: 8),
                        ..._ratingOptions.map((opt) {
                          final (val, label) = opt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _RatingBtn(
                              label: label,
                              active: _f.minRating == val,
                              onTap: () => setState(
                                  () => _f = _f.copyWith(minRating: val)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sort
                  _SheetSection(
                    icon: '🔀',
                    title: 'Sort By',
                    child: Column(
                      children: _sortOptions.map((opt) {
                        final (key, icon, label) = opt;
                        final sel = _f.sortBy == key;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Text(icon,
                              style: const TextStyle(fontSize: 20)),
                          title: Text(label,
                              style: const TextStyle(fontSize: 14)),
                          trailing: sel
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF1565C0))
                              : Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey.shade400),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _f = sel
                                ? _f.copyWith(clearSortBy: true)
                                : _f.copyWith(sortBy: key));
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _f),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: Text(
                  _f.hasActiveFilters
                      ? 'Apply Filters (${_f.activeCount} active)'
                      : 'Apply Filters',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sheet section wrapper
class _SheetSection extends StatelessWidget {
  final String icon;
  final String title;
  final Widget child;

  const _SheetSection(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// Toggle row
class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? Colors.green.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? Colors.green.shade400
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14)),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

// Rating button
class _RatingBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RatingBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Colors.amber.shade700
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active
                ? Colors.amber.shade700
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
