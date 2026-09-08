import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import 'user_management_screen.dart';
import 'customer_management_screen.dart';
import 'audit_trail_screen.dart';
import 'database_inspector_screen.dart';

class AdminDashboardView extends StatefulWidget {
  final Function(int) onTabChange;

  const AdminDashboardView({super.key, required this.onTabChange});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  Map<String, dynamic>? _health;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    try {
      final h = await ApiService.getHealth();
      setState(() => _health = h);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Health Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withOpacity(0.35),
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
                      'SYSTEM & INFRASTRUCTURE HEALTH',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          const Text('Online 2.0.0', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'BankFlow PCMS Enterprise Core',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Centralized management for multi-branch collections, customer ledgers, and system audits.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Core Admin Functions Grid
          const Text('Administration Console', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _buildAdminCard(
                Icons.people_alt_rounded,
                'User Directory',
                'Roles & staff accounts',
                const Color(0xFF2563EB),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
              ),
              _buildAdminCard(
                Icons.badge_rounded,
                'Customer Records',
                'Add, edit & KYC status',
                const Color(0xFF16A34A),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerManagementScreen())),
              ),
              _buildAdminCard(
                Icons.history_edu_rounded,
                'Audit Trail',
                'Real-time access logs',
                const Color(0xFFEA580C),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditTrailScreen())),
              ),
              _buildAdminCard(
                Icons.storage_rounded,
                'Database Inspector',
                'Inspect raw SQLite tables',
                const Color(0xFF7C3AED),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DatabaseInspectorScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Security & Server Config Info
          const Text('API & Security Gate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active API Base URL', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Flexible(
                      child: Text(
                        ApiService.baseUrl,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Data Privacy Encryption', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('AES-256 + Aadhaar Masked', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('OTP Dispatch Gate', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('Nodemailer / Ethereal active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
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
