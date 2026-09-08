import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class MaturityAccrualScreen extends StatefulWidget {
  const MaturityAccrualScreen({super.key});

  @override
  State<MaturityAccrualScreen> createState() => _MaturityAccrualScreenState();
}

class _MaturityAccrualScreenState extends State<MaturityAccrualScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadMaturing();
  }

  Future<void> _loadMaturing() async {
    final branch = Provider.of<BranchProvider>(context, listen: false);
    await branch.fetchMaturingAccounts(days: 30);
  }

  void _runMonthlyAccrual() async {
    setState(() => _isProcessing = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final branch = Provider.of<BranchProvider>(context, listen: false);

    final res = await branch.runBatchAccrual(
      performedBy: auth.name,
      role: auth.role,
    );

    setState(() => _isProcessing = false);

    if (mounted && res != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text('Monthly Accrual Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accrual Month: ${res['accrualMonth']}'),
              const SizedBox(height: 6),
              Text('Accounts Processed: ${res['processed']}'),
              Text('Skipped (already accrued): ${res['skipped']}'),
              const SizedBox(height: 8),
              Text(
                'Total Interest Credited: ₹${res['totalInterest']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _loadMaturing();
    }
  }

  void _processMaturities() async {
    setState(() => _isProcessing = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final branch = Provider.of<BranchProvider>(context, listen: false);

    final res = await branch.processMaturity(
      performedBy: auth.name,
      role: auth.role,
    );

    setState(() => _isProcessing = false);

    if (mounted && res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processed ${res['maturedCount']} matured accounts! Payout calculated.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      _loadMaturing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final branch = Provider.of<BranchProvider>(context);
    final maturing = branch.maturingAccounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Interest Accrual & Maturity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMaturing,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Batch Action Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Automated Monthly Interest Engine', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text('Calculate & Credit Interest', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Computes 4.5%–5.0% annual interest on minimum monthly balance for all active Pigmy accounts.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _runMonthlyAccrual,
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: const Text('Run Batch Accrual'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _processMaturities,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Process Maturity'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Maturing Soon Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Accounts Maturing in 30 Days', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text('${maturing.length} accounts', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            if (maturing.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No accounts maturing within 30 days.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              )
            else
              ...maturing.map((acc) {
                final days = acc.daysToMaturity ?? 0;
                final projected = acc.projectedPayout ?? acc.balance;

                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(acc.customerName ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          StatusBadge(status: acc.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('A/C: ${acc.accountNumber} · ${acc.customerPhone ?? ""}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Balance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('₹${acc.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Days Left', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('$days days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: days <= 7 ? const Color(0xFFDC2626) : const Color(0xFFD97706))),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Projected Payout', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('₹${projected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
