// ============================================================
// Feature #84: Daily Check-in
// File: lib/screens/daily_checkin_screen.dart
// Kaam Dhanda App — Flutter
//
// pubspec.yaml mein add karo:
//   geolocator: ^10.1.0
//   intl: ^0.18.1
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class DailyCheckinScreen extends StatefulWidget {
  final String userType; // 'field_staff' or 'gurukul'
  final String userId;
  final String userName;

  const DailyCheckinScreen({
    Key? key,
    required this.userType,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}