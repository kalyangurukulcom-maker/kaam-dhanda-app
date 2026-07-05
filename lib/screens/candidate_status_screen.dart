// ============================================================
// Feature #83: Candidate Status Update
// File: lib/screens/candidate_status_screen.dart
// Kaam Dhanda App — Flutter
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CandidateStatusScreen extends StatefulWidget {
  final String userType; // 'field_staff' or 'gurukul'
  final String userId;

  const CandidateStatusScreen({
    Key? key,
    required this.userType,
    required this.userId,
  }) : super(key: key);

  @override
  State<CandidateStatusScreen> createState() => _CandidateStatusScreenState();
}

class _CandidateStatusScreenState extends State<CandidateStatusScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

  final List<_StatusTab> _tabs = const [
    _StatusTab('सभी', 'all', Icons.people, Colors.blueGrey),
    _StatusTab('Pending', 'pending', Icons.hourglass_empty, Color(0xFFFF8F00)),
    _StatusTab('Verified', 'verified', Icons.verified, Color(0xFF43A047)),
    _StatusTab('Joined', 'joined', Icons.check_circle, Color(0xFF1E88E5)),
    _StatusTab('Rejected', 'rejected', Icons.cancel, Color(0xFFE53935)),
  ];