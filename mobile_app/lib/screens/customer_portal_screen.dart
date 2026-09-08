import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/receipt_dialog.dart';
import '../../widgets/titanium_card.dart';

class CustomerPortalScreen extends StatefulWidget {
  const CustomerPortalScreen({super.key});

  @override
  State<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends State<CustomerPortalScreen> {
  Map<String, dynamic>? _interestData;
  Map<String, dynamic>? _passbookData;
  bool _loading = true;
  final TextEditingController _depositAmtCtrl = TextEditingController(text: '500');

  @override
  void initState() {
    super.initState();
    _loadCustomerPortalData();
  }

  @override
  void dispose() {
    _depositAmtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerPortalData() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final passbook = await ApiService.getPassbooks();
      final accounts = (passbook['accounts'] as List?) ?? [];

      dynamic targetAccId;
      if (accounts.isNotEmpty) {
        final match = accounts.firstWhere(
          (a) =>
              (auth.user != null && a['customer_id']?.toString() == auth.user!.id.toString()) ||
              (a['customer_email'] != null && a['customer_email'].toString().toLowerCase() == auth.email.toLowerCase()),
          orElse: () => accounts[0],
        );
        targetAccId = match['id'];
      }

      Map<String, dynamic>? data;
      if (targetAccId != null) {
        try {
          data = await ApiService.getInterestHistory(targetAccId);
        } catch (_) {}
      }

      setState(() {
        _interestData = data;
        _passbookData = passbook;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final balance = (_interestData?['currentBalance'] as num?)?.toDouble() ?? 5000.0;
    final rate = _interestData?['interestRate'] ?? 4.5;
    final daysLeft = _interestData?['daysToMaturity'] ?? 365;
    final projected = (_interestData?['projectedPayout'] as num?)?.toDouble() ?? (balance * 1.045);
    final totalAccrued = (_interestData?['totalAccruedInterest'] as num?)?.toDouble() ?? 37.50;
    final accNumber = _interestData?['accountNumber'] ?? 'PCMS-00120';
    final transactions = (_passbookData?['recentTransactions'] as List?) ?? [];

    final depositAmt = _depositAmtCtrl.text.isNotEmpty ? _depositAmtCtrl.text : '500';
    final upiUrl = 'upi://pay?pa=pcmsbank@upi&pn=BankFlow+PCMS&am=$depositAmt&tn=Deposit+$accNumber';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadCustomerPortalData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3D Titanium Holographic Card
              TitaniumCard(
                title: 'Pigmy Passbook A/C',
                balance: '₹ ${balance.toStringAsFixed(2)}',
                accountNumber: accNumber,
                accountHolder: 'SAVINGS DEPOSITOR',
                interestRate: '$rate%',
              ),

              // Maturity & Yield Breakdown Card
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF312E81).withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Maturity Countdown & Projection',
                          style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                          ),
                          child: Text(
                            '⏳ $daysLeft Days Left',
                            style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ((365 - daysLeft.clamp(0, 365)) / 365).clamp(0.05, 1.0),
                        minHeight: 7,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Accrued Interest', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                            const SizedBox(height: 2),
                            Text('₹${totalAccrued.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Projected Payout', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                            const SizedBox(height: 2),
                            Text('₹${projected.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Instant Self-Deposit via Dynamic UPI QR
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF16A34A), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Instant Self-Deposit via UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                              Text('Pay with GPay / PhonePe / Paytm / BHIM', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Amount input & quick presets
                    const Text('Select or Enter Deposit Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _depositAmtCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF2563EB), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPresetButton(100),
                        const SizedBox(width: 6),
                        _buildPresetButton(200),
                        const SizedBox(width: 6),
                        _buildPresetButton(500),
                        const SizedBox(width: 6),
                        _buildPresetButton(1000),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dynamic QR Code Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: QrImageView(
                              data: upiUrl,
                              version: QrVersions.auto,
                              size: 160.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('Deposit: ₹$depositAmt · VPA: pcmsbank@upi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          const SizedBox(height: 4),
                          const Text('Scan & Pay directly from your mobile UPI app', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Passbook Transaction History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Passbook Transaction History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('${transactions.length} entries', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),

              if (transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No deposit transactions recorded yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              else
                ...transactions.map((tx) {
                  final amt = (tx['amount'] as num?)?.toDouble() ?? 500.0;
                  final date = tx['collection_date'] ?? DateTime.now().toString().split(' ')[0];
                  final mode = tx['payment_mode'] ?? 'CASH';
                  final receiptId = tx['receipt_id'] ?? 'RCP-2026-0001';

                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF16A34A), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deposit Received ($mode)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('$date · Ref: $receiptId', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+₹${amt.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF16A34A)),
                            ),
                            InkWell(
                              onTap: () {
                                ReceiptDialog.show(context, {
                                  'receiptId': receiptId,
                                  'customerName': 'Account Holder',
                                  'account': accNumber,
                                  'amount': amt,
                                  'paymentMode': mode,
                                  'balance': balance,
                                  'date': date,
                                  'time': '10:00 AM',
                                });
                              },
                              child: const Text('Receipt >', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(int amt) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _depositAmtCtrl.text = amt.toString();
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('₹$amt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
      ),
    );
  }
}
