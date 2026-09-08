import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  String _selectedRole = 'Collection Agent';
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _loading = false;
  bool _agreedToTerms = true;
  String? _error;

  // Custom Sovereign Palette
  static const Color kRoyalPurple = Color(0xFF55356E);
  static const Color kRoyalPurpleLight = Color(0xFF6F468E);
  static const Color kDeepObsidian = Color(0xFF28153A);
  static const Color kObsidianOnyx = Color(0xFF191308);
  static const Color kSoftLilac = Color(0xFFE9E2F3);
  static const Color kFrostCyan = Color(0xFFD6F5FF);
  static const Color kSageEmerald = Color(0xFF76A787);
  static const Color kSageEmeraldLight = Color(0xFFE6F4EB);
  static const Color kPorcelain = Color(0xFFF7F4FA);

  final List<String> _roles = [
    'Collection Agent',
    'Branch Manager',
    'Cashier',
    'Administrator',
    'Customer',
    'Auditor'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _empIdCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the banking compliance terms to proceed.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        role: _selectedRole,
        employeeId: _empIdCtrl.text.trim().isEmpty ? null : _empIdCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: kSageEmeraldLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: kSageEmerald, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Account Created', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDeepObsidian)),
            ],
          ),
          content: Text(
            res['message'] ?? 'Your banking credentials have been registered. You may now sign in.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF584869)),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRoyalPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Proceed to Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepObsidian,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kFrostCyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Open Sovereign Account',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kSageEmerald.withOpacity(0.22),
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
                    kRoyalPurple.withOpacity(0.35),
                    kRoyalPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Security Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: kRoyalPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kSoftLilac.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: kFrostCyan, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Core Banking Onboarding • Instant Verification',
                              style: TextStyle(color: kFrostCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Main White Card
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
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Legal Full Name
                          const Text(
                            'LEGAL FULL NAME (AS ON ID)',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                            decoration: InputDecoration(
                              hintText: 'e.g. Rahul Sharma',
                              hintStyle: TextStyle(color: kObsidianOnyx.withOpacity(0.35), fontSize: 13),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: kRoyalPurple, size: 20),
                              filled: true,
                              fillColor: kPorcelain,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kRoyalPurple, width: 1.8)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter legal full name' : null,
                          ),

                          const SizedBox(height: 14),

                          // Official Email
                          const Text(
                            'OFFICIAL EMAIL ADDRESS',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                            decoration: InputDecoration(
                              hintText: 'e.g. rahul@bankflow.com',
                              hintStyle: TextStyle(color: kObsidianOnyx.withOpacity(0.35), fontSize: 13),
                              prefixIcon: const Icon(Icons.email_outlined, color: kRoyalPurple, size: 20),
                              filled: true,
                              fillColor: kPorcelain,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kRoyalPurple, width: 1.8)),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter email address';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Role & Branch Code Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ACCOUNT ROLE',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: kPorcelain,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: kSoftLilac),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedRole,
                                          isExpanded: true,
                                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: kObsidianOnyx)))).toList(),
                                          onChanged: (v) {
                                            if (v != null) setState(() => _selectedRole = v);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'BRANCH CODE',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _empIdCtrl,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kObsidianOnyx),
                                      decoration: InputDecoration(
                                        hintText: 'BR01',
                                        hintStyle: TextStyle(color: kObsidianOnyx.withOpacity(0.35)),
                                        filled: true,
                                        fillColor: kPorcelain,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kRoyalPurple, width: 1.8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Password
                          const Text(
                            'CREATE PASSWORD',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                            decoration: InputDecoration(
                              hintText: 'Min 6 characters',
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
                            validator: (v) => v != null && v.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),

                          const SizedBox(height: 14),

                          // Confirm Password
                          const Text(
                            'CONFIRM PASSWORD',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kRoyalPurple, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPassCtrl,
                            obscureText: _obscureConfirmPass,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kObsidianOnyx),
                            decoration: InputDecoration(
                              hintText: 'Re-enter password',
                              hintStyle: TextStyle(color: kObsidianOnyx.withOpacity(0.35)),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: kRoyalPurple, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, color: kRoyalPurple.withOpacity(0.6), size: 20),
                                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                              ),
                              filled: true,
                              fillColor: kPorcelain,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kSoftLilac)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kRoyalPurple, width: 1.8)),
                            ),
                            validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                          ),

                          const SizedBox(height: 14),

                          // Compliance Agreement
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                activeColor: kSageEmerald,
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _agreedToTerms = v ?? true),
                              ),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'I agree to the BankFlow Sovereign Security Terms & RBI KYC Audit Protocol.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF6B587B), height: 1.3),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Submit Button
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
                              onPressed: _loading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Create Sovereign Account',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.check_circle_outline_rounded, color: kFrostCyan, size: 18),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Back to Sign In
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? ', style: TextStyle(fontSize: 13, color: Color(0xFF6B587B))),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Sign In Here',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kRoyalPurple),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
