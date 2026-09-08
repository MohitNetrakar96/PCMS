import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class AccountClosureScreen extends StatefulWidget {
  const AccountClosureScreen({super.key});

  @override
  State<AccountClosureScreen> createState() => _AccountClosureScreenState();
}

class _AccountClosureScreenState extends State<AccountClosureScreen> {
  List<dynamic> _accounts = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final res = await ApiService.getPassbooks();
      setState(() {
        _accounts = res['accounts'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _handleCloseAccount(dynamic acc) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final id = acc['id'];
    final accNum = acc['account_number'] ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Account Closure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to close account $accNum? System will compute accrued interest, apply premature penalty if applicable, and generate payout voucher.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Close Account & Payout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.closeAccount(
        id,
        performedBy: auth.name,
        performedByRole: auth.role,
        performedByEmail: auth.email,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text('Account Closed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A/C Number: ${res['accountNumber']}'),
                const SizedBox(height: 6),
                Text('Total Deposits: ₹${res['totalDeposits']}'),
                Text('Accrued Interest: ₹${res['totalInterest']}'),
                if (res['isPremature'] == true)
                  Text('Premature Penalty: ₹${res['penalty']}', style: const TextStyle(color: Color(0xFFDC2626))),
                const Divider(height: 16),
                Text(
                  'FINAL PAYOUT: ₹${res['payout']}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF16A34A)),
                ),
              ],
            ),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Closure failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _handleRenewAccount(dynamic acc) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final id = acc['id'];

    try {
      final res = await ApiService.renewAccount(
        id,
        performedBy: auth.name,
        performedByRole: auth.role,
        performedByEmail: auth.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account renewed for 12 months! New maturity: ${res['newMaturityDate']}'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        _loadAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renewal failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _accounts.where((a) {
      final num = (a['account_number'] ?? '').toString().toLowerCase();
      final name = (a['customer_name'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return num.contains(q) || name.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Passbook & Account Closure Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by account number or customer name…',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No accounts found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) => _buildAccountItem(filtered[idx]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(dynamic acc) {
    final status = acc['status'] ?? 'ACTIVE';
    final isClosed = status == 'CLOSED';
    final isMatured = status == 'MATURED';
    final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
    final accNum = acc['account_number'] ?? 'PCMS-000';
    final name = acc['customer_name'] ?? 'Customer';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 4),
          Text('A/C: $accNum · ${acc['account_type'] ?? "Savings Passbook"}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Interest Rate', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('${acc['interest_rate'] ?? 4.5}% p.a.', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              if (!isClosed)
                ElevatedButton(
                  onPressed: () => _handleCloseAccount(acc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Close & Payout'),
                )
              else
                ElevatedButton(
                  onPressed: () => _handleRenewAccount(acc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Renew 12-Mo'),
                ),
            ],
          )
        ],
      ),
    );
  }
}
