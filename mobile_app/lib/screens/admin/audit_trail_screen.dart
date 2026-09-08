import 'package:flutter/material.dart';
import '../../models/audit_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  List<AuditLogModel> _logs = [];
  bool _loading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  Future<void> _loadAudit() async {
    try {
      final list = await ApiService.getAuditLogs();
      setState(() {
        _logs = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Audit Trail?'),
        content: const Text('All historical audit logs will be permanently erased.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.clearAuditLogs();
      _loadAudit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _logs.where((l) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = l.action.toLowerCase().contains(q) || l.userName.toLowerCase().contains(q) || l.details.toLowerCase().contains(q);
      if (!matchesQuery) return false;

      if (_roleFilter != 'all' && l.role?.toLowerCase() != _roleFilter.toLowerCase()) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('System Audit Trail & Risk Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626)),
            onPressed: _clearLogs,
            tooltip: 'Clear Audit Logs',
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search action, user, or details…',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRolePill('All Logs (${_logs.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildRolePill('Agent', 'Collection Agent'),
                      const SizedBox(width: 8),
                      _buildRolePill('Manager', 'Branch Manager'),
                      const SizedBox(width: 8),
                      _buildRolePill('Cashier', 'Cashier'),
                      const SizedBox(width: 8),
                      _buildRolePill('Admin', 'Administrator'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No audit logs available.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final log = filtered[idx];
                          final isOk = log.status == 'ok';

                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            borderColor: isOk ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ),
                                    StatusBadge(status: log.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By: ${log.userName} (${log.role ?? "System"}) · ${log.createdAt.split("T")[0]}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                if (log.details.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                                    child: Text(log.details, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                  )
                                ]
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill(String label, String roleKey) {
    final active = _roleFilter == roleKey;
    return InkWell(
      onTap: () => setState(() => _roleFilter = roleKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
