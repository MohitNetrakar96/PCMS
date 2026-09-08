import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'get_started_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color kRoyalPurple = Color(0xFF55356E);
  static const Color kRoyalPurpleLight = Color(0xFF6F468E);
  static const Color kDeepObsidian = Color(0xFF28153A);
  static const Color kFrostCyan = Color(0xFFD6F5FF);
  static const Color kSoftLilac = Color(0xFFE9E2F3);

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Proactively detect backend (USB or Wi-Fi)
    ApiService.autoDiscoverServer();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initSession();

    if (!mounted) return;

    if (authProvider.isAuthenticated && authProvider.user != null && authProvider.user!.email.trim().isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepObsidian,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kDeepObsidian, kRoyalPurple, kRoyalPurpleLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kRoyalPurple, kRoyalPurpleLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: kRoyalPurple.withOpacity(0.5),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: kFrostCyan.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: kSoftLilac.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(Icons.account_balance_rounded, size: 52, color: kFrostCyan),
              ),
              const SizedBox(height: 24),
              const Text(
                'PCMS BankFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sovereign Pigmy Collection Gateway',
                style: TextStyle(
                  color: kSoftLilac.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: kFrostCyan),
            ],
          ),
        ),
      ),
    );
  }
}
