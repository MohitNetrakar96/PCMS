// ============================================================
// daily_summary_screen.dart  PCMS
// Agent daily summary  stat cards  bar chart  pending visits
// Responsive: 2x2 grid (mobile)  4-across row (wide >= 720px)
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/section_header.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────
class PendingVisit {
  const PendingVisit({
    required this.name,
    required this.accountNumber,
    required this.area,
    required this.route,
    required this.amount,
    required this.status,
    this.reason,
  });
  final String name;
  final String accountNumber;
  final String area;
  final String route;
  final double amount;
  final CollectionStatus status;
  final String? reason;
}

class DailySummary {
  const DailySummary({
    this.totalAssigned  = 0,
    this.totalVisited   = 0,
    this.totalCollected = 0,
    this.totalAmount    = 0.0,
    this.cashAmount     = 0.0,
    this.upiAmount      = 0.0,
    this.chequeAmount   = 0.0,
    this.neftAmount     = 0.0,
    this.pendingVisits  = const [],
  });

  final int    totalAssigned;
  final int    totalVisited;
  final int    totalCollected;
  final double totalAmount;
  final double cashAmount;
  final double upiAmount;
  final double chequeAmount;
  final double neftAmount;
  final List<PendingVisit> pendingVisits;

  double get collectionPct =>
      totalAssigned > 0 ? (totalCollected / totalAssigned) * 100 : 0.0;

  bool get isEmpty =>
      totalAssigned == 0 &&
      totalAmount == 0 &&
      pendingVisits.isEmpty;

  factory DailySummary.fromJson(Map<String, dynamic> j) => DailySummary(
        totalAssigned:  j['total_assigned']  as int,
        totalVisited:   j['total_visited']   as int,
        totalCollected: j['total_collected'] as int,
        totalAmount:    (j['total_amount']   as num).toDouble(),
        cashAmount:     (j['cash_amount']    as num).toDouble(),
        upiAmount:      (j['upi_amount']     as num).toDouble(),
        chequeAmount:   (j['cheque_amount']  as num).toDouble(),
        neftAmount:     (j['neft_amount']    as num).toDouble(),
        pendingVisits: (j['pending_visits'] as List)
            .map((e) => PendingVisit(
                  name:          e['name']           as String,
                  accountNumber: e['account_number'] as String,
                  area:          e['area']           as String,
                  route:         e['route']          as String,
                  amount:        (e['amount']        as num).toDouble(),
                  status: _statusFrom(e['status']    as String),
                  reason:        e['reason']         as String?,
                ))
            .toList(),
      );

  static CollectionStatus _statusFrom(String s) => switch (s) {
        'collected'     => CollectionStatus.collected,
        'not_available' => CollectionStatus.notAvailable,
        'locked'        => CollectionStatus.locked,
        _               => CollectionStatus.pending,
      };
}

// ─────────────────────────────────────────────────────────────
// Repository  (swap body with real HTTP call)
// ─────────────────────────────────────────────────────────────
abstract final class SummaryRepository {
  /// TODO: replace with http.get + DailySummary.fromJson(...)
  static Future<DailySummary> fetch(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const DailySummary();
  }
}

// ─────────────────────────────────────────────────────────────
// DailySummaryScreen
// ─────────────────────────────────────────────────────────────
class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key, this.date});
  final DateTime? date;

  @override
  State<DailySummaryScreen> createState() => _DSState();
}

class _DSState extends State<DailySummaryScreen> {
  late DateTime      _date;
  DailySummary?      _summary;
  bool               _loading = true;
  String?            _error;
  bool               _submitting = false;

  static final _dtFmt = DateFormat('EEE, dd MMM yyyy');
  static final _amt   = NumberFormat('#,##,##0.00', 'en_IN');
  static final _amtK  = NumberFormat('#,##,##0',    'en_IN');

  @override
  void initState() {
    super.initState();
    _date = widget.date ?? DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await SummaryRepository.fetch(_date);
      if (mounted) setState(() { _summary = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _submitSummary() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Daily Summary?'),
        content: Text(
          'This will submit your summary for ${_dtFmt.format(_date)} to the branch manager.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Summary submitted successfully.'),
      backgroundColor: AppPalette.success,
    ));
  }

  String _fmtShort(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return _amtK.format(v);
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily Summary'),
          Text(_dtFmt.format(_date),
              style: AppTextStyles.caption
                  .copyWith(color: AppPalette.textSecondary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          // Date picker
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Change date',
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now(),
              );
              if (d != null && mounted) {
                setState(() { _date = d; _loading = true; _summary = null; });
                _load();
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);

    final s = _summary!;
    final wide = MediaQuery.of(context).size.width >= 720;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppPalette.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, wide ? 40 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat cards ─────────────────────────────────
            _buildStatGrid(s, wide),
            const SizedBox(height: 24),
            // ── Chart ──────────────────────────────────────
            _buildChartCard(s),
            const SizedBox(height: 24),
            // ── Pending visits ─────────────────────────────
            _buildPendingList(s),
            const SizedBox(height: 28),
            // ── Actions ────────────────────────────────────
            _buildActions(wide),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Stat cards grid
  // ─────────────────────────────────────────────────────────
  Widget _buildStatGrid(DailySummary s, bool wide) {
    final pct = s.collectionPct;
    final cards = [
      _StatCard(
        icon: Icons.people_alt_outlined,
        title: 'Total Visited',
        value: '${s.totalVisited}',
        sub: 'of ${s.totalAssigned} assigned',
        accent: AppPalette.primary,
      ),
      _StatCard(
        icon: Icons.check_circle_outline_rounded,
        title: 'Collected',
        value: '${s.totalCollected}',
        sub: '${s.totalAssigned - s.totalCollected} pending',
        accent: AppPalette.success,
      ),
      _StatCard(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Total Amount',
        value: 'Rs.${_fmtShort(s.totalAmount)}',
        sub: _amt.format(s.totalAmount),
        accent: AppPalette.primary,
        highlight: true,
      ),
      _StatCard(
        icon: Icons.donut_small_outlined,
        title: 'Collection %',
        value: '${pct.toStringAsFixed(1)}%',
        sub: pct >= 80 ? 'On target' : 'Below target',
        accent: pct >= 80 ? AppPalette.success : AppPalette.warning,
        progress: pct / 100,
      ),
    ];

    if (wide) {
      return Row(
        children: cards
            .map((c) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: c)))
            .toList(),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: cards,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Bar chart card
  // ─────────────────────────────────────────────────────────
  Widget _buildChartCard(DailySummary s) {
    final hasData = s.cashAmount + s.upiAmount + s.chequeAmount + s.neftAmount > 0;
    final amounts = [s.cashAmount, s.upiAmount, s.chequeAmount, s.neftAmount];
    final maxY = (hasData
        ? (amounts.reduce((a, b) => a > b ? a : b) * 1.35)
        : 10000.0);
    final colors = [
      AppPalette.primary,
      AppPalette.success,
      AppPalette.warning,
      const Color(0xFF2563EB),
    ];
    const labels = ['Cash', 'UPI', 'Cheque', 'NEFT'];

    BarChartGroupData makeBar(int x, double val, Color c) => BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: val,
              color: c,
              width: 36,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5), topRight: Radius.circular(5)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true, toY: maxY,
                color: AppPalette.surfaceVariant,
              ),
            ),
          ],
        );

    double calcInterval(double max) {
      if (max <= 5000)  return 1000;
      if (max <= 20000) return 5000;
      if (max <= 50000) return 10000;
      return 25000;
    }

    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: 'Collection by Payment Mode'),
          const SizedBox(height: 4),
          // Legend row
          Wrap(
            spacing: 16,
            children: List.generate(4, (i) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: colors[i], shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(labels[i], style: AppTextStyles.caption),
              ],
            )),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            _ChartEmptyState()
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppPalette.primary.withOpacity(0.88),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '${labels[group.x]}\nRs.${_amt.format(rod.toY)}',
                        AppTextStyles.labelSmall
                            .copyWith(color: Colors.white, height: 1.6),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[v.toInt()],
                              style: AppTextStyles.caption
                                  .copyWith(color: AppPalette.textSecondary)),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: calcInterval(maxY),
                        getTitlesWidget: (v, _) {
                          if (v == 0) return const SizedBox.shrink();
                          final label = v >= 100000
                              ? '${(v / 100000).toStringAsFixed(1)}L'
                              : v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(0)}K'
                                  : v.toInt().toString();
                          return Text(label,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppPalette.textSecondary),
                              textAlign: TextAlign.right);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: calcInterval(maxY),
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppPalette.outlineVariant,
                      strokeWidth: 0.6,
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < 4; i++)
                      makeBar(i, amounts[i], colors[i]),
                  ],
                ),
                duration: const Duration(milliseconds: 400),
              ),
            ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Pending / failed visits
  // ─────────────────────────────────────────────────────────
  Widget _buildPendingList(DailySummary s) {
    final items = s.pendingVisits;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Pending & Failed Visits'),
      const SizedBox(height: 12),
      if (items.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: AppPalette.successContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(children: [
            const Icon(Icons.task_alt_rounded,
                color: AppPalette.success, size: 36),
            const SizedBox(height: 8),
            Text('All visits completed',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppPalette.onSuccessContainer)),
            Text('No pending visits for today.',
                style: AppTextStyles.caption
                    .copyWith(color: AppPalette.textSecondary)),
          ]),
        )
      else
        ...items.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(bottom: e.key < items.length - 1 ? 10 : 0),
          child: _PendingItem(visit: e.value),
        )),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // Action buttons
  // ─────────────────────────────────────────────────────────
  Widget _buildActions(bool wide) {
    final download = OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF report download — coming soon'))),
      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
      label: const Text('Download PDF Report'),
    );

    final submit = ElevatedButton.icon(
      onPressed: _submitting ? null : _submitSummary,
      icon: _submitting
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : const Icon(Icons.send_rounded, size: 18),
      label: Text(_submitting ? 'Submitting…' : 'Submit to Branch'),
    );

    if (wide) {
      return Row(children: [
        Expanded(child: SizedBox(height: 50, child: download)),
        const SizedBox(width: 16),
        Expanded(child: SizedBox(height: 50, child: submit)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(height: 50, child: submit),
      const SizedBox(height: 10),
      SizedBox(height: 50, child: download),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// _StatCard
// ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.sub,
    required this.accent,
    this.highlight = false,
    this.progress,
  });
  final IconData icon;
  final String title, value, sub;
  final Color accent;
  final bool highlight;
  final double? progress; // 0.0..1.0

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? AppPalette.primary : AppPalette.surface;
    final fg = highlight ? Colors.white : AppPalette.textPrimary;
    final fgSub = highlight ? Colors.white60 : AppPalette.textSecondary;
    final iconBg = highlight
        ? Colors.white.withOpacity(0.15)
        : accent.withOpacity(0.10);
    final iconFg = highlight ? Colors.white : accent;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: highlight
            ? const [
                BoxShadow(
                    color: Color(0x280B2545), blurRadius: 12, offset: Offset(0, 4))
              ]
            : appCardDecoration.boxShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Icon badge
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconFg),
        ),
        const Spacer(),
        // Value
        Text(value,
            style: AppTextStyles.titleLarge.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(title,
            style: AppTextStyles.labelSmall.copyWith(color: fgSub)),
        const SizedBox(height: 2),
        Text(sub,
            style: AppTextStyles.caption.copyWith(color: fgSub, fontSize: 10),
            maxLines: 1),
        // Progress bar (for collection %)
        if (progress != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: highlight
                  ? Colors.white.withOpacity(0.2)
                  : AppPalette.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                  highlight ? Colors.white : accent),
              minHeight: 3,
            ),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _PendingItem
// ─────────────────────────────────────────────────────────────
class _PendingItem extends StatelessWidget {
  const _PendingItem({required this.visit});
  final PendingVisit visit;

  @override
  Widget build(BuildContext context) {
    final v       = visit;
    final fmt     = NumberFormat('#,##,##0.00', 'en_IN');
    final initials = v.name.split(' ').take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();

    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppPalette.primaryContainer,
            child: Text(initials,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppPalette.onPrimaryContainer)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(v.name,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                StatusChip(status: v.status),
              ]),
              const SizedBox(height: 3),
              Text('${v.accountNumber}  •  ${v.area}  •  ${v.route}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppPalette.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (v.reason != null) ...[
                const SizedBox(height: 3),
                Text(v.reason!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppPalette.warning),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Due', style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text('Rs.${fmt.format(v.amount)}',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _ChartEmptyState
// ─────────────────────────────────────────────────────────────
class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();
  @override
  Widget build(BuildContext context) => Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppPalette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.bar_chart_rounded,
              size: 48, color: AppPalette.textDisabled),
          const SizedBox(height: 10),
          Text('No collection data yet',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppPalette.textSecondary)),
          Text('Data appears after collections are recorded.',
              style: AppTextStyles.caption),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// _ErrorState
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppPalette.textDisabled),
            const SizedBox(height: 14),
            Text('Could not load summary',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            Text(message,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ]),
        ),
      );
}
