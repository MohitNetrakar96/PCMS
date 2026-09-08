import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../models/collection_model.dart';
import 'customer_visit_screen.dart';
import '../../widgets/banking_3d_banner.dart';
import '../../widgets/passbook_scanner_sheet.dart';
import '../cashier/vault_handover_screen.dart';
import '../../utils/map_utils.dart';

class AgentHomeView extends StatelessWidget {
  const AgentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<CollectionProvider>();
    final pending = provider.pendingCustomers;
    final totalDue = provider.totalCollected;
    final target = provider.totalTarget > 0 ? provider.totalTarget : 1278.0;
    final percent = target > 0 ? (totalDue / target).clamp(0.0, 1.0) : 0.0;
    final completedCount = provider.completedCount;
    final totalCount = provider.collections.length;

    return RefreshIndicator(
      onRefresh: () => provider.fetchTodayCollections(auth.email),
      color: const Color(0xFF55356E),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Banking3dVisualBanner(
            title: 'Imperial Pigmy Reserve',
            subtitle: 'Secure doorstep thrift collection & vault ledger',
          ),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF55356E),
                  Color(0xFF381F4C),
                  Color(0xFF191308),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF55356E).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0xFFD6F5FF).withOpacity(0.25), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TODAY'S CASH COLLECTED",
                      style: TextStyle(
                        color: const Color(0xFFD6F5FF).withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF76A787).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF76A787), width: 0.8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.sync, color: Color(0xFF76A787), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Vault Sync',
                            style: TextStyle(color: Color(0xFFD6F5FF), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₹' + totalDue.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF76A787)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ₹' + target.toStringAsFixed(0),
                      style: TextStyle(color: const Color(0xFFE9E2F3).withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      (percent * 100).toStringAsFixed(0) + '% Completed (' + completedCount.toString() + '/' + totalCount.toString() + ')',
                      style: const TextStyle(color: Color(0xFFD6F5FF), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: provider.pendingOfflineCount > 0
                  ? const Color(0xFFFFFBEB)
                  : (provider.isOfflineMode ? const Color(0xFFF1F5F9) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: provider.pendingOfflineCount > 0
                    ? const Color(0xFFFDE68A)
                    : (provider.isOfflineMode ? const Color(0xFFCBD5E1) : const Color(0xFFE9E2F3)),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  provider.pendingOfflineCount > 0
                      ? Icons.pending_actions_rounded
                      : (provider.isOfflineMode ? Icons.cloud_off_rounded : Icons.check_circle_rounded),
                  color: provider.pendingOfflineCount > 0
                      ? const Color(0xFFD97706)
                      : (provider.isOfflineMode ? const Color(0xFF64748B) : const Color(0xFF16A34A)),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.pendingOfflineCount > 0
                            ? '${provider.pendingOfflineCount} Offline Deposits Pending Sync'
                            : (provider.isOfflineMode ? 'Doorstep Offline Mode Active' : 'Doorstep Offline Ledger Active'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: provider.pendingOfflineCount > 0 ? const Color(0xFF92400E) : const Color(0xFF191308),
                        ),
                      ),
                      Text(
                        provider.pendingOfflineCount > 0
                            ? 'Saved on phone · Tap Sync to post to vault'
                            : (provider.isOfflineMode ? 'Using cached route offline' : 'Local cache & vault in sync'),
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.pendingOfflineCount > 0 ? const Color(0xFFB45309) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Syncing offline ledger with banking vault...'), duration: Duration(seconds: 1)),
                    );
                    final res = await provider.syncOfflineQueue(auth.email);
                    if (context.mounted) {
                      final synced = res['synced'] ?? 0;
                      final failed = res['failed'] ?? 0;
                      if (synced > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ Synced $synced offline deposits to vault!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      } else if (failed > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not reach vault ($failed failed). Will retry.'),
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Ledger is up to date!'),
                            backgroundColor: Color(0xFF55356E),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 14),
                  label: const Text('Sync Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.pendingOfflineCount > 0 ? const Color(0xFFD97706) : const Color(0xFF55356E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.menu_book, color: Color(0xFF55356E), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Next Customer in Queue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191308)),
                  ),
                ],
              ),
              Text(
                'View All Stops →',
                style: TextStyle(color: const Color(0xFF55356E).withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E2F3)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.military_tech, color: Color(0xFF76A787), size: 48),
                  SizedBox(height: 8),
                  Text('All Doorstep Collections Completed!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF191308))),
                  SizedBox(height: 4),
                  Text('Ready for End-of-Day vault handover with cashier.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else ...[
            _buildCustomerCard(context, pending.first, isNext: true, stopNumber: 1),
            if (pending.length > 1) ...[
              const SizedBox(height: 14),
              Row(
                children: const [
                  Icon(Icons.keyboard_double_arrow_right, color: Color(0xFF55356E), size: 16),
                  SizedBox(width: 6),
                  Text('Subsequent Stop', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF191308))),
                ],
              ),
              const SizedBox(height: 8),
              _buildSubsequentCard(context, pending[1], stopNumber: 2),
            ],
          ],

          const SizedBox(height: 24),
          const Text('Quick Field Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF191308))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Passbook',
                  color: const Color(0xFF55356E),
                  onTap: () {
                    PassbookScannerSheet.show(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Vault Handover',
                  color: const Color(0xFF76A787),
                  textColor: const Color(0xFF191308),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VaultHandoverScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CollectionModel item, {required bool isNext, required int stopNumber}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E2F3), width: 1.4),
        boxShadow: const [
          BoxShadow(color: Color(0x0A55356E), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E2F3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF55356E).withOpacity(0.3)),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF55356E), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191308)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.area + ' • Due: ₹' + item.amount.toStringAsFixed(1),
                      style: TextStyle(color: const Color(0xFF191308).withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6F5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF76A787), width: 0.8),
                ),
                child: Text(
                  'STOP #' + stopNumber.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF191308),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    MapUtils.openMap(
                      context: context,
                      latitude: item.latitude,
                      longitude: item.longitude,
                      title: item.name,
                      address: item.address,
                    );
                  },
                  icon: const Icon(Icons.navigation, size: 14, color: Color(0xFF55356E)),
                  label: const Text('Navigate', style: TextStyle(color: Color(0xFF55356E), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF55356E), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CustomerVisitScreen(collection: item)),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Collect Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF55356E),
                    foregroundColor: const Color(0xFFD6F5FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubsequentCard(BuildContext context, CollectionModel item, {required int stopNumber}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E2F3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9E2F3),
          radius: 16,
          child: Text(
            '#' + stopNumber.toString(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF55356E)),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308))),
        subtitle: Text(item.area + ' • ₹' + item.amount.toStringAsFixed(1) + ' due', style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF55356E)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CustomerVisitScreen(collection: item)),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: textColor, size: 18),
      label: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
    );
  }
}
