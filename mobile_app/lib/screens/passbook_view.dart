import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/customer_model.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../services/api_service.dart';
import '../services/payment_config_service.dart';
import '../widgets/agent_qr_config_sheet.dart';
import '../widgets/titanium_card.dart';
import '../widgets/receipt_dialog.dart';

class PassbookView extends StatefulWidget {
  final String? initialCustomerId;
  const PassbookView({super.key, this.initialCustomerId});

  @override
  State<PassbookView> createState() => _PassbookViewState();
}

class _PassbookViewState extends State<PassbookView> {
  // Agent Passbook Data
  Map<String, dynamic>? _agentPassbookData;
  List<dynamic> _agentTransactions = [];

  // Customer Passbook Data
  Map<String, dynamic>? _customerData;
  Map<String, dynamic>? _customerAccount;
  List<dynamic> _customerTransactions = [];

  bool _loading = true;
  bool _submittingDeposit = false;
  double _depositAmount = 500.0;
  String _paymentMode = 'CASH';

  // Agent Custom Payment Scanner Configuration
  String _agentUpiVpa = 'bankflow@upi';
  String _agentUpiName = 'BankFlow Pigmy Deposit';
  String? _agentCustomQrImageBase64;
  String _agentQrMode = 'DYNAMIC';

  final TextEditingController _customAmountCtrl = TextEditingController(text: '500');
  Timer? _realtimeTimer;

  // Selected customer for quick agent collection
  List<CustomerModel> _assignedCustomers = [];
  String? _selectedCollectCustomerId;

  @override
  void initState() {
    super.initState();
    _loadUpiConfig();
    _loadPassbookData();

    // Real-time polling timer every 5 seconds to update passbook live
    _realtimeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _silentRefreshData();
      }
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _customAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUpiConfig() async {
    final vpa = await PaymentConfigService.getUpiVpa();
    final name = await PaymentConfigService.getUpiName();
    final img = await PaymentConfigService.getCustomQrImageBase64();
    final mode = await PaymentConfigService.getQrMode();
    if (mounted) {
      setState(() {
        _agentUpiVpa = vpa;
        _agentUpiName = name;
        _agentCustomQrImageBase64 = img;
        _agentQrMode = mode;
      });
    }
  }

  Future<void> _silentRefreshData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.role.toLowerCase();

    if (role.contains('customer')) {
      final res = await ApiService.getCustomerMyPassbook(
        email: auth.email,
        phone: auth.phone,
      );
      if (res.isNotEmpty && mounted) {
        setState(() {
          _customerData = res['customer'];
          _customerAccount = res['account'];
          _customerTransactions = res['history'] ?? [];
        });
      }
    } else {
      final res = await ApiService.getAgentPassbook(auth.email);
      if (res.isNotEmpty && mounted) {
        setState(() {
          _agentPassbookData = res;
          _agentTransactions = res['transactions'] ?? [];
        });
      }
    }
  }

  Future<void> _loadPassbookData() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.role.toLowerCase();

    try {
      if (role.contains('customer')) {
        // Load only the logged-in customer's passbook
        final res = await ApiService.getCustomerMyPassbook(
          email: auth.email,
          phone: auth.phone,
        );
        if (mounted) {
          setState(() {
            _customerData = res['customer'];
            _customerAccount = res['account'];
            _customerTransactions = res['history'] ?? [];
            _loading = false;
          });
        }
      } else {
        // Load the agent's dedicated collection passbook
        final passbookRes = await ApiService.getAgentPassbook(auth.email);
        final customers = await ApiService.getCustomers();

        if (mounted) {
          setState(() {
            _agentPassbookData = passbookRes;
            _agentTransactions = passbookRes['transactions'] ?? [];
            _assignedCustomers = customers;
            if (customers.isNotEmpty) {
              _selectedCollectCustomerId = customers.first.id;
            }
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recordDeposit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.role.toLowerCase();
    final provider = Provider.of<CollectionProvider>(context, listen: false);

    final amount = double.tryParse(_customAmountCtrl.text) ?? _depositAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount.')),
      );
      return;
    }

    String custId = '';
    String custName = 'Customer';
    if (role.contains('customer')) {
      custId = _customerData?['id'] ?? 'CUST-101';
      custName = _customerData?['name'] ?? auth.name;
    } else {
      if (_selectedCollectCustomerId == null && _assignedCustomers.isNotEmpty) {
        _selectedCollectCustomerId = _assignedCustomers.first.id;
      }
      custId = _selectedCollectCustomerId ?? 'CUST-101';
      final found = _assignedCustomers.firstWhere((c) => c.id == custId, orElse: () => _assignedCustomers.first);
      custName = found.name;
    }

    setState(() => _submittingDeposit = true);

    try {
      final res = await provider.recordDeposit(
        customerId: custId,
        agentEmail: auth.email,
        status: 'collected',
        collectedAmount: amount,
        depositTotal: amount,
        paymentMode: _paymentMode,
        remarks: 'Passbook digital deposit',
      );

      setState(() => _submittingDeposit = false);

      if (res != null && mounted) {
        await _loadPassbookData();

        final receiptId = res['receipt_id'] ?? res['receiptId'] ?? 'RCP-${DateTime.now().millisecondsSinceEpoch}';
        ReceiptDialog.show(
          context,
          {
            'receiptId': receiptId,
            'customerName': custName,
            'accountNumber': 'PG-2026-${custId.replaceAll("CUST-", "")}',
            'amount': amount,
            'date': DateTime.now().toString().split(' ')[0],
            'time': DateTime.now().toString().split(' ')[1].substring(0, 5),
            'paymentMode': _paymentMode,
            'agentName': auth.name,
            'balance': (_agentPassbookData?['totalCollectedToday'] as num?)?.toDouble() ?? amount,
          },
        );
      }
    } catch (e) {
      setState(() => _submittingDeposit = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deposit recording failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _deleteTransaction(dynamic tx) async {
    final id = tx['id'] ?? tx['receipt_id'] ?? tx['receiptId'];
    final customerName = tx['customerName'] ?? tx['customer_name'] ?? 'Customer';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final receipt = tx['receiptId'] ?? tx['receipt_id'] ?? 'Receipt';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text('Delete History Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF191308))),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this collection record?\n\n• Customer: $customerName\n• Amount: ₹${amount.toStringAsFixed(2)}\n• Receipt: $receipt',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting history record...'), duration: Duration(seconds: 1)),
      );
      final success = await ApiService.deleteHistoryItem(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Collection history record deleted successfully.'), backgroundColor: Color(0xFF16A34A)),
          );
          await _loadPassbookData();
          final auth = Provider.of<AuthProvider>(context, listen: false);
          Provider.of<CollectionProvider>(context, listen: false).fetchTodayCollections(auth.email);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete history record.'), backgroundColor: Color(0xFFDC2626)),
          );
        }
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 10),
            Text('Clear All History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF191308))),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete ALL collection history statements and reset the day passbook?',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clearing all history...'), duration: Duration(seconds: 1)),
      );
      final success = await ApiService.clearAllHistory();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ All history cleared successfully.'), backgroundColor: Color(0xFF16A34A)),
          );
          await _loadPassbookData();
          final auth = Provider.of<AuthProvider>(context, listen: false);
          Provider.of<CollectionProvider>(context, listen: false).fetchTodayCollections(auth.email);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear history.'), backgroundColor: Color(0xFFDC2626)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F4FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF55356E))),
      );
    }

    final auth = Provider.of<AuthProvider>(context);
    final role = auth.role.toLowerCase();

    if (role.contains('customer')) {
      return _buildCustomerPassbookView(auth);
    } else {
      return _buildAgentPassbookView(auth);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1. AGENT DEDICATED PASSBOOK & REAL-TIME STATEMENT VIEW
  // ─────────────────────────────────────────────────────────────

  Widget _buildAgentPassbookView(AuthProvider auth) {
    final agentInfo = _agentPassbookData?['agent'] as Map<String, dynamic>?;
    final totalCollected = (_agentPassbookData?['totalCollectedToday'] as num?)?.toDouble() ?? 0.0;
    final cashCollected = (_agentPassbookData?['totalCashToday'] as num?)?.toDouble() ?? 0.0;
    final upiCollected = (_agentPassbookData?['totalUpiToday'] as num?)?.toDouble() ?? 0.0;
    final targetToday = (_agentPassbookData?['totalTargetToday'] as num?)?.toDouble() ?? 2500.0;
    final completedStops = _agentPassbookData?['completedStops'] ?? 0;
    final totalStops = _agentPassbookData?['totalStops'] ?? 0;
    final commissionEarned = (_agentPassbookData?['commissionEarned'] as num?)?.toDouble() ?? 0.0;
    final accNumber = _agentPassbookData?['accountNumber'] ?? 'PB-AGT-CAG301';

    final agentName = agentInfo?['name'] ?? auth.name;
    final agentArea = agentInfo?['area'] ?? auth.area ?? 'Sector 12';
    final agentRoute = agentInfo?['route'] ?? auth.route ?? 'Route A';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      body: RefreshIndicator(
        onRefresh: _loadPassbookData,
        color: const Color(0xFF55356E),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Live Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Agent Ledger • $agentArea',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF76A787).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚡ Live Real-Time',
                      style: TextStyle(color: Color(0xFF16A34A), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Titanium Agent Passbook Card
            TitaniumCard(
              title: 'AGENT COLLECTION PASSBOOK • $accNumber',
              balance: '₹ ${totalCollected.toStringAsFixed(2)}',
              accountNumber: accNumber,
              accountHolder: '${agentName.toUpperCase()} (COLLECTION AGENT)',
              interestRate: '2.0% Commission (₹${commissionEarned.toStringAsFixed(2)})',
            ),
            const SizedBox(height: 16),

            // Real-time Field Performance Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF191308),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF55356E), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A55356E), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Collection Target & Progress',
                          style: TextStyle(color: Color(0xFFD6F5FF), fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF55356E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$agentRoute · $completedStops/$totalStops Done',
                          style: const TextStyle(color: Color(0xFFD6F5FF), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: targetToday > 0 ? (totalCollected / targetToday).clamp(0.0, 1.0) : 0.0,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF76A787)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cash in Hand', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          Text('💵 ₹${cashCollected.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF76A787), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Digital UPI Received', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          Text('📱 ₹${upiCollected.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD6F5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Commission Earned', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          Text('₹${commissionEarned.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD6F5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Agent Collection Statement Ledger
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: const [
                            Icon(Icons.auto_stories, color: Color(0xFF55356E), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Collection Statement',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF191308)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_agentTransactions.isNotEmpty) ...[
                            InkWell(
                              onTap: _clearAllHistory,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.delete_sweep_rounded, size: 12, color: Color(0xFFDC2626)),
                                    SizedBox(width: 3),
                                    Text('Clear', style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_agentTransactions.length} Items',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  if (_agentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.receipt_long, color: Color(0xFFCBD5E1), size: 36),
                            SizedBox(height: 6),
                            Text('No collections recorded yet today.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _agentTransactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 14, color: Color(0xFFF8FAFC)),
                      itemBuilder: (ctx, idx) {
                        final tx = _agentTransactions[idx];
                        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                        final date = tx['collectionDate'] ?? tx['date'] ?? 'Today';
                        final mode = tx['paymentMode'] ?? 'CASH';
                        final receipt = tx['receiptId'] ?? 'RCP-2026';
                        final customerName = tx['customerName'] ?? 'Customer';
                        final time = tx['time'] ?? 'Today';

                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  ReceiptDialog.show(context, {
                                    'receiptId': receipt,
                                    'customerName': customerName,
                                    'accountNumber': 'PG-2026-${tx["customerId"] ?? "00"}',
                                    'amount': amount,
                                    'date': date,
                                    'time': time,
                                    'paymentMode': mode,
                                    'agentName': agentName,
                                    'balance': totalCollected,
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: mode == 'UPI' ? const Color(0xFF2563EB).withOpacity(0.12) : const Color(0xFF76A787).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          mode == 'UPI' ? Icons.qr_code : Icons.arrow_downward,
                                          color: mode == 'UPI' ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$customerName • $mode',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308)),
                                            ),
                                            Text('$date $time · $receipt', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '+ ₹${amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: mode == 'UPI' ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkResponse(
                              onTap: () => _deleteTransaction(tx),
                              radius: 20,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instant Doorstep Collection Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E2F3), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF55356E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_card, color: Color(0xFF55356E), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Instant Doorstep Deposit Entry',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308)),
                            ),
                            Text('Instantly credits agent passbook & issues receipt', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_assignedCustomers.isNotEmpty) ...[
                    const Text('Select Customer to Credit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF191308))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _assignedCustomers.any((c) => c.id == _selectedCollectCustomerId)
                              ? _selectedCollectCustomerId
                              : _assignedCustomers.first.id,
                          isExpanded: true,
                          items: _assignedCustomers.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                '${c.name} (${c.id}) • ₹${c.openingBalance.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCollectCustomerId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Quick Amount Buttons
                  const Text('Deposit Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF191308))),
                  const SizedBox(height: 8),
                  Row(
                    children: [100, 200, 500, 1000].map((amt) {
                      final isSel = _depositAmount == amt.toDouble();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _depositAmount = amt.toDouble();
                                _customAmountCtrl.text = amt.toString();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSel ? const Color(0xFF55356E) : const Color(0xFFD6F5FF).withOpacity(0.3),
                              side: BorderSide(color: isSel ? const Color(0xFF55356E) : const Color(0xFFE9E2F3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              '₹$amt',
                              style: TextStyle(
                                color: isSel ? Colors.white : const Color(0xFF55356E),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _customAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Custom Amount (₹)',
                      prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) setState(() => _depositAmount = parsed);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Payment Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('💵 Cash'),
                          selected: _paymentMode == 'CASH',
                          selectedColor: const Color(0xFF55356E),
                          labelStyle: TextStyle(color: _paymentMode == 'CASH' ? Colors.white : const Color(0xFF191308), fontWeight: FontWeight.bold, fontSize: 12),
                          onSelected: (val) => setState(() => _paymentMode = 'CASH'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('📱 Digital'),
                          selected: _paymentMode == 'UPI',
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(color: _paymentMode == 'UPI' ? Colors.white : const Color(0xFF191308), fontWeight: FontWeight.bold, fontSize: 12),
                          onSelected: (val) => setState(() => _paymentMode = 'UPI'),
                        ),
                      ),
                    ],
                  ),

                  if (_paymentMode == 'UPI') ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x142563EB), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _agentQrMode == 'IMAGE' && _agentCustomQrImageBase64 != null
                                        ? '📸 Agent QR'
                                        : '⚡ Agent Dynamic UPI QR',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308)),
                                  ),
                                  Text(
                                    _agentUpiVpa,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => AgentQrConfigSheet.show(context, onSaved: _loadUpiConfig),
                                icon: const Icon(Icons.tune, size: 15, color: Color(0xFF55356E)),
                                label: const Text('Set QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF55356E))),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1EBF7),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_agentQrMode == 'IMAGE' && _agentCustomQrImageBase64 != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                base64Decode(_agentCustomQrImageBase64!),
                                height: 170,
                                width: 170,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ] else ...[
                            QrImageView(
                              data: 'upi://pay?pa=$_agentUpiVpa&pn=${Uri.encodeComponent(_agentUpiName)}&am=$_depositAmount&cu=INR&tn=AgentPassbookDeposit',
                              version: QrVersions.auto,
                              size: 140.0,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submittingDeposit ? null : _recordDeposit,
                      icon: _submittingDeposit
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _submittingDeposit ? 'Recording...' : 'Post Deposit (₹${_depositAmount.toStringAsFixed(0)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF55356E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. CUSTOMER ONLY PASSBOOK VIEW (ONE PASSBOOK PER USER)
  // ─────────────────────────────────────────────────────────────

  Widget _buildCustomerPassbookView(AuthProvider auth) {
    final cust = _customerData;
    final balance = (_customerAccount?['balance'] as num?)?.toDouble() ?? 1000.0;
    final interestRate = (_customerAccount?['interest_rate'] as num?)?.toDouble() ?? 4.5;
    final accruedInterest = (balance * (interestRate / 100) * 30) / 365;
    final projectedMaturity = balance + (balance * (interestRate / 100));
    final accountNumber = _customerAccount?['account_number'] ?? (cust != null ? 'PCMS-${cust["id"].toString().replaceAll("CUST-", "")}' : 'PCMS-00000');
    final holderName = cust?['name'] ?? auth.name;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      body: RefreshIndicator(
        onRefresh: _loadPassbookData,
        color: const Color(0xFF55356E),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Customer Account Header (No Dropdown Switcher)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'My Online Passbook • $holderName',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF55356E).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔒 Verified A/C',
                      style: TextStyle(color: Color(0xFF55356E), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Titanium Passbook Card
            TitaniumCard(
              title: 'Pigmy Savings Passbook • $accountNumber',
              balance: '₹ ${balance.toStringAsFixed(2)}',
              accountNumber: accountNumber,
              accountHolder: holderName.toUpperCase(),
              interestRate: '$interestRate% Yield',
            ),
            const SizedBox(height: 16),

            // Maturity Projection Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF191308),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF55356E), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A55356E), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Maturity Projection & Growth',
                        style: TextStyle(color: Color(0xFFD6F5FF), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF55356E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('⏳ 365-Day Cycle', style: TextStyle(color: Color(0xFFD6F5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.35,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF76A787)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Accrued Interest (Est.)', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          Text('₹${accruedInterest.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF76A787), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Projected Maturity Payout', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          Text('₹${projectedMaturity.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD6F5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Customer Transaction Statement Ledger
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_stories, color: Color(0xFF55356E), size: 18),
                          SizedBox(width: 8),
                          Text('Passbook Statement Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308))),
                        ],
                      ),
                      Row(
                        children: [
                          if (_customerTransactions.isNotEmpty) ...[
                            InkWell(
                              onTap: _clearAllHistory,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.delete_sweep_rounded, size: 12, color: Color(0xFFDC2626)),
                                    SizedBox(width: 4),
                                    Text('Clear', style: TextStyle(color: Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text('${_customerTransactions.length} Records', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  if (_customerTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.receipt_long, color: Color(0xFFCBD5E1), size: 36),
                            SizedBox(height: 6),
                            Text('No transactions recorded yet.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            Text('Make a deposit below to update your online passbook.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customerTransactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 14, color: Color(0xFFF8FAFC)),
                      itemBuilder: (ctx, idx) {
                        final tx = _customerTransactions[idx];
                        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                        final date = tx['collection_date'] ?? tx['date'] ?? 'Today';
                        final mode = tx['payment_mode'] ?? 'CASH';
                        final receipt = tx['receipt_id'] ?? 'RCP-2026-000';

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF76A787).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_downward, color: Color(0xFF16A34A), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Deposit • $mode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308))),
                                  Text('$date · $receipt', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Text(
                              '+ ₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            InkResponse(
                              onTap: () => _deleteTransaction(tx),
                              radius: 20,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Self Deposit Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E2F3), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF55356E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Color(0xFF55356E), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Instant Self-Deposit via UPI',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308)),
                            ),
                            Text('Scan & pay directly to credit your Pigmy account', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Amount Selector
                  const Text('Quick Select Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF191308))),
                  const SizedBox(height: 8),
                  Row(
                    children: [100, 200, 500, 1000].map((amt) {
                      final isSel = _depositAmount == amt.toDouble();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _depositAmount = amt.toDouble();
                                _customAmountCtrl.text = amt.toString();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSel ? const Color(0xFF55356E) : const Color(0xFFD6F5FF).withOpacity(0.3),
                              side: BorderSide(color: isSel ? const Color(0xFF55356E) : const Color(0xFFE9E2F3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              '₹$amt',
                              style: TextStyle(
                                color: isSel ? Colors.white : const Color(0xFF55356E),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: 'upi://pay?pa=$_agentUpiVpa&pn=${Uri.encodeComponent(_agentUpiName)}&am=$_depositAmount&cu=INR&tn=PigmySelfDeposit',
                            version: QrVersions.auto,
                            size: 140.0,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan to Deposit ₹${_depositAmount.toStringAsFixed(0)} via GPay / PhonePe',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submittingDeposit ? null : _recordDeposit,
                      icon: _submittingDeposit
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _submittingDeposit ? 'Processing...' : 'Confirm Self-Deposit (₹${_depositAmount.toStringAsFixed(0)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF55356E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
