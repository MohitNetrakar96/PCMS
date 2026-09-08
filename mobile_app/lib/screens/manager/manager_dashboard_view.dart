import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../admin/customer_management_screen.dart';
import 'live_visits_screen.dart';
import 'manager_reconciliation_screen.dart';
import 'maturity_accrual_screen.dart';

class ManagerDashboardView extends StatefulWidget {
  final Function(int) onTabChange;

  const ManagerDashboardView({super.key, required this.onTabChange});

  @override
  State<ManagerDashboardView> createState() => _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends State<ManagerDashboardView> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final branch = Provider.of<BranchProvider>(context, listen: false);
    await branch.fetchDashboardMetrics(email: auth.email, role: auth.role);
    await branch.fetchPendingMismatches(role: auth.role);
    await branch.fetchLiveVisits();
    await branch.fetchMaturingAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final branch = Provider.of<BranchProvider>(context);
    final metrics = branch.dashboardMetrics ?? {};
    final mismatches = branch.pendingMismatches;

    final totalTarget = (metrics['totalTarget'] as num?)?.toDouble() ?? 15000.0;
    final totalCollected = (metrics['totalCollected'] as num?)?.toDouble() ?? 0.0;
    final collectedCash = (metrics['collectedCash'] as num?)?.toDouble() ?? 0.0;
    final collectedDigital = (metrics['collectedDigital'] as num?)?.toDouble() ?? 0.0;
    final completionRate = metrics['completionRate'] ?? 0;
    final totalCustomers = metrics['totalCustomers'] ?? 0;
    final completedCount = metrics['completedCount'] ?? 0;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch KPI Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
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
                        'BRANCH TOTAL COLLECTIONS',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF22C55E)),
                        ),
                        child: const Text('Branch Active', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${totalCollected.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cash in Hand', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('₹${collectedCash.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Digital UPI', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('₹${collectedDigital.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF93C5FD), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Target Due', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('₹${totalTarget.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFED7AA), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pending Reconciliation Alert Card (with Red Badge if > 0)
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerReconciliationScreen()));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mismatches.isNotEmpty ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: mismatches.isNotEmpty ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: mismatches.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        mismatches.isNotEmpty ? Icons.error_outline_rounded : Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mismatches.isNotEmpty
                                    ? '${mismatches.length} Reconciliation Variance'
                                    : 'All Accounts Reconciled ✓',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: mismatches.isNotEmpty ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                ),
                              ),
                              if (mismatches.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(10)),
                                  child: Text('${mismatches.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mismatches.isNotEmpty
                                ? 'Tap to inspect shortage / excess differences & resolve'
                                : 'Daily field collection equals vault submission',
                            style: TextStyle(
                              fontSize: 11,
                              color: mismatches.isNotEmpty ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Key Branch Action Cards
            const Text('Branch Management Hub', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildHubTile(
                    Icons.people_alt_rounded,
                    'Customer Directory',
                    '$totalCustomers Enrolled',
                    const Color(0xFF55356E),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerManagementScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHubTile(
                    Icons.trending_up_rounded,
                    'Interest Accrual',
                    '${branch.maturingAccounts.length} Maturing',
                    const Color(0xFF2563EB),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaturityAccrualScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHubTile(
                    Icons.sensors_rounded,
                    'Live Visits Feed',
                    '${branch.liveVisits.length} Logged Today',
                    const Color(0xFF16A34A),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveVisitsScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHubTile(
                    Icons.fact_check_rounded,
                    'Reconciliation',
                    mismatches.isNotEmpty ? '${mismatches.length} Mismatches' : 'Balanced',
                    const Color(0xFFD97706),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerReconciliationScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Performance Overview
            const Text('Operations Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Customers Scheduled', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text('$totalCustomers', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Visits Completed', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text('$completedCount ($completionRate%)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Accounts Maturing in 30 Days', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text('${branch.maturingAccounts.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Live Visits Snippet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Live Visits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveVisitsScreen())),
                  child: const Text('View Live Stream', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            if (branch.liveVisits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No collection visits recorded yet today.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ),
              )
            else
              ...branch.liveVisits.take(5).map((v) => _buildLiveVisitCard(v)),
          ],
        ),
      ),
    );
  }

  Widget _buildHubTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
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
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
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

  Widget _buildLiveVisitCard(Map<String, dynamic> v) {
    final status = v['status'] ?? 'pending';
    final amount = (v['collectedAmount'] as num?)?.toDouble() ?? 0.0;
    final name = v['customerName'] ?? 'Customer';
    final time = v['visitTime'] ?? 'Pending';
    final mode = v['paymentMode'] ?? 'CASH';

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: status == 'collected' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
            child: Icon(
              status == 'collected' ? Icons.check_rounded : Icons.access_time_rounded,
              color: status == 'collected' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('$time · $mode · ${v['area'] ?? ""}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          Text(
            '₹${amount.toInt()}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: status == 'collected' ? const Color(0xFF16A34A) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
