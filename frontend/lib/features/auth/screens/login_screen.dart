// ============================================================
// login_screen.dart — PCMS
// Multi-role, responsive login with OTP, Offline & Device Registration
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // State flags
  bool _otpVerified = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  // State flags
  UserRole _role = UserRole.collectionAgent;
  bool _useOtp = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  // Offline Simulation
  bool _isOffline = false;

  // OTP State
  bool _isOtpSent = false;
  String _generatedOtp = '';
  int _resendSeconds = 0;
  Timer? _resendTimer;

  String get _roleIdLabel {
    switch (_role) {
      case UserRole.admin:
        return 'Email / Admin ID';
      case UserRole.branchManager:
        return 'Email / Branch Manager ID';
      case UserRole.cashier:
        return 'Email / Cashier ID';
      case UserRole.collectionAgent:
        return 'Email / Collection Agent ID';
      case UserRole.auditor:
        return 'Email / Auditor ID';
    }
  }

  String get _roleIdHint {
    switch (_role) {
      case UserRole.admin:
        return 'Enter email or Admin ID';
      case UserRole.branchManager:
        return 'Enter email or Branch Manager ID';
      case UserRole.cashier:
        return 'Enter email or Cashier ID';
      case UserRole.collectionAgent:
        return 'Enter email or Collection Agent ID';
      case UserRole.auditor:
        return 'Enter email or Auditor ID';
    }
  }

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0,  end: -7.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0,  end: 7.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0,   end: 0.0),   weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _resendTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _sendOtp() async {
    final identifier = _phoneCtrl.text.trim();
    if (identifier.length < 3) {
      setState(() => _error = 'Please enter a valid Mobile Number, Email, or Employee ID.');
      _shakeCtrl.forward(from: 0);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final otpCode = await AuthService.instance.sendOtp(identifier);
    if (!mounted) return;

    if (otpCode == null) {
      setState(() {
        _loading = false;
        _error = 'Failed to request OTP. Please verify backend is running.';
      });
      _shakeCtrl.forward(from: 0);
      return;
    }

    setState(() {
      _loading = false;
      _isOtpSent = true;
      _generatedOtp = otpCode;
    });
    
    _startResendTimer();

    // Show mock SMS alert
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.sms_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'SMS Mock Dispatcher: OTP is ',
                style: const TextStyle(color: Colors.white),
                children: [
                  TextSpan(
                    text: otpCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppPalette.warning),
                  ),
                ],
              ),
            ),
          ),
        ]),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    // Simulate login delay
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final username = _useOtp ? _phoneCtrl.text.trim() : _userCtrl.text.trim();
    
    UserData? authenticatedUser;

    if (_useOtp) {
      if (!_otpVerified) {
        // Step 1: Client-side validation of OTP code
        if (_otpCtrl.text.trim() != _generatedOtp) {
          setState(() {
            _loading = false;
            _error = 'Invalid OTP entered. Please try again.';
          });
          _shakeCtrl.forward(from: 0);
          return;
        }

        // Transition UI to password reset fields
        setState(() {
          _loading = false;
          _otpVerified = true;
          _error = null;
        });
        return;
      } else {
        // Step 2: Validate password inputs
        final newPass = _newPassCtrl.text;
        final confirmPass = _confirmPassCtrl.text;

        if (newPass.isEmpty || confirmPass.isEmpty) {
          setState(() {
            _loading = false;
            _error = 'Please enter and confirm your new password.';
          });
          _shakeCtrl.forward(from: 0);
          return;
        }

        if (newPass.length < 6) {
          setState(() {
            _loading = false;
            _error = 'Password must be at least 6 characters.';
          });
          _shakeCtrl.forward(from: 0);
          return;
        }

        if (newPass != confirmPass) {
          setState(() {
            _loading = false;
            _error = 'Passwords do not match.';
          });
          _shakeCtrl.forward(from: 0);
          return;
        }

        // Call backend API reset-password-otp endpoint
        authenticatedUser = await AuthService.instance.resetPasswordWithOtp(
          username: username,
          code: _otpCtrl.text.trim(),
          newPassword: newPass,
          expectedRole: _role,
        );
      }
    } else {
      // Regular password login
      authenticatedUser = await AuthService.instance.login(
        email: username,
        password: _passCtrl.text,
        expectedRole: _role,
        isOffline: _isOffline,
      );
    }

    if (authenticatedUser == null) {
      setState(() {
        _loading = false;
        _error = _isOffline
            ? 'Offline login failed. No cached credentials match.'
            : (_useOtp ? 'Reset password failed. Please try again.' : 'Invalid credentials or role. Please try again.');
      });
      _shakeCtrl.forward(from: 0);
      return;
    }

    // Authentication succeeded. Now verify Device Registration.
    final isDeviceBound = await AuthService.instance.isDeviceRegisteredApi(username);
    if (!isDeviceBound) {
      setState(() => _loading = false);
      final registered = await _showDeviceRegistrationDialog(username);
      if (!registered) return; // canceled device binding, stop login
    }

    if (mounted) setState(() => _loading = false);
    
    // Select Dashboard target
    final target = _role == UserRole.collectionAgent
        ? const DashboardScreen()
        : const AdminDashboardScreen();

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => target));
    }
  }

  Future<bool> _showDeviceRegistrationDialog(String username) async {
    bool registered = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phonelink_lock_rounded, color: AppPalette.primary, size: 28),
            SizedBox(width: 12),
            Text('Device Unregistered'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This device is not bound to your account. First-time login requires device registration for collection security.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPalette.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppPalette.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device Name: Chrome Browser (Windows Desktop)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.instance.registerDevice(username);
              registered = true;
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary),
            child: const Text('Register & Bind Device'),
          ),
        ],
      ),
    );
    return registered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.primary,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (_, constraints) => constraints.maxWidth >= _kBreakpoint
              ? _buildWide()
              : _buildNarrow(),
        ),
      ),
    );
  }

  Widget _buildWide() => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(children: [
              _buildOfflineBar(),
              const _AppLogo(),
              const SizedBox(height: 20),
              _buildFormCard(flat: false),
              const SizedBox(height: 48),
            ]),
          ),
        ),
      );

  Widget _buildNarrow() => Column(children: [
        _buildOfflineBar(),
        const _AppLogo(),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppPalette.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: _buildFormCard(flat: true),
            ),
          ),
        ),
      ]);

  Widget _buildOfflineBar() => Container(
        color: _isOffline ? AppPalette.warning : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOffline ? Icons.cloud_off_rounded : Icons.cloud_queue_rounded,
              color: _isOffline ? Colors.black87 : Colors.white60,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _isOffline ? 'OFFLINE MODE SIMULATED' : 'ONLINE MODE CONNECTED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _isOffline ? Colors.black87 : Colors.white60,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isOffline,
              onChanged: (v) {
                setState(() {
                  _isOffline = v;
                  _error = null;
                });
              },
              activeColor: Colors.black87,
              activeTrackColor: Colors.black12,
              inactiveThumbColor: Colors.white60,
              inactiveTrackColor: Colors.white24,
            ),
          ],
        ),
      );

  Widget _buildFormCard({required bool flat}) {
    final formBody = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome header
          Text('Welcome back',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppPalette.textPrimary)),
          const SizedBox(height: 4),
          Text('Sign in to continue to PCMS',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppPalette.textSecondary)),
          const SizedBox(height: 20),

          // Method Tab
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppPalette.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _useOtp = false;
                    _otpVerified = false;
                    _error = null;
                  }),
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: !_useOtp ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                      boxShadow: !_useOtp
                          ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Password Login',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: !_useOtp ? AppPalette.primary : AppPalette.textSecondary,
                        fontWeight: !_useOtp ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _useOtp = true;
                    _otpVerified = false;
                    _error = null;
                  }),
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: _useOtp ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                      boxShadow: _useOtp
                          ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'OTP Login',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _useOtp ? AppPalette.primary : AppPalette.textSecondary,
                        fontWeight: _useOtp ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Role selection
          Text('Select Login Role', style: AppTextStyles.labelSmall.copyWith(color: AppPalette.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserRole.values.map((r) {
              final isSel = _role == r;
              return ChoiceChip(
                label: Text(r.label),
                selected: isSel,
                onSelected: _loading ? null : (selected) {
                  if (selected) setState(() => _role = r);
                },
                selectedColor: AppPalette.primaryContainer,
                labelStyle: AppTextStyles.caption.copyWith(
                  color: isSel ? AppPalette.primary : AppPalette.textSecondary,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppPalette.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Conditional Fields
          if (!_useOtp) ...[
            // Username Input
            TextFormField(
              controller: _userCtrl,
              enabled: !_loading,
              keyboardType: TextInputType.text, // support both phone digit inputs and text IDs
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _roleIdLabel,
                hintText: _roleIdHint,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email or ${_roleIdLabel.replaceAll("Email / ", "")} is required';
                }
                if (v.trim().length < 4) return 'Enter a valid login ID/email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Input
            TextFormField(
              controller: _passCtrl,
              enabled: !_loading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  color: AppPalette.textSecondary,
                  onPressed: _loading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),
            const SizedBox(height: 2),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : () => _showForgotDialog(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                child: const Text('Forgot Password?'),
              ),
            ),
          ] else ...[
            // OTP Flow inputs
            if (_otpVerified) ...[
              // Show Set New Password fields
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _otpVerified = false;
                              _newPassCtrl.clear();
                              _confirmPassCtrl.clear();
                            }),
                  ),
                  Text('Set New Password',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppPalette.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassCtrl,
                enabled: !_loading,
                obscureText: _obscureNewPass,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter at least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    color: AppPalette.textSecondary,
                    onPressed: _loading
                        ? null
                        : () => setState(() => _obscureNewPass = !_obscureNewPass),
                    tooltip: _obscureNewPass ? 'Show password' : 'Hide password',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassCtrl,
                enabled: !_loading,
                obscureText: _obscureConfirmPass,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Verify your new password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    color: AppPalette.textSecondary,
                    onPressed: _loading
                        ? null
                        : () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    tooltip: _obscureConfirmPass ? 'Show password' : 'Hide password',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Standard OTP field
              TextFormField(
                controller: _phoneCtrl,
                enabled: !_loading && !_isOtpSent,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Email / Employee ID',
                  hintText: 'Enter registered Email or ID',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: _isOtpSent
                      ? TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _isOtpSent = false;
                                    _otpCtrl.clear();
                                  }),
                          child: const Text('Change'),
                        )
                      : null,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Account ID is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isOtpSent) ...[
                TextFormField(
                  controller: _otpCtrl,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-Digit OTP',
                    hintText: 'Enter received code',
                    prefixIcon: Icon(Icons.message_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Verification code is required';
                    if (v.trim().length != 6) return 'Must be 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _resendSeconds > 0
                          ? 'Resend OTP in ${_resendSeconds}s'
                          : 'Didn\'t receive OTP?',
                      style: AppTextStyles.bodySmall,
                    ),
                    TextButton(
                      onPressed: _resendSeconds > 0 || _loading ? null : _sendOtp,
                      child: const Text('Resend Code'),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: const Text('Send Verification OTP'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ],

          // Error Display with shake transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim, axisAlignment: -1, child: child),
            child: _error != null
                ? AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0), child: child),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppPalette.errorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppPalette.error.withOpacity(0.35), width: 1),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.error_outline_rounded, color: AppPalette.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.bodySmall.copyWith(color: AppPalette.onErrorContainer)),
                          ),
                        ]),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Main Submit login Button
          if (!_useOtp || _isOtpSent) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ))
                    : Text(_useOtp
                        ? (_otpVerified ? 'Update Password & Login' : 'Verify OTP & Continue')
                        : 'Sign In'),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Register text link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account? ",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppPalette.textSecondary)),
              InkWell(
                onTap: _loading ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text('Register',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppPalette.primary, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Demo Info box
          _DemoHint(role: _role),
        ],
      ),
    );

    if (flat) return formBody;

    return DecoratedBox(
      decoration: appCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppPalette.surface,
      ),
      child: Padding(padding: const EdgeInsets.all(32), child: formBody),
    );
  }

  void _showForgotDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter your registered mobile number and we\'ll send a reset code.',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset link sent to your mobile number.')),
              );
            },
            child: const Text('Send Reset OTP'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _AppLogo
// ─────────────────────────────────────────────────────────────
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.account_balance_rounded,
                color: AppPalette.primary, size: 36),
          ),
        ),
        const SizedBox(height: 14),
        Text('PCMS',
            style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Payment Collection Management System',
            style: AppTextStyles.caption.copyWith(color: Colors.white60),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _DemoHint  — displays credentials dynamically based on role
// ─────────────────────────────────────────────────────────────
class _DemoHint extends StatelessWidget {
  final UserRole role;
  const _DemoHint({required this.role});

  String get _demoCredentials {
    switch (role) {
      case UserRole.collectionAgent: return '9999999999 / pass@123';
      case UserRole.admin:           return '8888888888 / pass@123';
      case UserRole.branchManager:   return '7777777777 / pass@123';
      case UserRole.cashier:         return '6666666666 / pass@123';
      case UserRole.auditor:         return '5555555555 / pass@123';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            size: 14, color: AppPalette.onPrimaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.caption
                  .copyWith(color: AppPalette.onPrimaryContainer),
              children: [
                TextSpan(text: 'Demo for ${role.label}: '),
                TextSpan(
                    text: _demoCredentials,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

const _kBreakpoint = 600.0;
