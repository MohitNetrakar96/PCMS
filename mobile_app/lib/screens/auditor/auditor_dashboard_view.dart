import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/branch_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../admin/audit_trail_screen.dart';
import '../manager/manager_reconciliation_screen.dart';

class AuditorDashboardView extends StatefulWidget {
  final Function(int) onTabChange;

  const AuditorDashboardView({super.key, required this.onTabChange});

  @override
  State<AuditorDashboardView> createState() => _AuditorDashboardViewState();
}

class _AuditorDashboardViewState extends State<AuditorDashboardView> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final branch = Provider.of<BranchProvider>(context, listen: false);
    await branch.fetchAuditLogs();
    await branch.fetchPendingMismatches(role: 'Auditor');
  }

  @override
  Widget build(BuildContext context) {
    final branch = Provider.of<BranchProvider>(context);
    final auditLogs = branch.auditLogs;
    final mismatches = branch.pendingMismatches;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auditor Overview Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF374151), Color(0xFF1F2937), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'INTERNAL AUDIT & COMPLIANCE DESK',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Read-Only Audit', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Compliance & Risk Oversight', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Audit Trail Records', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('${auditLogs.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pending Mismatches', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('${mismatches.length}', style: TextStyle(color: mismatches.isNotEmpty ? const Color(0xFFF87171) : const Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Auditor Links
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditTrailScreen())),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.history_edu_rounded, color: Color(0xFF2563EB), size: 24),
                          SizedBox(height: 8),
                          Text('Audit Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Filter by role/date', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerReconciliationScreen())),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 24),
                          SizedBox(height: 8),
                          Text('Variance Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Inspect vault records', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent System Audit Logs
            const Text('Recent System Events', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            if (auditLogs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No audit records recorded yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              )
            else
              ...auditLogs.take(8).map((log) => AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Icon(Icons.security_rounded, size: 18, color: log.status == 'ok' ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${log.userName} (${log.role ?? "System"}) · ${log.details}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        StatusBadge(status: log.status),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
