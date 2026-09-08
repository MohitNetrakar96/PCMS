import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'vault_handover_screen.dart';
import 'denomination_counter_screen.dart';
import 'account_closure_screen.dart';
import '../manager/manager_reconciliation_screen.dart';

class CashierDashboardView extends StatefulWidget {
  final Function(int) onTabChange;

  const CashierDashboardView({super.key, required this.onTabChange});

  @override
  State<CashierDashboardView> createState() => _CashierDashboardViewState();
}

class _CashierDashboardViewState extends State<CashierDashboardView> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final branch = Provider.of<BranchProvider>(context, listen: false);
    await branch.fetchVaultToday('agent@bankflow.com');
    await branch.fetchDashboardMetrics(role: 'Cashier');
  }

  @override
  Widget build(BuildContext context) {
    final branch = Provider.of<BranchProvider>(context);
    final vault = branch.vaultToday;
    final metrics = branch.dashboardMetrics ?? {};

    final collectedCash = (metrics['collectedCash'] as num?)?.toDouble() ?? 0.0;
    final status = vault?.status ?? 'not_submitted';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vault Settlement Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MAIN VAULT INVENTORY & SETTLEMENT',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${collectedCash.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Expected Vault Cash: ₹${collectedCash.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        vault?.cashierAccepted == true ? '✓ Accepted by Cashier' : 'Pending Verification',
                        style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cashier Workflow Grid
            const Text('Cashier Desk Operations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildActionTile(
                  Icons.shield_rounded,
                  'Vault Handover',
                  '8-Step EOD Workflow',
                  const Color(0xFF059669),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultHandoverScreen())),
                ),
                _buildActionTile(
                  Icons.calculate_rounded,
                  'Denomination Counter',
                  '₹2000 to ₹1 Notes',
                  const Color(0xFF2563EB),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DenominationCounterScreen())),
                ),
                _buildActionTile(
                  Icons.account_balance_wallet_rounded,
                  'Account Closures',
                  'Payout & Renewal',
                  const Color(0xFFD97706),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountClosureScreen())),
                ),
                _buildActionTile(
                  Icons.assignment_turned_in_rounded,
                  'EOD Reconciliation',
                  'Variance & Balance',
                  const Color(0xFF7C3AED),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerReconciliationScreen())),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vault Handover Status Summary
            const Text('Current Handover Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusRow('1. Agent Cash Submission', vault?.cashSubmitted != null && vault!.cashSubmitted > 0),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildStatusRow('2. Manager OTP Clearance (if variance)', vault?.managerOtpVerified == true),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildStatusRow('3. Cashier Physical Acceptance', vault?.cashierAccepted == true),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildStatusRow('4. Bank Deposit Reference Slip', vault?.bankReference != null && vault!.bankReference!.isNotEmpty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool completed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: completed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            completed ? 'DONE ✓' : 'PENDING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: completed ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
