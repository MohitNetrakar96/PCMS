import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String _selectedRole = 'Collection Agent';
  bool _obscurePass = true;
  bool _isOtpMode = false;
  bool _otpSent = false;
  bool _sendingOtp = false;
  String? _generatedOtp;

  // Custom Sovereign Palette
  static const Color kRoyalPurple = Color(0xFF55356E);
  static const Color kRoyalPurpleLight = Color(0xFF6F468E);
  static const Color kDeepObsidian = Color(0xFF28153A);
  static const Color kObsidianOnyx = Color(0xFF191308);
  static const Color kSoftLilac = Color(0xFFE9E2F3);
  static const Color kSoftLilacLight = Color(0xFFF6F2FA);
  static const Color kFrostCyan = Color(0xFFD6F5FF);
  static const Color kFrostCyanAccent = Color(0xFF7DE1FC);
  static const Color kSageEmerald = Color(0xFF76A787);
  static const Color kPorcelain = Color(0xFFF7F4FA);

  final List<Map<String, dynamic>> _roleConfigs = [
    {'name': 'Collection Agent', 'label': 'Agent', 'icon': Icons.directions_walk_rounded},
    {'name': 'Branch Manager', 'label': 'Manager', 'icon': Icons.account_balance_rounded},
    {'name': 'Cashier', 'label': 'Cashier', 'icon': Icons.payments_rounded},
    {'name': 'Administrator', 'label': 'Admin', 'icon': Icons.admin_panel_settings_rounded},
    {'name': 'Customer', 'label': 'Customer', 'icon': Icons.person_pin_rounded},
    {'name': 'Auditor', 'label': 'Auditor', 'icon': Icons.fact_check_rounded},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _selectRoleConfig(Map<String, dynamic> config) {
    setState(() {
      _selectedRole = config['name'];
      _otpSent = false;
    });
  }

  void _openForgotPasswordSheet() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final resetOtpCtrl = TextEditingController();
    final resetNewPassCtrl = TextEditingController();
    final resetConfirmPassCtrl = TextEditingController();
    int resetStep = 1;
    bool isResetLoading = false;
    String? resetError;
    String? resetOtpGenerated;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kRoyalPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: kRoyalPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kDeepObsidian),
                          ),
                          Text(
                            'Secure 2-step account recovery via OTP',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B587B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (resetError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resetError!,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (resetStep == 1) ...[
                  const Text(
                    'REGISTERED EMAIL OR EMPLOYEE ID',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resetEmailCtrl,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                    decoration: InputDecoration(
                      hintText: 'e.g. yourname@company.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: kRoyalPurple, size: 20),
                      filled: true,
                      fillColor: kPorcelain,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isResetLoading
                        ? null
                        : () async {
                            final target = resetEmailCtrl.text.trim();
                            if (target.isEmpty) {
                              setModalState(() => resetError = 'Please enter your registered email or employee ID.');
                              return;
                            }
                            setModalState(() {
                              isResetLoading = true;
                              resetError = null;
                            });
                            try {
                              final res = await ApiService.sendOtp(target);
                              setModalState(() {
                                isResetLoading = false;
                                resetOtpGenerated = res['otp']?.toString() ?? '123456';
                                resetStep = 2;
                              });
                            } catch (e) {
                              setModalState(() {
                                isResetLoading = false;
                                resetError = e.toString().replaceAll('Exception: ', '').trim();
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRoyalPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isResetLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Send Reset OTP Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                  ),
                ] else ...[
                  if (resetOtpGenerated != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: kSageEmerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kSageEmerald.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: kSageEmerald, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OTP Dispatched: $resetOtpGenerated',
                              style: const TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Text(
                    '6-DIGIT VERIFICATION CODE',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resetOtpCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.w900, color: kObsidianOnyx),
                    decoration: InputDecoration(
                      hintText: resetOtpGenerated ?? '123456',
                      prefixIcon: const Icon(Icons.pin_rounded, color: kSageEmerald),
                      filled: true,
                      fillColor: kFrostCyan.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSageEmerald)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'NEW SECURITY PASSWORD',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resetNewPassCtrl,
                    obscureText: obscureNew,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                    decoration: InputDecoration(
                      hintText: 'Min 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: kRoyalPurple, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: kRoyalPurple.withOpacity(0.6), size: 18),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      filled: true,
                      fillColor: kPorcelain,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'CONFIRM NEW PASSWORD',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resetConfirmPassCtrl,
                    obscureText: obscureConfirm,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                    decoration: InputDecoration(
                      hintText: 'Re-enter new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: kRoyalPurple, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: kRoyalPurple.withOpacity(0.6), size: 18),
                        onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                      filled: true,
                      fillColor: kPorcelain,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isResetLoading
                        ? null
                        : () async {
                            final code = resetOtpCtrl.text.trim();
                            final newPass = resetNewPassCtrl.text;
                            final confirmPass = resetConfirmPassCtrl.text;

                            if (code.isEmpty) {
                              setModalState(() => resetError = 'Please enter the 6-digit verification OTP.');
                              return;
                            }
                            if (newPass.length < 6) {
                              setModalState(() => resetError = 'Password must be at least 6 characters.');
                              return;
                            }
                            if (newPass != confirmPass) {
                              setModalState(() => resetError = 'Passwords do not match.');
                              return;
                            }

                            setModalState(() {
                              isResetLoading = true;
                              resetError = null;
                            });

                            try {
                              await ApiService.resetPasswordOtp(
                                email: resetEmailCtrl.text.trim(),
                                code: code,
                                password: newPass,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                setState(() {
                                  _emailCtrl.text = resetEmailCtrl.text.trim();
                                  _passCtrl.text = newPass;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated successfully! You can now sign in.'),
                                    backgroundColor: kSageEmerald,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                isResetLoading = false;
                                resetError = e.toString().replaceAll('Exception: ', '').trim();
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRoyalPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isResetLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Save New Password & Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(width: 6),
                              Icon(Icons.check_circle_rounded, size: 16),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final email = _emailCtrl.text.trim();

    if (_isOtpMode) {
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your official email or employee ID to receive OTP.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      if (!_otpSent) {
        setState(() => _sendingOtp = true);
        try {
          final res = await ApiService.sendOtp(email);
          setState(() {
            _sendingOtp = false;
            _otpSent = true;
            _generatedOtp = res['otp']?.toString() ?? '123456';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Bank OTP Dispatched: ${_generatedOtp ?? "123456"}')),
                  ],
                ),
                backgroundColor: kSageEmerald,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          setState(() => _sendingOtp = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '').trim()),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        }
        return;
      } else {
        final enteredOtp = _otpCtrl.text.trim();
        if (enteredOtp.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter the 6-digit verification code.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
          return;
        }

        setState(() => _sendingOtp = true);
        try {
          final user = await ApiService.verifyOtp(
            email,
            enteredOtp,
            expectedRole: _selectedRole,
          );
          await auth.setUser(user);
          setState(() => _sendingOtp = false);
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          }
        } catch (e) {
          setState(() => _sendingOtp = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '').trim()),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        }
        return;
      }
    }

    final password = _passCtrl.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your official email or employee ID.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your security password.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final success = await auth.login(
      email,
      password,
      role: _selectedRole,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Authentication failed. Please verify credentials.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: kDeepObsidian,
      body: Stack(
        children: [
          // Background ambient gradient orbs
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kRoyalPurple.withOpacity(0.55),
                    kRoyalPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kSageEmerald.withOpacity(0.20),
                    kSageEmerald.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kFrostCyanAccent.withOpacity(0.18),
                    kFrostCyanAccent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // App Brand Crest Icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kRoyalPurple, kRoyalPurpleLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: kRoyalPurple.withOpacity(0.5),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: kFrostCyanAccent.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: kSoftLilac.withOpacity(0.4), width: 1.4),
                      ),
                      child: const Center(
                        child: Icon(Icons.account_balance_rounded, color: kFrostCyan, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'PCMS BankFlow',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Sovereign Pigmy Banking Gateway',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: kSoftLilac,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Security Chip Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: kSageEmerald.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kSageEmerald.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: kFrostCyan, size: 13),
                          SizedBox(width: 6),
                          Text(
                            '256-Bit SSL • RBI Sovereign Compliant',
                            style: TextStyle(
                              color: kFrostCyan,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Main White/Porcelain Form Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: kObsidianOnyx.withOpacity(0.35),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: kRoyalPurple.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: kSoftLilac, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sign-in Mode Switcher (Password vs OTP)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: kSoftLilacLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kSoftLilac),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _isOtpMode = false;
                                    _otpSent = false;
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9.5),
                                    decoration: BoxDecoration(
                                      color: !_isOtpMode ? kRoyalPurple : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_isOtpMode
                                          ? [
                                              BoxShadow(
                                                color: kRoyalPurple.withOpacity(0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Password Sign In',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: !_isOtpMode ? Colors.white : kRoyalPurple.withOpacity(0.75),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _isOtpMode = true;
                                    _otpSent = false;
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9.5),
                                    decoration: BoxDecoration(
                                      color: _isOtpMode ? kRoyalPurple : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _isOtpMode
                                          ? [
                                              BoxShadow(
                                                color: kRoyalPurple.withOpacity(0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'One-Time OTP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _isOtpMode ? Colors.white : kRoyalPurple.withOpacity(0.75),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Role Selector Chips
                        const Text(
                          'SELECT BANKING ROLE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: kRoyalPurple,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _roleConfigs.map((config) {
                            final isSelected = _selectedRole == config['name'];
                            return InkWell(
                              onTap: () => _selectRoleConfig(config),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                                decoration: BoxDecoration(
                                  color: isSelected ? kRoyalPurple : kSoftLilacLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? kRoyalPurple : kSoftLilac,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: kRoyalPurple.withOpacity(0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      config['icon'],
                                      size: 14,
                                      color: isSelected ? kFrostCyan : kRoyalPurple.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      config['label'],
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.white : kObsidianOnyx,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        const Text(
                          'OFFICIAL EMAIL / EMPLOYEE ID',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: kRoyalPurple,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailCtrl,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                          decoration: InputDecoration(
                            hintText: 'e.g. yourname@company.com',
                            hintStyle: TextStyle(color: kObsidianOnyx.withOpacity(0.35), fontSize: 13),
                            prefixIcon: const Icon(Icons.email_outlined, color: kRoyalPurple, size: 20),
                            filled: true,
                            fillColor: kPorcelain,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kRoyalPurple, width: 1.8)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (!_isOtpMode) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SECURITY PASSWORD',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: kRoyalPurple,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              GestureDetector(
                                onTap: _openForgotPasswordSheet,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kRoyalPurple),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: kObsidianOnyx.withOpacity(0.35)),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: kRoyalPurple, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: kRoyalPurple.withOpacity(0.6), size: 20),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                              filled: true,
                              fillColor: kPorcelain,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kRoyalPurple, width: 1.8)),
                            ),
                          ),
                        ] else ...[
                          if (_otpSent) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '6-DIGIT VERIFICATION CODE',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: kRoyalPurple,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _otpSent = false;
                                      _otpCtrl.clear();
                                    });
                                  },
                                  child: const Text(
                                    'Change Email',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kRoyalPurple),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _otpCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w900, color: kObsidianOnyx),
                              decoration: InputDecoration(
                                hintText: _generatedOtp ?? '123456',
                                prefixIcon: const Icon(Icons.pin_rounded, color: kSageEmerald),
                                filled: true,
                                fillColor: kFrostCyan.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSageEmerald)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSageEmerald)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kRoyalPurple, width: 2.0)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton.icon(
                                onPressed: _sendingOtp
                                    ? null
                                    : () async {
                                        setState(() => _sendingOtp = true);
                                        try {
                                          final res = await ApiService.sendOtp(_emailCtrl.text.trim());
                                          setState(() {
                                            _sendingOtp = false;
                                            _generatedOtp = res['otp']?.toString() ?? '123456';
                                          });
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('New OTP Sent: ${_generatedOtp ?? "123456"}'),
                                                backgroundColor: kSageEmerald,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setState(() => _sendingOtp = false);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.refresh_rounded, size: 14, color: kRoyalPurple),
                                label: const Text('Resend OTP Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kRoyalPurple)),
                              ),
                            ),
                          ]
                        ],
                        const SizedBox(height: 22),

                        // Authorize Button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kRoyalPurple, kRoyalPurpleLight],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: kRoyalPurple.withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: (auth.isLoading || _sendingOtp) ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: (auth.isLoading || _sendingOtp)
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isOtpMode
                                            ? (!_otpSent ? 'Send 6-Digit OTP' : 'Verify OTP & Enter Portal')
                                            : 'Authorize & Enter Portal',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _isOtpMode && !_otpSent ? Icons.send_rounded : Icons.arrow_forward_rounded,
                                        color: kFrostCyan,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Switch to Register Screen
                        Center(
                          child: TextButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: RichText(
                              text: const TextSpan(
                                text: "New to PCMS BankFlow? ",
                                style: TextStyle(fontSize: 13, color: Color(0xFF6B587B)),
                                children: [
                                  TextSpan(
                                    text: 'Open Account / Sign Up',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: kRoyalPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: kFrostCyan.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'ISO 27001 Certified • Vault Encrypted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kSoftLilac.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
