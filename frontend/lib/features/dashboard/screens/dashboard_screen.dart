import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/section_header.dart';

import '../../collections/screens/collection_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'daily_summary_screen.dart';

const _mockRecentCollections = [
  {'name': 'Arjun Kumar', 'id': 'LN-8472', 'time': '10:45 AM', 'amount': 15000.0, 'status': CollectionStatus.collected},
  {'name': 'Meera Reddy', 'id': 'LN-9210', 'time': '11:15 AM', 'amount': 8500.0, 'status': CollectionStatus.pending},
  {'name': 'Vikram Singh', 'id': 'LN-1029', 'time': '12:30 PM', 'amount': 22000.0, 'status': CollectionStatus.collected},
  {'name': 'Sneha Sharma', 'id': 'LN-3341', 'time': '01:10 PM', 'amount': 5400.0, 'status': CollectionStatus.notAvailable},
  {'name': 'Rohit Verma', 'id': 'LN-5521', 'time': '02:00 PM', 'amount': 12000.0, 'status': CollectionStatus.locked},
];

const _mockHistory = [
  {'date': 'Today', 'items': [
    {'name': 'Arjun Kumar', 'id': 'LN-8472', 'time': '10:45 AM', 'amount': 15000.0, 'status': CollectionStatus.collected},
    {'name': 'Vikram Singh', 'id': 'LN-1029', 'time': '12:30 PM', 'amount': 22000.0, 'status': CollectionStatus.collected},
  ]},
  {'date': 'Yesterday', 'items': [
    {'name': 'Anita Desai', 'id': 'LN-2291', 'time': '09:30 AM', 'amount': 9500.0, 'status': CollectionStatus.collected},
    {'name': 'Pooja Patel', 'id': 'LN-1182', 'time': '02:45 PM', 'amount': 7200.0, 'status': CollectionStatus.notAvailable},
    {'name': 'Sunil Kumar', 'id': 'LN-4439', 'time': '04:20 PM', 'amount': 18000.0, 'status': CollectionStatus.collected},
  ]}
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _HomeTab(),
      const CollectionListScreen(),
      const _HistoryTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppPalette.primary,
        unselectedItemColor: AppPalette.textDisabled,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt_rounded), label: 'Collections'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          // Navigate to collection list screen inside FAB via push
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CollectionListScreen()),
          );
        },
        backgroundColor: AppPalette.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Collection', style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Widget _buildKPICard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.caption.copyWith(color: context.appColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headlineSmall.copyWith(color: context.appColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Good morning, Rahul 👋', style: AppTextStyles.titleMedium),
            Text('Tue, 24 Oct 2025', style: AppTextStyles.caption.copyWith(color: context.appColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppPalette.primary),
            tooltip: 'Daily Summary',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailySummaryScreen()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 8),
            child: CircleAvatar(
              backgroundColor: AppPalette.primaryContainer,
              foregroundColor: AppPalette.primary,
              child: Text('RA', style: AppTextStyles.labelMedium),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary strip
            Row(
              children: [
                _buildKPICard(context, "Today's Target", '₹1,24,500', AppPalette.primary, Icons.track_changes_rounded),
                const SizedBox(width: 12),
                _buildKPICard(context, "Collected", '₹87,200', AppPalette.tertiary, Icons.check_circle_outline_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildKPICard(context, "Pending", '₹37,300', AppPalette.warning, Icons.pending_actions_rounded),
                const SizedBox(width: 12),
                _buildKPICard(context, "Borrowers", '28 total', context.appColors.textSecondary ?? const Color(0xFF4A6280), Icons.groups_outlined),
              ],
            ),
            const SizedBox(height: 24),
            
            // Collection Progress
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Progress", style: AppTextStyles.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppPalette.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const Text('70%', style: TextStyle(color: AppPalette.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.70,
                    backgroundColor: AppPalette.surfaceVariant,
                    color: AppPalette.tertiary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('28 collected', style: AppTextStyles.caption.copyWith(color: context.appColors.textSecondary)),
                      Text('12 pending', style: AppTextStyles.caption.copyWith(color: context.appColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Today's Route
            const SectionHeader(title: "Today's Route"),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final statuses = [AppPalette.tertiary, AppPalette.warning, AppPalette.error];
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: statuses[index % statuses.length],
                      radius: 6,
                    ),
                    label: Text('BN${index + 1}', style: AppTextStyles.labelMedium),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppPalette.outlineVariant),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Recent Activity
            SectionHeader(
              title: "Recent Collections",
              actionLabel: "View All",
              onAction: () {},
            ),
            const SizedBox(height: 12),
            ..._mockRecentCollections.map((item) {
              final status = item['status'] as CollectionStatus;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppPalette.surfaceVariant,
                        child: Text(
                          (item['name'] as String).split(' ').map((e) => e[0]).join(),
                          style: TextStyle(color: context.appColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item['name'] as String, style: AppTextStyles.titleMedium),
                            const SizedBox(height: 4),
                            Text('${item['id']} • ${item['time']}', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AmountText(amount: item['amount'] as double),
                          const SizedBox(height: 6),
                          StatusChip(status: status),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 80), // FAB padding
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('History', style: AppTextStyles.titleLarge),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockHistory.length,
        itemBuilder: (context, index) {
          final group = _mockHistory[index];
          final date = group['date'] as String;
          final items = group['items'] as List<Map<String, dynamic>>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: date),
              const SizedBox(height: 12),
              ...items.map((item) {
                final status = item['status'] as CollectionStatus;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppPalette.surfaceVariant,
                          child: Text(
                            (item['name'] as String).split(' ').map((e) => e[0]).join(),
                            style: TextStyle(color: context.appColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item['name'] as String, style: AppTextStyles.titleMedium),
                              const SizedBox(height: 4),
                              Text('${item['id']} • ${item['time']}', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AmountText(amount: item['amount'] as double),
                            const SizedBox(height: 6),
                            StatusChip(status: status),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
