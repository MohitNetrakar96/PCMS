import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../widgets/banker_avatar.dart';

// Agent Views
import 'agent/agent_home_view.dart';
import 'collections_screen.dart';
import 'route_map_screen.dart';

// Manager Views
import 'manager/manager_dashboard_view.dart';
import 'manager/live_visits_screen.dart';
import 'manager/manager_reconciliation_screen.dart';
import 'manager/maturity_accrual_screen.dart';

// Admin Views
import 'admin/admin_dashboard_view.dart';
import 'admin/customer_management_screen.dart';
import 'admin/user_management_screen.dart';
import 'admin/audit_trail_screen.dart';

// Cashier Views
import 'cashier/cashier_dashboard_view.dart';
import 'cashier/vault_handover_screen.dart';
import 'cashier/denomination_counter_screen.dart';
import 'cashier/account_closure_screen.dart';

// Auditor Views
import 'auditor/auditor_dashboard_view.dart';

// Customer Views
import 'customer_portal_screen.dart';

// Shared
import 'passbook_view.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<CollectionProvider>().fetchTodayCollections(auth.email);
    });
  }

  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.role.toLowerCase();

    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (role.contains('admin')) {
      // Administrator Dashboard
      screens = [
        AdminDashboardView(onTabChange: _onTabChange),
        const CustomerManagementScreen(),
        const UserManagementScreen(),
        const AuditTrailScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin Hub'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
        BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff Users'),
        BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Audit Trail'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (role.contains('manager')) {
      // Branch Manager Dashboard
      screens = [
        ManagerDashboardView(onTabChange: _onTabChange),
        const CustomerManagementScreen(),
        const LiveVisitsScreen(),
        const ManagerReconciliationScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
        BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye), label: 'Live Field'),
        BottomNavigationBarItem(icon: Icon(Icons.rule), label: 'Reconcile'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (role.contains('cashier')) {
      // Cashier Dashboard
      screens = [
        CashierDashboardView(onTabChange: _onTabChange),
        const VaultHandoverScreen(),
        const DenominationCounterScreen(),
        const AccountClosureScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Vault Desk'),
        BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Handover'),
        BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Cash Count'),
        BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Closure'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (role.contains('auditor')) {
      // Auditor Dashboard
      screens = [
        AuditorDashboardView(onTabChange: _onTabChange),
        const AuditTrailScreen(),
        const LiveVisitsScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Audit Hub'),
        BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Compliance'),
        BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye), label: 'Live Feeds'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (role.contains('customer')) {
      // Customer Portal
      screens = const [
        PassbookView(),
        CustomerPortalScreen(),
        ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Passbook'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Self Deposit'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      // Default: Collection Agent
      screens = [
        const AgentHomeView(),
        const CollectionsScreen(),
        const RouteMapScreen(),
        const PassbookView(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ledger'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Collections'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Route Map'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Passbook'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF55356E),
        title: Row(
          children: [
            BankerAvatar(
              photoUrl: auth.photoUrl,
              name: auth.name,
              radius: 17,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  auth.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD6F5FF),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFD6F5FF)),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFF55356E)),
                      SizedBox(width: 10),
                      Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF191308))),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to exit your sovereign banking session?',
                    style: TextStyle(color: Color(0xFF55356E), fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF55356E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: screens[safeIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9E2F3), width: 1.5)),
          boxShadow: [
            BoxShadow(color: Color(0x0F55356E), blurRadius: 10, offset: Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: navItems,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF55356E),
          unselectedItemColor: const Color(0xFF191308).withOpacity(0.45),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
        ),
      ),
    );
  }
}
