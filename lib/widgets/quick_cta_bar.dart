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
