import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class ManagerReconciliationScreen extends StatefulWidget {
  const ManagerReconciliationScreen({super.key});

  @override
  State<ManagerReconciliationScreen> createState() => _ManagerReconciliationScreenState();
}

class _ManagerReconciliationScreenState extends State<ManagerReconciliationScreen> {
  @override
  void initState() {
    super.initState();
    _loadReconciliation();
  }

  Future<void> _loadReconciliation() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final branch = Provider.of<BranchProvider>(context, listen: false);
    await branch.fetchDailyReconciliation(role: auth.role);
    await branch.fetchPendingMismatches(role: auth.role);
  }

  void _showResolveDialog(int recordId, String agentEmail, double difference) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resolve Cash Discrepancy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'Agent: $agentEmail\nVariance Amount: ₹${difference.toStringAsFixed(2)} (${difference > 0 ? "Shortfall" : "Excess"})',
                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Resolution Note / Manager Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Agent deposited shortage in vault next morning. Approved by Branch Manager.',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final branch = Provider.of<BranchProvider>(context, listen: false);
                final success = await branch.resolveMismatch(
                  recordId,
                  auth.name,
                  auth.role,
                  note: noteCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Discrepancy marked as RESOLVED ✓'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                  _loadReconciliation();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Resolution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branch = Provider.of<BranchProvider>(context);
    final dailyData = branch.dailyRecon ?? {};
    final results = (dailyData['results'] as List?) ?? [];
    final mismatchCount = dailyData['mismatchCount'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cash Reconciliation & Vault Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReconciliation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: mismatchCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mismatchCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Icon(
                    mismatchCount > 0 ? Icons.error_rounded : Icons.check_circle_rounded,
                    color: mismatchCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mismatchCount > 0 ? '$mismatchCount Unresolved Discrepancies' : 'Vault Handover Balanced ✓',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: mismatchCount > 0 ? const Color(0xFF991B1B) : const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Comparing field collections vs EOD physical submissions',
                          style: TextStyle(fontSize: 11, color: mismatchCount > 0 ? const Color(0xFFB91C1C) : const Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Agent End-of-Day Settlements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),

            if (results.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No reconciliation entries available for today.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              )
            else
              ...results.map((r) => _buildReconciliationTile(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationTile(Map<String, dynamic> r) {
    final status = r['status'] ?? 'MATCHED';
    final hasMismatch = r['hasMismatch'] == true;
    final agent = r['agentEmail'] ?? '';
    final collected = (r['totalCollected'] as num?)?.toDouble() ?? 0.0;
    final submitted = (r['totalSubmitted'] as num?)?.toDouble() ?? 0.0;
    final diff = (r['difference'] as num?)?.toDouble() ?? 0.0;
    final recordId = r['recordId'] is int ? r['recordId'] : int.tryParse(r['recordId']?.toString() ?? '0') ?? 0;
    final note = r['note'];

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: hasMismatch ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  agent,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Field Collected', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('₹${collected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vault Submitted', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('₹${submitted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Variance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text(
                    '${diff >= 0 ? "+" : ""}₹${diff.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasMismatch ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
              child: Text('Resolution note: $note', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
            ),
          ],
          if (hasMismatch) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showResolveDialog(recordId, agent, diff),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Resolve Discrepancy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
