import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/screens/login_screen.dart';

class SessionTimeoutWrapper extends StatefulWidget {
  final Widget child;
  const SessionTimeoutWrapper({super.key, required this.child});

  @override
  State<SessionTimeoutWrapper> createState() => _SessionTimeoutWrapperState();
}

class _SessionTimeoutWrapperState extends State<SessionTimeoutWrapper> {
  Timer? _inactivityTimer;
  Timer? _warningTimer;
  int _secondsRemaining = 10;
  bool _showingWarning = false;

  static const _timeoutDuration = Duration(seconds: 50); // Warning triggers at 50s
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
  }

  void _startTimer() {
    _cancelTimers();
    // Only monitor timeout if a user is logged in
    if (AuthService.instance.currentUser == null) return;

    _inactivityTimer = Timer(_timeoutDuration, _showWarningDialog);
  }

  void _handleUserInteraction(PointerEvent details) {
    if (!_showingWarning) {
      _startTimer();
    }
  }

  void _showWarningDialog() {
    if (!mounted) return;
    setState(() {
      _showingWarning = true;
      _secondsRemaining = 10;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            // Setup the countdown ticker
            _warningTimer?.cancel();
            _warningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_secondsRemaining <= 1) {
                timer.cancel();
                Navigator.pop(ctx); // Close dialog
                _logout();
              } else {
                setStateBuilder(() {
                  _secondsRemaining--;
                });
                setState(() {
                  _secondsRemaining = _secondsRemaining;
                });
              }
            });

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('Session Expiring'),
                ],
              ),
              content: Text(
                'You have been inactive. You will be automatically signed out in $_secondsRemaining seconds due to inactivity.',
                style: const TextStyle(fontSize: 15),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    _warningTimer?.cancel();
                    Navigator.pop(ctx); // Close dialog
                    setState(() {
                      _showingWarning = false;
                    });
                    _startTimer(); // Reset inactivity timer
                  },
                  child: const Text('Stay Signed In'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _warningTimer?.cancel();
    });
  }

  void _logout() {
    AuthService.instance.logout();
    setState(() {
      _showingWarning = false;
    });
    
    // Clear navigator stack and send to login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been signed out due to inactivity.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerHover: _handleUserInteraction,
      child: widget.child,
    );
  }
}
