// ============================================================
// admin_dashboard_screen.dart — PCMS Admin Portal
// Persistent sidebar + dense stat cards + line chart + top agents
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/screens/login_screen.dart';
import 'customer_management_screen.dart';

// ── Models ───────────────────────────────────────────────────
class TopAgentModel {
  const TopAgentModel({
    required this.rank,
    required this.name,
    required this.avatarUrl,
    required this.collectedAmount,
    required this.targetAmount,
    required this.completionPct,
  });

  final int rank;
  final String name;
  final String avatarUrl;
  final double collectedAmount;
  final double targetAmount;
  final double completionPct;
}

class CollectionTrendModel {
  const CollectionTrendModel({
    required this.day,
    required this.amount,
  });
  final String day;
  final double amount;
}

enum AdminTab { dashboard, customers, agents, reports, settings }

extension _TabX on AdminTab {
  String get label => switch (this) {
        AdminTab.dashboard => 'Dashboard',
        AdminTab.customers => 'Customers',
        AdminTab.agents    => 'Agents',
        AdminTab.reports   => 'Reports',
        AdminTab.settings  => 'Settings',
      };

  IconData get icon => switch (this) {
        AdminTab.dashboard => Icons.dashboard_outlined,
        AdminTab.customers => Icons.people_outline_rounded,
        AdminTab.agents    => Icons.badge_outlined,
        AdminTab.reports   => Icons.analytics_outlined,
        AdminTab.settings  => Icons.settings_outlined,
      };

  IconData get activeIcon => switch (this) {
        AdminTab.dashboard => Icons.dashboard_rounded,
        AdminTab.customers => Icons.people_rounded,
        AdminTab.agents    => Icons.badge_rounded,
        AdminTab.reports   => Icons.analytics_rounded,
        AdminTab.settings  => Icons.settings_rounded,
      };
}

// ── Mock Data ────────────────────────────────────────────────
const List<TopAgentModel> _kTopAgents = [
  TopAgentModel(rank: 1, name: 'Sanjay Sharma', avatarUrl: 'SS', collectedAmount: 184500, targetAmount: 200000, completionPct: 92.25),
  TopAgentModel(rank: 2, name: 'Rahul Ahire',    avatarUrl: 'RA', collectedAmount: 167200, targetAmount: 180000, completionPct: 92.88),
  TopAgentModel(rank: 3, name: 'Priya Deshmukh', avatarUrl: 'PD', collectedAmount: 155000, targetAmount: 175000, completionPct: 88.57),
  TopAgentModel(rank: 4, name: 'Arjun Kamble',   avatarUrl: 'AK', collectedAmount: 142000, targetAmount: 160000, completionPct: 88.75),
  TopAgentModel(rank: 5, name: 'Meera Patil',    avatarUrl: 'MP', collectedAmount: 135400, targetAmount: 150000, completionPct: 90.26),
];

const List<CollectionTrendModel> _kTrend = [
  CollectionTrendModel(day: 'Mon', amount: 380000),
  CollectionTrendModel(day: 'Tue', amount: 410000),
  CollectionTrendModel(day: 'Wed', amount: 395000),
  CollectionTrendModel(day: 'Thu', amount: 460000),
  CollectionTrendModel(day: 'Fri', amount: 485000),
  CollectionTrendModel(day: 'Sat', amount: 512000),
  CollectionTrendModel(day: 'Sun', amount: 540000),
];

// ─────────────────────────────────────────────────────────────
// AdminDashboardScreen
// ─────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminState();
}

class _AdminState extends State<AdminDashboardScreen> {
  AdminTab _activeTab = AdminTab.dashboard;
  bool _loading = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _loading = false);
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Logout'),
        content: const Text('Are you sure you want to sign out of the PCMS Admin Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // pop dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.error, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.background,
      drawer: isWide ? null : Drawer(child: _Sidebar(active: _activeTab, onTab: (t) {
        setState(() => _activeTab = t);
        _scaffoldKey.currentState?.closeDrawer();
      }, onLogout: _onLogout)),
      body: Row(children: [
        // Sidebar on wide screen
        if (isWide)
          _Sidebar(
            active: _activeTab,
            onTab: (t) => setState(() => _activeTab = t),
            onLogout: _onLogout,
          ),
        
        // Main Content Area
        Expanded(
          child: Column(children: [
            // Topbar
            _Topbar(
              isWide: isWide,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onRefresh: _refresh,
              loading: _loading,
            ),
            
            // Scrollable Panel
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _activeTab == AdminTab.dashboard
                        ? _buildDashboardBody(isWide)
                        : _activeTab == AdminTab.customers
                            ? const CustomerManagementScreen()
                            : _buildTabPlaceholder(_activeTab.label),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTabPlaceholder(String title) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.construction_rounded, size: 48, color: AppPalette.textDisabled),
        const SizedBox(height: 16),
        Text('$title Panel', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text('Back-office management interface coming soon.', style: AppTextStyles.caption),
      ]),
    );
  }

  Widget _buildDashboardBody(bool isWide) {
    final size = MediaQuery.of(context).size;
    // Adapt details based on width
    final isStacked = size.width < 1200;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppPalette.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row of Stat Cards
          _buildStatGrid(isWide),
          const SizedBox(height: 24),
          
          // Main layout columns
          if (isStacked) ...[
            _buildChartCard(),
            const SizedBox(height: 24),
            _buildTopAgentsCard(),
          ] else
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildChartCard()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildTopAgentsCard()),
            ]),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Stat Grid Layout
  // ─────────────────────────────────────────────────────────
  Widget _buildStatGrid(bool isWide) {
    final stats = [
      _AdminStatCard(
        icon: Icons.payments_outlined,
        title: "Today's Collection",
        value: "₹8,42,000",
        sub: "+12.4% from yesterday",
        color: AppPalette.success,
        iconBg: AppPalette.successContainer,
      ),
      _AdminStatCard(
        icon: Icons.people_outline_rounded,
        title: "Total Customers",
        value: "1,482",
        sub: "32 added this week",
        color: AppPalette.primary,
        iconBg: AppPalette.primaryContainer,
      ),
      _AdminStatCard(
        icon: Icons.badge_outlined,
        title: "Active Agents",
        value: "24 / 28",
        sub: "4 currently off-duty",
        color: AppPalette.primary,
        iconBg: AppPalette.primaryContainer,
      ),
      _AdminStatCard(
        icon: Icons.pending_actions_rounded,
        title: "Pending Collection",
        value: "₹2,18,500",
        sub: "Target: ₹10.6L today",
        color: AppPalette.warning,
        iconBg: AppPalette.warningContainer,
      ),
      _AdminStatCard(
        icon: Icons.account_balance_wallet_outlined,
        title: "Cash in Hand",
        value: "₹3,84,000",
        sub: "Deposited: ₹4.58L",
        color: AppPalette.primary,
        iconBg: AppPalette.primaryContainer,
      ),
    ];

    return LayoutBuilder(builder: (_, constraints) {
      final width = constraints.maxWidth;
      // Determine columns based on width
      int crossAxisCount = 2;
      if (width >= 1400) {
        crossAxisCount = 5;
      } else if (width >= 1024) {
        crossAxisCount = 3;
      } else if (width >= 600) {
        crossAxisCount = 2;
      } else {
        crossAxisCount = 1;
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 5 ? 1.45 : 1.7,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => stats[i],
      );
    });
  }

  // ─────────────────────────────────────────────────────────
  // Collection Trend Line Chart Card
  // ─────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    final format = NumberFormat('#,##,##0', 'en_IN');
    final double maxY = 600000;

    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(
            title: 'Collection Trend (Last 7 Days)',
            actionLabel: 'Export Report',
            onAction: () {},
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 300000,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppPalette.primary.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${_kTrend[spot.spotIndex].day}\n₹${format.format(spot.y)}',
                        AppTextStyles.labelSmall.copyWith(color: Colors.white, height: 1.5),
                      );
                    }).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= _kTrend.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_kTrend[idx].day,
                              style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      interval: 50000,
                      getTitlesWidget: (v, _) {
                        if (v == 300000) return const SizedBox.shrink();
                        final label = '${(v / 100000).toStringAsFixed(1)}L';
                        return Text(label,
                            style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary),
                            textAlign: TextAlign.right);
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50000,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppPalette.outlineVariant,
                    strokeWidth: 0.6,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _kTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                    isCurved: true,
                    color: AppPalette.success,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppPalette.success.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Top Performing Agents Card
  // ─────────────────────────────────────────────────────────
  Widget _buildTopAgentsCard() {
    final format = NumberFormat('#,##,##0', 'en_IN');
    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Top Performing Agents'),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _kTopAgents.length,
              separatorBuilder: (_, __) => const Divider(height: 16, thickness: 0.5),
              itemBuilder: (_, i) {
                final agent = _kTopAgents[i];
                return Row(children: [
                  // Rank icon or index
                  SizedBox(
                    width: 24,
                    child: Text(
                      '#${agent.rank}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: i == 0
                            ? AppPalette.warning
                            : i == 1
                                ? const Color(0xFF94A3B8) // silver-slate
                                : i == 2
                                    ? const Color(0xFFB45309) // bronze-amber
                                    : AppPalette.textDisabled,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppPalette.primaryContainer,
                    child: Text(
                      agent.avatarUrl,
                      style: AppTextStyles.labelSmall.copyWith(color: AppPalette.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Agent stats
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(agent.name, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: agent.completionPct / 100,
                          backgroundColor: AppPalette.surfaceVariant,
                          color: AppPalette.success,
                          minHeight: 4,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  // Collected vs target
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                    Text('₹${format.format(agent.collectedAmount)}',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                    Text('${agent.completionPct.toStringAsFixed(1)}%',
                        style: AppTextStyles.caption.copyWith(color: AppPalette.success)),
                  ]),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sidebar — Web Side Navigation Panel
// ─────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.active,
    required this.onTab,
    required this.onLogout,
  });

  final AdminTab active;
  final ValueChanged<AdminTab> onTab;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppPalette.primary,
      child: Column(children: [
        // Sidebar Header / Logo
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: AppPalette.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('PCMS Portal',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3)),
                  Text('ADMIN PORTAL',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white38,
                          fontSize: 9,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ),
        ),
        
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 16),
        
        // Navigation items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: AdminTab.values.map((t) {
              final isSel = active == t;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  selected: isSel,
                  selectedTileColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  leading: Icon(
                    isSel ? t.activeIcon : t.icon,
                    color: isSel ? Colors.white : Colors.white60,
                    size: 20,
                  ),
                  title: Text(
                    t.label,
                    style: TextStyle(
                      color: isSel ? Colors.white : Colors.white70,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13.5,
                    ),
                  ),
                  onTap: () => onTab(t),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Sidebar Footer / Admin profile
        const Divider(color: Colors.white10, height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              child: Text('AD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Admin Console',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('System Manager',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
              onPressed: onLogout,
              tooltip: 'Sign Out',
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Topbar Component
// ─────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.isWide,
    required this.onMenuTap,
    required this.onRefresh,
    required this.loading,
  });

  final bool isWide;
  final VoidCallback onMenuTap;
  final VoidCallback onRefresh;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        if (!isWide) ...[
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppPalette.primary),
            onPressed: onMenuTap,
          ),
          const SizedBox(width: 8),
        ],
        
        // Portal Title
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PCMS Admin Control Panel', style: AppTextStyles.titleMedium),
              const SizedBox(height: 2),
              Text(today, style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
            ],
          ),
        ),
        
        // Topbar action icons
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.primary)),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppPalette.textSecondary, size: 20),
            onPressed: onRefresh,
            tooltip: 'Refresh Dashboard',
          ),
        
        const SizedBox(width: 8),
        
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppPalette.textSecondary, size: 20),
          onPressed: () {},
          tooltip: 'System Alerts',
        ),
        
        const SizedBox(width: 12),
        const VerticalDivider(width: 1, indent: 22, endIndent: 22),
        const SizedBox(width: 16),
        
        // Admin Quick Profile info
        Row(children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Console Manager',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary)),
              Text('Active',
                  style: TextStyle(fontSize: 10, color: AppPalette.success, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppPalette.primaryContainer,
            child: Text('CM',
                style: AppTextStyles.labelSmall.copyWith(color: AppPalette.primary, fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AdminStatCard Component
// ─────────────────────────────────────────────────────────────
class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.sub,
    required this.color,
    required this.iconBg,
  });

  final IconData icon;
  final String title;
  final String value;
  final String sub;
  final Color color;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          // Stat mini-badge
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ]),
        const Spacer(),
        Text(value,
            style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(title, style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(sub, style: AppTextStyles.caption.copyWith(fontSize: 9.5, color: color), maxLines: 1),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ErrorState Component
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppPalette.textDisabled),
          const SizedBox(height: 16),
          Text('Failed to load portal data', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text(message, style: AppTextStyles.bodySmall, textAlign: TextAlign.center, maxLines: 3),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}
