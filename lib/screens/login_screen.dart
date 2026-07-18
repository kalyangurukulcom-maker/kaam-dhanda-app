import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Please enter a valid 10-digit mobile number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential cred) async {
          await FirebaseAuth.instance.signInWithCredential(cred);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() { _error = e.message ?? 'Verification failed. Try again.'; _loading = false; });
        },
        codeSent: (String vId, int? resendToken) {
          setState(() { _verificationId = vId; _otpSent = true; _loading = false; });
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _error = 'Please enter the complete 6-digit OTP');
      return;
    }
    if (_verificationId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp);
      await FirebaseAuth.instance.signInWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Invalid OTP. Please try again.'; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Something went wrong. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _otpSent ? _otpStep() : _phoneStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0,4))]),
          child: const Icon(Icons.work_rounded, size: 44, color: Color(0xFF1565C0))),
        const SizedBox(height: 16),
        const Text('KaamDhanda', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Rozgaar Ka Sahi Platform', style: TextStyle(color: Colors.white70, fontSize: 15)),
      ]),
    );
  }

  Widget _phoneStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      const Text('Login / Register', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
      const SizedBox(height: 6),
      Text('Enter your mobile number to continue', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      const SizedBox(height: 28),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            ),
            child: Row(children: [
              const Text('IN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              const SizedBox(width: 4),
              const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontSize: 15)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: const Color(0xFF1565C0).withOpacity(0.6)),
            ]),
          ),
          Expanded(child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 1),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '00000 00000',
              hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, letterSpacing: 0.5),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          )),
        ]),
      ),
      const SizedBox(height: 8),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 3,
          ),
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
      const SizedBox(height: 32),
      Center(child: Wrap(spacing: 16, alignment: WrapAlignment.center, children: [
        _featureChip(Icons.work, 'Find Jobs'),
        _featureChip(Icons.people, 'Hire Workers'),
        _featureChip(Icons.verified, 'Trusted Platform'),
      ])),
      const SizedBox(height: 24),
      Center(child: Text('By continuing, you agree to our Terms & Privacy Policy', style: TextStyle(fontSize: 11, color: Colors.grey[500]), textAlign: TextAlign.center)),
    ]);
  }

  Widget _featureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 14, color: const Color(0xFF1565C0)),
      label: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
      backgroundColor: const Color(0xFF1565C0).withOpacity(0.08),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _otpStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      const Text('Verify OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
      const SizedBox(height: 6),
      Text('OTP sent to +91 ${_phoneCtrl.text}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      const SizedBox(height: 28),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (i) => _otpBox(i))),
      const SizedBox(height: 8),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 3,
          ),
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Verify & Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Did not receive OTP? ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        TextButton(
          onPressed: _loading ? null : () => setState(() { _otpSent = false; _error = null; for (final c in _otpCtrls) c.clear(); }),
          child: const Text('Change Number', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
      Center(child: TextButton(
        onPressed: _loading ? null : _sendOtp,
        child: const Text('Resend OTP', style: TextStyle(color: Color(0xFF1565C0), fontSize: 13)),
      )),
    ]);
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpFocus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF5F7FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF1565C0).withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF1565C0).withOpacity(0.25))),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) FocusScope.of(context).requestFocus(_otpFocus[index + 1]);
          if (v.isEmpty && index > 0) FocusScope.of(context).requestFocus(_otpFocus[index - 1]);
          if (index == 5 && v.isNotEmpty) { FocusScope.of(context).unfocus(); _verifyOtp(); }
        },
      ),
    );
  }
}
