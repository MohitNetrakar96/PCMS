import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/collection_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/signature_pad_widget.dart';
import '../../widgets/denomination_dialog.dart';

class VaultHandoverScreen extends StatefulWidget {
  const VaultHandoverScreen({super.key});

  @override
  State<VaultHandoverScreen> createState() => _VaultHandoverScreenState();
}

class _VaultHandoverScreenState extends State<VaultHandoverScreen> {
  int _currentStep = 0;
  final _cashSubmittedCtrl = TextEditingController(text: '4500');
  final _expectedCashCtrl = TextEditingController(text: '4500');
  final _managerOtpCtrl = TextEditingController();
  final _bankRefCtrl = TextEditingController(text: 'SBI-DEP-984321');
  bool _cashierSigned = false;
  bool _loading = false;
  double _difference = 0.0;
  String? _otpSent;

  String _getAgentEmail() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.email.isNotEmpty ? auth.email : 'agent@bankflow.com';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVaultState();
    });
  }

  Future<void> _loadVaultState() async {
    final email = _getAgentEmail();
    final branch = Provider.of<BranchProvider>(context, listen: false);
    final coll = Provider.of<CollectionProvider>(context, listen: false);

    if (coll.totalCollected > 0) {
      _expectedCashCtrl.text = coll.totalCollected.toStringAsFixed(0);
      _cashSubmittedCtrl.text = coll.totalCollected.toStringAsFixed(0);
    }

    await branch.fetchVaultToday(email);
    final vault = branch.vaultToday;
    if (vault != null && vault.status != 'not_submitted') {
      _cashSubmittedCtrl.text = vault.cashSubmitted.toInt().toString();
      _expectedCashCtrl.text = vault.expectedCash.toInt().toString();
      _difference = vault.differenceAmount;
      if (vault.status == 'locked') {
        _currentStep = 4;
      } else if (vault.cashierAccepted) {
        _currentStep = 3;
      } else if (vault.managerOtpVerified || _difference == 0) {
        _currentStep = 2;
      } else {
        _currentStep = 1;
      }
      if (mounted) setState(() {});
    }
  }

  // Step 1: Submit cash
  void _submitCash() async {
    final email = _getAgentEmail();
    final submitted = double.tryParse(_cashSubmittedCtrl.text) ?? 0.0;
    final expected = double.tryParse(_expectedCashCtrl.text) ?? 0.0;
    setState(() {
      _difference = submitted - expected;
      _loading = true;
    });

    try {
      final res = await ApiService.submitVaultCash(
        agentEmail: email,
        cashSubmitted: submitted,
        expectedCash: expected,
      );

      setState(() {
        _loading = false;
        if (_difference != 0) {
          _currentStep = 1; // Needs manager OTP
        } else {
          _currentStep = 2; // Jump directly to Cashier Acceptance
        }
      });

      if (_difference != 0) {
        // Request manager OTP
        final otpRes = await ApiService.requestManagerOtp(
          agentEmail: email,
          difference: _difference,
        );
        setState(() {
          _otpSent = otpRes['otp']?.toString();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variance detected (₹$_difference). Manager Approval OTP: $_otpSent'),
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Step 2: Verify Manager OTP
  void _verifyManagerOtp() async {
    final email = _getAgentEmail();
    setState(() => _loading = true);
    try {
      final success = await ApiService.verifyManagerOtp(
        agentEmail: email,
        otpCode: _managerOtpCtrl.text.trim().isNotEmpty ? _managerOtpCtrl.text.trim() : (_otpSent ?? '1234'),
      );
      setState(() {
        _loading = false;
        if (success) _currentStep = 2;
      });
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manager Clearance Verified ✓'), backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid code: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Step 3: Cashier Digital Acceptance
  void _cashierAccept() async {
    final email = _getAgentEmail();
    setState(() => _loading = true);
    try {
      final success = await ApiService.cashierAcceptVault(
        agentEmail: email,
        signatureUrl: 'cashier_sig_verified_${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() {
        _loading = false;
        if (success) _currentStep = 3;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // Step 4: Bank Deposit Slip
  void _sealLedger() async {
    final email = _getAgentEmail();
    setState(() => _loading = true);
    try {
      final success = await ApiService.bankDepositSlip(
        agentEmail: email,
        bankReference: _bankRefCtrl.text.trim(),
      );
      setState(() {
        _loading = false;
        if (success) _currentStep = 4;
      });
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Day Ledger Sealed & Locked ✓'), backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('EOD Vault Settlement Workflow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper indicator
            _buildStepper(),
            const SizedBox(height: 20),

            // Step 0: Cash Submission
            if (_currentStep == 0) ...[
              _buildSectionCard(
                title: 'Step 1: Physical Cash Handover',
                subtitle: 'Agent enters submitted cash vs system expected collections.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expected Cash Collection (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _expectedCashCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Physical Cash Submitted (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cashSubmittedCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            DenominationDialog.show(
                              context,
                              double.tryParse(_expectedCashCtrl.text) ?? 4500,
                              (tot, counts) {
                                setState(() {
                                  _cashSubmittedCtrl.text = tot.toInt().toString();
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.calculate_rounded, size: 16),
                          label: const Text('Open Denomination Counter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitCash,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit for Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step 1: Manager OTP Clearance (if variance)
            if (_currentStep == 1) ...[
              _buildSectionCard(
                title: 'Step 2: Manager Variance Clearance',
                subtitle: 'A difference of ₹${_difference.toStringAsFixed(2)} was detected. Enter the 4-digit approval code.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_otpSent != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          'Manager Variance Code: $_otpSent',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), fontSize: 13),
                        ),
                      ),
                    TextField(
                      controller: _managerOtpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter 4-digit code (e.g. ${_otpSent ?? "1234"})',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verifyManagerOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Verify Manager Code', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step 2: Cashier Physical Acceptance & Signature
            if (_currentStep == 2) ...[
              _buildSectionCard(
                title: 'Step 3: Cashier Physical Vault Acceptance',
                subtitle: 'Cashier signs off on receiving physical cash into the main vault.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        'Total Cash Verified: ₹${_cashSubmittedCtrl.text} ✓',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Cashier Signature Pad', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SignaturePadWidget(
                      onSigned: (points) => setState(() => _cashierSigned = points.isNotEmpty),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _cashierAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept Cash into Vault', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step 3: Bank Deposit Reference Slip
            if (_currentStep == 3) ...[
              _buildSectionCard(
                title: 'Step 4: Bank Deposit Reference Slip',
                subtitle: 'Enter the bank deposit slip reference number to seal day register.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bank Slip Number / Reference', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bankRefCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. SBI-DEP-984321',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sealLedger,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Seal & Lock Day Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step 4: Final Day Closure Success
            if (_currentStep == 4) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('Day Ledger Locked & Sealed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Text('Bank Ref: ${_bankRefCtrl.text} · Vault Closed', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Cashier Desk'),
                    )
                  ],
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepIndicator(0, 'Submit'),
        _buildStepDivider(),
        _buildStepIndicator(1, 'Clearance'),
        _buildStepDivider(),
        _buildStepIndicator(2, 'Accept'),
        _buildStepDivider(),
        _buildStepIndicator(3, 'Bank Slip'),
        _buildStepDivider(),
        _buildStepIndicator(4, 'Locked'),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? const Color(0xFF16A34A)
                  : isCurrent
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFCBD5E1),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text('${stepIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 12,
      height: 2,
      color: const Color(0xFFCBD5E1),
      margin: const EdgeInsets.only(bottom: 14),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Widget child}) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
