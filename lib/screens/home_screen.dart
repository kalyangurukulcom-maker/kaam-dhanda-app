import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Screens
import 'worker_marketplace_screen.dart';
import 'jobs_screen.dart';
import 'nearby_workers_screen.dart';
import 'testimonials_screen.dart';
import 'grameen_sathi_screen.dart';
import 'job_alert_subscription.dart';
import 'employer_job_management_screen.dart';
import 'daily_checkin_screen.dart';
import 'monthly_target_screen.dart';
import 'candidate_status_screen.dart';
import 'worker_cv_screen.dart';

// Widgets
import '../widgets/live_stats_widget.dart';
import '../widgets/quick_cta_bar.dart';
import '../widgets/worker_availability_widget.dart';
import '../widgets/available_today_filter.dart';

const _kDemoWorkerId   = 'W001';
const _kDemoWorkerName = 'Ramesh Kumar';
const _kDemoWorkerPhone = '9876543210';
const _kDemoEmployerId  = 'E001';
const _kDemoEmployerName = 'Ravi Enterprises';
const _kDemoStaffId    = 'GS001';
const _kDemoStaffName  = 'Field Staff 1';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
