import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

String? _firebaseError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Safe Firebase init — if it fails, show error on screen (don't crash silently)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    _firebaseError = e.toString();
  }
  runApp(const KaamDhandaApp());
}

class KaamDhandaApp extends StatelessWidget {
  const KaamDhandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If Firebase failed, show clear error message on screen
    if (_firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red[50],
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Firebase Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 12),
              Text(_firebaseError!, style: const TextStyle(fontSize: 13, color: Colors.black87), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Try re-init
                  try {
                    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
                    _firebaseError = null;
                  } catch (e) { _firebaseError = e.toString(); }
                },
                child: const Text('Retry'),
              ),
            ]),
          )),
        ),
      );
    }

    return MaterialApp(
      title: 'KaamDhanda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFF1976D2),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        fontFamily: null,
      ),
      home: const SplashGate(),
      routes: {
        '/home': (ctx) => HomeScreen(
          args: ModalRoute.of(ctx)?.settings.arguments as Map<String,dynamic>?,
        ),
        '/login': (ctx) => const LoginScreen(),
      },
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';
      final userType = prefs.getString('user_type') ?? 'guest';
      final docId = prefs.getString('user_doc_id') ?? '';
      final name = prefs.getString('user_name') ?? '';

      if (mounted) {
        if (phone.isNotEmpty && userType != 'guest') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(args: {
                'phone': phone, 'userType': userType, 'docId': docId, 'name': name,
              }),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // SharedPrefs failed — just go to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.work_rounded, size: 56, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 24),
            const Text('KaamDhanda', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('Rozgaar Ka Sahi Platform', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}