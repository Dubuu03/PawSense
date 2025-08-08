import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../models/user_model.dart';

class VerifyEmailPage extends StatefulWidget {
  final String username;
  final String email;
  final String uid;
  final String contactNumber;
  final DateTime dateOfBirth;
  final bool agreedToTerms;
  final String address;

  const VerifyEmailPage({
    super.key,
    required this.username,
    required this.email,
    required this.uid,
    required this.contactNumber,
    required this.dateOfBirth,
    required this.agreedToTerms,
    required this.address,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}
class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _authService = AuthService();

  bool _isLoading = false;
  bool _saved = false;
  bool _navigated = false;
  int _seconds = 60;
  Timer? _timer;
  late StreamSubscription<bool> _emailVerifiedSub;

  @override
  void initState() {
    super.initState();
    _startTimer();


    _emailVerifiedSub = _authService.emailVerifiedStream.listen((verified) {
      if (verified) {
        _handleVerified();
      }
    });
  }

  void _startTimer() {
    _seconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailVerifiedSub.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() => _isLoading = true);
    await _authService.resendVerificationEmail();
    setState(() => _isLoading = false);
    _startTimer();
    _showSnack('Verification email resent.');
  }

  Future<void> _saveUser() async {
    final user = _authService.currentUser;
    if (!_saved && user != null) {
      await _authService.saveUser(UserModel(
        uid: widget.uid,
        username: widget.username,
        email: widget.email,
        contactNumber: widget.contactNumber,
        dateOfBirth: widget.dateOfBirth,
        agreedToTerms: widget.agreedToTerms,
        createdAt: DateTime.now(),
        address: widget.address,
      ));
      _saved = true;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleVerified() async {
    if (!_navigated && mounted) {
      _navigated = true;
      _stopTimer(); // optional
      await _saveUser();
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('img/sendemail.png', height: 150, fit: BoxFit.contain),
              const SizedBox(height: 40),
              const Text(
                'Confirm your email address',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'We sent you a verification link. Please check your email to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _seconds == 0 ? _resendEmail : null,
                  child: Text(
                    _seconds == 0 ? "Resend Email" : "Send Again in $_seconds s",
                    style: TextStyle(
                      fontSize: 14,
                      color: _seconds == 0 ? Colors.black : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
