// ============================================================
// collection_list_screen.dart  PCMS
// Agent daily customer collection list
// Responsive: card list (mobile)  |  DataTable (wide/web >= 720px)
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/status_chip.dart';
import 'customer_visit_screen.dart';

import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────
class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.area,
    required this.route,
    required this.pigmyAccountNumber,
    required this.pendingAmount,
    required this.status,
    required this.phone,
    required this.address,
    this.visitTime,
    this.remarks,
    this.paymentMode,
    this.email,
    required this.openingBalance,
    this.latitude,
    this.longitude,
    required this.isNew,
    this.kycStatus = 'Pending',
    this.aadharNumber = '',
    this.panNumber = '',
    this.photoCaptured = false,
    this.signatureCaptured = false,
  });

  final String id;
  final String name;
  final String area;
  final String route;
  final String pigmyAccountNumber;
  final double pendingAmount;
  final CollectionStatus status;
  final String phone;
  final String address;
  final String? visitTime;
  final String? remarks;
  final String? paymentMode;
  final String? email;
  final double openingBalance;
  final double? latitude;
  final double? longitude;
  final int isNew;
  final String kycStatus;
  final String aadharNumber;
  final String panNumber;
  final bool photoCaptured;
  final bool signatureCaptured;

  CustomerModel copyWith({
    CollectionStatus? status,
    String? visitTime,
    String? remarks,
    String? paymentMode,
    bool? photoCaptured,
    bool? signatureCaptured,
  }) =>
      CustomerModel(
        id: id,
        name: name,
        area: area,
        route: route,
        pigmyAccountNumber: pigmyAccountNumber,
        pendingAmount: pendingAmount,
        status: status ?? this.status,
        phone: phone,
        address: address,
        visitTime: visitTime ?? this.visitTime,
        remarks: remarks ?? this.remarks,
        paymentMode: paymentMode ?? this.paymentMode,
        email: email,
        openingBalance: openingBalance,
        latitude: latitude,
        longitude: longitude,
        isNew: isNew,
        kycStatus: kycStatus,
        aadharNumber: aadharNumber,
        panNumber: panNumber,
        photoCaptured: photoCaptured ?? this.photoCaptured,
        signatureCaptured: signatureCaptured ?? this.signatureCaptured,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'area': area,
        'route': route,
        'pigmy_account_number': pigmyAccountNumber,
        'pending_amount': pendingAmount,
        'status': status.name,
        'phone': phone,
        'address': address,
        'visit_time': visitTime,
        'remarks': remarks,
        'payment_mode': paymentMode,
        'email': email,
        'opening_balance': openingBalance,
        'latitude': latitude,
        'longitude': longitude,
        'is_new': isNew,
        'kyc_status': kycStatus,
        'aadhar_number': aadharNumber,
        'pan_number': panNumber,
        'photo_captured': photoCaptured ? 1 : 0,
        'signature_captured': signatureCaptured ? 1 : 0,
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        name: json['name'] as String,
        area: json['area'] as String,
        route: json['route'] as String,
        pigmyAccountNumber: json['pigmy_account_number'] as String,
        pendingAmount: (json['pending_amount'] as num).toDouble(),
        status: _statusFromString(json['status'] as String),
        phone: json['phone'] as String,
        address: json['address'] as String,
        visitTime: json['visit_time'] as String?,
        remarks: json['remarks'] as String?,
        paymentMode: json['payment_mode'] as String?,
        email: json['email'] as String?,
        openingBalance: (json['opening_balance'] as num).toDouble(),
        latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
        isNew: json['is_new'] as int? ?? 0,
        kycStatus: json['kyc_status'] as String? ?? 'Pending',
        aadharNumber: json['aadhar_number'] as String? ?? '',
        panNumber: json['pan_number'] as String? ?? '',
        photoCaptured: (json['photo_captured'] as int? ?? 0) == 1,
        signatureCaptured: (json['signature_captured'] as int? ?? 0) == 1,
      );

  static CollectionStatus _statusFromString(String s) {
    switch (s) {
      case 'collected':     return CollectionStatus.collected;
      case 'not_available': return CollectionStatus.notAvailable;
      case 'locked':        return CollectionStatus.locked;
      case 'payment_tomorrow': return CollectionStatus.paymentTomorrow;
      case 'shifted':        return CollectionStatus.shifted;
      default:              return CollectionStatus.pending;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Repository (Real API + Caching + Syncing)
// ─────────────────────────────────────────────────────────────
abstract final class CustomerRepository {
  static const String _baseUrl = 'http://localhost:3000/api/collections';

  /// Sync offline transactions saved in SharedPreferences.
  static Future<bool> syncOfflineCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agentEmail = AuthService.instance.currentUser?.email ?? 'agent@example.com';
      final queue = prefs.getStringList('offline_payments_queue') ?? [];
      
      if (queue.isEmpty) return true;
      
      final transactions = queue.map((txStr) => json.decode(txStr)).toList();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/sync'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': agentEmail,
          'transactions': transactions,
        }),
      );

      if (response.statusCode == 200) {
        await prefs.remove('offline_payments_queue');
        debugPrint('[SyncManager] Offline queue synchronized successfully.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SyncManager] Sync failed: $e');
      return false;
    }
  }

  /// Record payment or visit (online or offline fallback).
  static Future<bool> recordCollection({
    required String customerId,
    required CollectionStatus status,
    required double collectedAmount,
    required String paymentMode,
    required String remarks,
    double? latitude,
    double? longitude,
    bool? photoCaptured,
    bool? signatureCaptured,
  }) async {
    final agentEmail = AuthService.instance.currentUser?.email ?? 'agent@example.com';
    final d = DateTime.now();
    final visitTime = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    
    final payload = {
      'customerId': customerId,
      'agentEmail': agentEmail,
      'status': status.name,
      'collectedAmount': collectedAmount,
      'paymentMode': paymentMode,
      'remarks': remarks,
      'visitTime': visitTime,
      'latitude': latitude,
      'longitude': longitude,
      'photoCaptured': photoCaptured == true,
      'signatureCaptured': signatureCaptured == true,
    };

    // Save to local cached list so changes are reflected in UI immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('today_collections_cache');
      if (cacheStr != null) {
        final List<dynamic> decoded = json.decode(cacheStr);
        final index = decoded.indexWhere((item) => item['id'] == customerId);
        if (index != -1) {
          decoded[index]['status'] = status.name;
          decoded[index]['collected_amount'] = collectedAmount;
          decoded[index]['visit_time'] = visitTime;
          decoded[index]['remarks'] = remarks;
          decoded[index]['payment_mode'] = paymentMode;
          decoded[index]['photo_captured'] = photoCaptured == true ? 1 : 0;
          decoded[index]['signature_captured'] = signatureCaptured == true ? 1 : 0;
          await prefs.setString('today_collections_cache', json.encode(decoded));
        }
      }
    } catch (e) {
      debugPrint('Error updating local collection cache: $e');
    }

    try {
      // Attempt online API call
      final response = await http.post(
        Uri.parse('$_baseUrl/record'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        debugPrint('Recorded collection online.');
        return true;
      }
    } catch (e) {
      debugPrint('Network unavailable, saving collection offline: $e');
    }

    // Offline mode: Queue payment transaction details locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList('offline_payments_queue') ?? [];
      queue.add(json.encode(payload));
      await prefs.setStringList('offline_payments_queue', queue);
      debugPrint('Enqueued collection transaction offline.');
      return true;
    } catch (e) {
      debugPrint('Error enqueuing transaction locally: $e');
      return false;
    }
  }

  /// Fetch today's collection schedule (from API, or fallback to offline SharedPreferences cache)
  static Future<List<CustomerModel>> fetchTodayList() async {
    final prefs = await SharedPreferences.getInstance();
    final agentEmail = AuthService.instance.currentUser?.email ?? 'agent@example.com';
    
    // Attempt online fetch
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/today?email=$agentEmail'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        // Update local cache
        await prefs.setString('today_collections_cache', response.body);
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => CustomerModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load collections online, loading from cache: $e');
    }

    // Fallback to offline cache
    final cacheStr = prefs.getString('today_collections_cache');
    if (cacheStr != null) {
      final List<dynamic> list = json.decode(cacheStr);
      return list.map((item) => CustomerModel.fromJson(item)).toList();
    }

    return const [];
  }
}

// ─────────────────────────────────────────────────────────────
// CollectionListScreen
// ─────────────────────────────────────────────────────────────
class CollectionListScreen extends StatefulWidget {
  const CollectionListScreen({super.key});

  @override
  State<CollectionListScreen> createState() => _State();
}

class _State extends State<CollectionListScreen> {
  final _searchCtrl = TextEditingController();

  List<CustomerModel> _customers = const [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _selectedArea;

  // ── Computed ─────────────────────────────────────────────────
  List<String> get _areas {
    final s = _customers.map((c) => c.area).toSet().toList()..sort();
    return s;
  }

  List<CustomerModel> get _filtered {
    final q = _search.toLowerCase();
    return _customers.where((c) {
      final matchQ = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.pigmyAccountNumber.toLowerCase().contains(q) ||
          c.area.toLowerCase().contains(q) ||
          c.route.toLowerCase().contains(q) ||
          c.phone.contains(q);
      final matchArea = _selectedArea == null || c.area == _selectedArea;
      return matchQ && matchArea;
    }).toList();
  }

  int get _visitedCount => _customers
      .where((c) =>
          c.status == CollectionStatus.collected ||
          c.status == CollectionStatus.notAvailable)
      .length;

  double get _collectedAmt => _customers
      .where((c) => c.status == CollectionStatus.collected)
      .fold(0.0, (s, c) => s + c.pendingAmount);

  double get _pendingAmt => _customers
      .where((c) => c.status == CollectionStatus.pending)
      .fold(0.0, (s, c) => s + c.pendingAmount);

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await CustomerRepository.fetchTodayList();
      if (mounted) setState(() { _customers = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _onRefresh() => _load();

  void _openCustomer(CustomerModel c) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => CustomerVisitScreen(customer: c)));

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: LayoutBuilder(
        builder: (_, c) =>
            c.maxWidth >= 720 ? _wideLayout() : _mobileLayout(),
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────
  Widget _mobileLayout() {
    final today = _fmtDate(DateTime.now());
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverAppBar(
          pinned: true,
          floating: true,
          snap: true,
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Customers',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text(today, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: () async {
                setState(() => _loading = true);
                final success = await CustomerRepository.syncOfflineCollections();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offline collections synced successfully.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync completed (no offline transactions or backend unreachable).')),
                  );
                }
                await _load();
              },
              tooltip: 'Sync Latest Data',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _onRefresh,
              tooltip: 'Refresh',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: _loading
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppPalette.success))
                : const SizedBox.shrink(),
          ),
        ),
        SliverToBoxAdapter(child: _SummaryStrip(
          visited: _visitedCount, total: _customers.length,
          collectedAmt: _collectedAmt, pendingAmt: _pendingAmt,
        )),
      ],
      body: Column(children: [
        _SearchFilterBar(
          controller: _searchCtrl, areas: _areas,
          selectedArea: _selectedArea,
          onSearch: (v) => setState(() => _search = v),
          onAreaChanged: (v) => setState(() => _selectedArea = v),
          onClearArea: () => setState(() => _selectedArea = null),
        ),
        Expanded(child: _buildListBody()),
      ]),
    );
  }

  Widget _buildListBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    final data = _filtered;
    if (data.isEmpty) return const _EmptyState();
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppPalette.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _CustomerCard(
          customer: data[i],
          index: i + 1,
          onTap: () => _openCustomer(data[i]),
        ),
      ),
    );
  }

  // ── Wide layout ───────────────────────────────────────────────
  Widget _wideLayout() {
    final today = _fmtDate(DateTime.now());
    return Column(children: [
      AppBar(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Customer Collection List',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Agent view  $today',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white70),
            onPressed: () async {
              setState(() => _loading = true);
              final success = await CustomerRepository.syncOfflineCollections();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offline collections synced successfully.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync completed (no offline transactions or backend unreachable).')),
                );
              }
              await _load();
            },
            tooltip: 'Sync Latest Data',
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              label: const Text('Refresh', style: TextStyle(color: Colors.white70)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      _SummaryStrip(
        visited: _visitedCount, total: _customers.length,
        collectedAmt: _collectedAmt, pendingAmt: _pendingAmt,
      ),
      _SearchFilterBar(
        controller: _searchCtrl, areas: _areas,
        selectedArea: _selectedArea,
        onSearch: (v) => setState(() => _search = v),
        onAreaChanged: (v) => setState(() => _selectedArea = v),
        onClearArea: () => setState(() => _selectedArea = null),
      ),
      Expanded(child: _buildWideBody()),
    ]);
  }

  Widget _buildWideBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    final data = _filtered;
    if (data.isEmpty) return const _EmptyState();
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppPalette.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: _buildDataTable(data),
      ),
    );
  }

  Widget _buildDataTable(List<CustomerModel> data) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return DecoratedBox(
      decoration: appCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(AppPalette.surfaceVariant),
            headingTextStyle: AppTextStyles.labelSmall
                .copyWith(color: AppPalette.textSecondary),
            dataTextStyle: AppTextStyles.bodyMedium,
            columnSpacing: 28,
            horizontalMargin: 20,
            dividerThickness: 0.5,
            border: TableBorder(
              horizontalInside: BorderSide(
                  color: AppPalette.outlineVariant, width: 0.5),
            ),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Pigmy Account')),
              DataColumn(label: Text('Area / Route')),
              DataColumn(label: Text('Amount'), numeric: true),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Visited')),
              DataColumn(label: Text('')),
            ],
            rows: data.asMap().entries.map((e) {
              final i = e.key; final c = e.value;
              final initials = c.name.split(' ')
                  .take(2).map((w) => w[0]).join().toUpperCase();
              return DataRow(cells: [
                DataCell(Text('${i + 1}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppPalette.textSecondary))),
                DataCell(Row(children: [
                  CircleAvatar(radius: 16,
                      backgroundColor: AppPalette.primaryContainer,
                      child: Text(initials,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppPalette.onPrimaryContainer))),
                  const SizedBox(width: 10),
                  Column(mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.name, style: AppTextStyles.bodyMedium),
                            if (c.isNew == 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppPalette.successContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'NEW',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppPalette.onSuccessContainer,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(c.phone, style: AppTextStyles.caption),
                      ]),
                ])),
                DataCell(Text(c.pigmyAccountNumber,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppPalette.primary,
                            fontFeatures: const [FontFeature.tabularFigures()]))),
                DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.area, style: AppTextStyles.bodySmall),
                      Text(c.route, style: AppTextStyles.caption),
                    ])),
                DataCell(Text('Rs.${fmt.format(c.pendingAmount)}',
                    style: AppTextStyles.bodyMediumNumeric.copyWith(
                        color: c.status == CollectionStatus.collected
                            ? AppPalette.success
                            : AppPalette.textPrimary))),
                DataCell(StatusChip(status: c.status)),
                DataCell(c.visitTime != null
                    ? Text(c.visitTime!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppPalette.textPrimary,
                                fontWeight: FontWeight.w600))
                    : Text('—', style: AppTextStyles.caption)),
                DataCell(TextButton(
                  onPressed: () => _openCustomer(c),
                  child: const Text('View'),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${_kDays[d.weekday - 1]}, ${d.day} ${_kMonths[d.month - 1]} ${d.year}';
}

const _kDays   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
const _kMonths = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];

// ─────────────────────────────────────────────────────────────
// _SummaryStrip  — navy banner with visit progress
// ─────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.visited,
    required this.total,
    required this.collectedAmt,
    required this.pendingAmt,
  });
  final int visited, total;
  final double collectedAmt, pendingAmt;

  @override
  Widget build(BuildContext context) {
    final progress  = total > 0 ? visited / total : 0.0;
    final pct       = '${(progress * 100).toStringAsFixed(0)}%';
    final fmt       = NumberFormat('#,##,##0', 'en_IN');

    return Container(
      color: AppPalette.primary,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Headline row
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$visited of $total visited today',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text('$pct of today\'s route complete',
                  style: AppTextStyles.caption.copyWith(color: Colors.white60)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: Colors.white24),
            ),
            child: Text('$visited / $total',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.18),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppPalette.success),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 14),
        // Amount pills
        Row(children: [
          _Pill(
            dot: AppPalette.success,
            label: 'Collected',
            value: 'Rs.${fmt.format(collectedAmt)}',
          ),
          const SizedBox(width: 10),
          _Pill(
            dot: AppPalette.warning,
            label: 'Pending',
            value: 'Rs.${fmt.format(pendingAmt)}',
          ),
        ]),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.dot, required this.label, required this.value});
  final Color dot;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: dot.withOpacity(0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(color: Colors.white60)),
          Text(value,
              style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SearchFilterBar  — sticky search + area dropdown
// ─────────────────────────────────────────────────────────────
class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar({
    required this.controller,
    required this.areas,
    required this.selectedArea,
    required this.onSearch,
    required this.onAreaChanged,
    required this.onClearArea,
  });

  final TextEditingController controller;
  final List<String> areas;
  final String? selectedArea;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onAreaChanged;
  final VoidCallback onClearArea;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        // Search
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search name, account, area…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          controller.clear();
                          onSearch('');
                        })
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Area dropdown
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selectedArea != null
                ? AppPalette.primaryContainer
                : AppPalette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: selectedArea != null
                    ? AppPalette.primary.withOpacity(0.4)
                    : AppPalette.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedArea,
              hint: Text('All Areas',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppPalette.textSecondary)),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppPalette.textPrimary),
              icon: Icon(
                  selectedArea != null
                      ? Icons.close_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppPalette.textSecondary),
              onTap: selectedArea != null ? () => onClearArea() : null,
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All Areas')),
                ...areas.map((a) =>
                    DropdownMenuItem<String?>(value: a, child: Text(a))),
              ],
              onChanged: onAreaChanged,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _CustomerCard  — mobile list item
// ─────────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.index,
    required this.onTap,
  });
  final CustomerModel customer;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c   = customer;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final initials = c.name.split(' ').take(2).map((w) => w[0]).join().toUpperCase();
    final isCollected = c.status == CollectionStatus.collected;

    return DecoratedBox(
      decoration: appCardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: avatar + name + chip ────────────────
                Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppPalette.primaryContainer,
                    child: Text(initials,
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppPalette.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(c.name,
                                  style: AppTextStyles.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (c.isNew == 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppPalette.successContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'NEW',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppPalette.onSuccessContainer,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppPalette.textSecondary),
                          const SizedBox(width: 2),
                          Text('${c.area}  ${c.route}',
                              style: AppTextStyles.caption),
                        ]),
                      ],
                    ),
                  ),
                  StatusChip(status: c.status),
                ]),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // ── Row 2: account + amount + visited ──────────
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // Pigmy account
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pigmy Account', style: AppTextStyles.caption),
                        const SizedBox(height: 3),
                        Text(c.pigmyAccountNumber,
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppPalette.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ])),
                      ],
                    ),
                  ),
                  // Amount
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Amount Due', style: AppTextStyles.caption),
                    const SizedBox(height: 3),
                    Text('Rs.${fmt.format(c.pendingAmount)}',
                        style: AppTextStyles.bodyMediumNumeric.copyWith(
                            color: isCollected
                                ? AppPalette.success
                                : AppPalette.textPrimary)),
                  ]),
                  // Visit time (only when visited)
                  if (c.visitTime != null) ...[
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Visited at', style: AppTextStyles.caption),
                      const SizedBox(height: 3),
                      Text(c.visitTime!,
                          style: AppTextStyles.caption.copyWith(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ]),
                  ],
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: c.maxHeight > 0 ? c.maxHeight : 400,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 88, height: 88,
                decoration: const BoxDecoration(
                  color: AppPalette.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined,
                    size: 40, color: AppPalette.onPrimaryContainer),
              ),
              const SizedBox(height: 20),
              Text('No customers assigned for today',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppPalette.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                  'Your assignment list is empty.\nContact your branch manager or pull down to refresh.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// _ErrorState
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
          const Icon(Icons.cloud_off_rounded,
              size: 48, color: AppPalette.textDisabled),
          const SizedBox(height: 16),
          Text('Could not load customers',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text(message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
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
}
