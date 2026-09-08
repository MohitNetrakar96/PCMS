// ============================================================
// register_screen.dart — PCMS
// Responsive registration page matching login screen design
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  UserRole _role = UserRole.collectionAgent;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _loading = false;
  String? _error;

  String get _roleIdLabel {
    switch (_role) {
      case UserRole.admin:
        return 'Admin ID (Optional)';
      case UserRole.branchManager:
        return 'Branch Manager ID (Optional)';
      case UserRole.cashier:
        return 'Cashier ID (Optional)';
      case UserRole.collectionAgent:
        return 'Collection Agent ID (Optional)';
      case UserRole.auditor:
        return 'Auditor ID (Optional)';
    }
  }

  String get _roleIdHint {
    switch (_role) {
      case UserRole.admin:
        return 'Enter admin ID';
      case UserRole.branchManager:
        return 'Enter branch manager ID';
      case UserRole.cashier:
        return 'Enter cashier ID';
      case UserRole.collectionAgent:
        return 'Enter collection agent ID';
      case UserRole.auditor:
        return 'Enter auditor ID';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _empIdCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    // Simulate small latency
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final success = await AuthService.instance.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      role: _role,
      employeeId: _empIdCtrl.text.trim().isEmpty ? null : _empIdCtrl.text.trim(),
    );

    setState(() {
      _loading = false;
    });

    if (!success) {
      setState(() {
        _error = 'Registration failed. Email or Employee ID may already be registered.';
      });
      return;
    }

    // Success dialog and navigation back
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppPalette.success, size: 28),
            SizedBox(width: 12),
            Text('Success'),
          ],
        ),
        content: const Text(
            'Your account has been registered successfully. You can now login using your credentials.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Pop dialog
              Navigator.pop(context); // Go back to login screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const breakpoint = 600.0;
    
    return Scaffold(
      backgroundColor: AppPalette.primary,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (_, constraints) => constraints.maxWidth >= breakpoint
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
            constraints: const BoxConstraints(maxWidth: 464),
            child: Column(children: [
              const _AppLogoHeader(),
              const SizedBox(height: 24),
              _buildFormCard(flat: false),
              const SizedBox(height: 48),
            ]),
          ),
        ),
      );

  Widget _buildNarrow() => Column(children: [
        const _AppLogoHeader(),
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

  Widget _buildFormCard({required bool flat}) {
    final formBody = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text('Create Account',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppPalette.textPrimary)),
          const SizedBox(height: 4),
          Text('Sign up to join PCMS system',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppPalette.textSecondary)),
          const SizedBox(height: 24),

          // Role selection
          _RoleSelector(
            selected: _role,
            onChanged: (r) => setState(() => _role = r),
            enabled: !_loading,
          ),
          const SizedBox(height: 20),

          // Full Name
          TextFormField(
            controller: _nameCtrl,
            enabled: !_loading,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Full name is required';
              if (v.trim().length < 2) return 'Enter a valid name';
              return null;
            },
          ),


          // Email Address
          TextFormField(
            controller: _emailCtrl,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email address is required';
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Employee ID (Optional)
          TextFormField(
            controller: _empIdCtrl,
            enabled: !_loading,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: _roleIdLabel,
              hintText: _roleIdHint,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passCtrl,
            enabled: !_loading,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                color: AppPalette.textSecondary,
                onPressed: _loading ? null : () => setState(() => _obscurePass = !_obscurePass),
                tooltip: _obscurePass ? 'Show password' : 'Hide password',
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmPassCtrl,
            enabled: !_loading,
            obscureText: _obscureConfirmPass,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _register(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                color: AppPalette.textSecondary,
                onPressed: _loading ? null : () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                tooltip: _obscureConfirmPass ? 'Show password' : 'Hide password',
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Error Display
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppPalette.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_error!,
                      style: AppTextStyles.caption.copyWith(color: AppPalette.onErrorContainer, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Register button
          ElevatedButton(
            onPressed: _loading ? null : _register,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Register'),
          ),
          const SizedBox(height: 20),

          // Sign In text link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? ",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppPalette.textSecondary)),
              InkWell(
                onTap: _loading ? null : () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text('Sign In',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppPalette.primary, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (flat) return formBody;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated,
      ),
      child: formBody,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _AppLogoHeader  — matching login header logo style
// ─────────────────────────────────────────────────────────────
class _AppLogoHeader extends StatelessWidget {
  const _AppLogoHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: const Center(
            child: Icon(Icons.account_balance_rounded, color: AppPalette.primary, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text('PCMS',
            style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Payment Collection Management System',
            style: AppTextStyles.caption.copyWith(color: Colors.white60),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _RoleSelector  — role picker ChoiceChips Wrap
// ─────────────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registering as',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppPalette.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UserRole.values.map((r) {
                final isSel = selected == r;
                return ChoiceChip(
                  label: Text(r.label),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) onChanged(r);
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
          ],
        ),
      ),
    );
  }
}
