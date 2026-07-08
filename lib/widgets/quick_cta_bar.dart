// ============================================================
// Feature #114: Quick CTA Bottom Bar
// File: lib/widgets/quick_cta_bar.dart
// Kaam Dhanda App — Flutter
//
// Usage — Scaffold ke bottomNavigationBar mein:
//
//   Scaffold(
//     bottomNavigationBar: QuickCtaBar(
//       onWorkerRegister: () => Navigator.push(...WorkerScreen),
//       onJobSearch: () => Navigator.push(...JobsScreen),
//       onHireWorker: () => Navigator.push(...WorkerMarketplaceScreen),
//     ),
//   )
//
// Ya sirf 2 buttons ke liye:
//   QuickCtaBar.twoButton(
//     onWorkerRegister: ...,
//     onJobSearch: ...,
//   )
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// Main Quick CTA Bar Widget
// ============================================================
class QuickCtaBar extends StatefulWidget {
  final VoidCallback? onWorkerRegister;
  final VoidCallback? onJobSearch;
  final VoidCallback? onHireWorker;
  final bool showHireButton; // false = sirf 2 buttons

  const QuickCtaBar({
    Key? key,
    this.onWorkerRegister,
    this.onJobSearch,
    this.onHireWorker,
    this.showHireButton = true,
  }) : super(key: key);

  /// Convenience constructor — sirf 2 buttons
  factory QuickCtaBar.twoButton({
    Key? key,
    VoidCallback? onWorkerRegister,
    VoidCallback? onJobSearch,
  }) =>
      QuickCtaBar(
        key: key,
        onWorkerRegister: onWorkerRegister,
        onJobSearch: onJobSearch,
        showHireButton: false,
      );

  @override
  State<QuickCtaBar> createState() => _QuickCtaBarState();
}

class _QuickCtaBarState extends State<QuickCtaBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeOutCubic,
    ));
    // Slide up after brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onTap(VoidCallback? action) {
    HapticFeedback.lightImpact();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: widget.showHireButton
                ? _threeButtons()
                : _twoButtons(),
          ),
        ),
      ),
    );
  }

  // ---- 3-button layout ----
  Widget _threeButtons() {
    return Row(
      children: [
        // Worker Register
        Expanded(
          child: _CtaButton(
            icon: '👷',
            label: 'Register करें',
            subLabel: 'Worker',
            bgColor: const Color(0xFF1565C0),
            onTap: () => _onTap(widget.onWorkerRegister),
          ),
        ),
        const SizedBox(width: 8),
        // Job Search
        Expanded(
          child: _CtaButton(
            icon: '🔍',
            label: 'Job ढूंढें',
            subLabel: 'Browse Jobs',
            bgColor: const Color(0xFF43A047),
            onTap: () => _onTap(widget.onJobSearch),
          ),
        ),
        const SizedBox(width: 8),
        // Hire Worker
        Expanded(
          child: _CtaButton(
            icon: '🏢',
            label: 'Hire करें',
            subLabel: 'Employer',
            bgColor: const Color(0xFFFF8F00),
            onTap: () => _onTap(widget.onHireWorker),
          ),
        ),
      ],
    );
  }

  // ---- 2-button layout ----
  Widget _twoButtons() {
    return Row(
      children: [
        Expanded(
          child: _CtaBigButton(
            icon: '👷',
            label: 'Worker Register करें',
            bgColor: const Color(0xFF1565C0),
            onTap: () => _onTap(widget.onWorkerRegister),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CtaBigButton(
            icon: '💼',
            label: 'Job ढूंढें',
            bgColor: const Color(0xFF43A047),
            onTap: () => _onTap(widget.onJobSearch),
          ),
        ),
      ],
    );
  }
}

// ---- Small 3-column button ----
class _CtaButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subLabel;
  final Color bgColor;
  final VoidCallback onTap;

  const _CtaButton({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subLabel,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Big 2-column button ----
class _CtaBigButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  const _CtaBigButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Floating CTA — scrollable page ke liye (overlaid on body)
// Scroll karne pe hide ho jaata hai, top pe aane pe show
// ============================================================
class FloatingCtaBar extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onWorkerRegister;
  final VoidCallback? onJobSearch;

  const FloatingCtaBar({
    Key? key,
    required this.scrollController,
    this.onWorkerRegister,
    this.onJobSearch,
  }) : super(key: key);

  @override
  State<FloatingCtaBar> createState() => _FloatingCtaBarState();
}

class _FloatingCtaBarState extends State<FloatingCtaBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  bool _visible = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = 1.0;
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final scrollingDown = offset > _lastOffset;
    _lastOffset = offset;

    if (scrollingDown && _visible) {
      _visible = false;
      _ctrl.reverse();
    } else if (!scrollingDown && !_visible) {
      _visible = true;
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _CtaBigButton(
                icon: '👷',
                label: 'Register करें',
                bgColor: const Color(0xFF1565C0),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onWorkerRegister?.call();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CtaBigButton(
                icon: '💼',
                label: 'Job ढूंढें',
                bgColor: const Color(0xFF43A047),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onJobSearch?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CtaBadge — notification dot ke saath CTA icon button
// AppBar actions ya anywhere mein use karo
// ============================================================
class CtaBadgeButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  const CtaBadgeButton({
    Key? key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.badgeCount,
  }) : super(key: key);

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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
