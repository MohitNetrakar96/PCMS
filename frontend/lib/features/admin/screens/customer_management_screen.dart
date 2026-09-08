// ============================================================
// customer_management_screen.dart — PCMS Admin Portal
// Paginated, sortable customer data table + Add Customer dialog
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';

// ── Model ────────────────────────────────────────────────────
class AdminCustomerModel {
  const AdminCustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.accountNo,
    required this.area,
    required this.agentAssigned,
    required this.balance,
    required this.status,
    required this.kycStatus,
  });

  final String id;
  final String name;
  final String phone;
  final String accountNo;
  final String area;
  final String agentAssigned;
  final double balance;
  final CollectionStatus status;
  final String kycStatus; // 'Verified', 'Pending', 'Rejected'

  AdminCustomerModel copyWith({
    String? name,
    String? phone,
    String? area,
    String? agentAssigned,
    double? balance,
    CollectionStatus? status,
  }) =>
      AdminCustomerModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        accountNo: accountNo,
        area: area ?? this.area,
        agentAssigned: agentAssigned ?? this.agentAssigned,
        balance: balance ?? this.balance,
        status: status ?? this.status,
        kycStatus: kycStatus,
      );

  factory AdminCustomerModel.fromJson(Map<String, dynamic> json) =>
      AdminCustomerModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        accountNo: json['account_no'] as String,
        area: json['area'] as String,
        agentAssigned: json['agent_assigned'] as String,
        balance: (json['balance'] as num).toDouble(),
        status: _statusFromString(json['status'] as String),
        kycStatus: json['kyc_status'] as String,
      );

  static CollectionStatus _statusFromString(String s) => switch (s) {
        'collected'     => CollectionStatus.collected,
        'not_available' => CollectionStatus.notAvailable,
        'locked'        => CollectionStatus.locked,
        _               => CollectionStatus.pending,
      };
}

// ── Repository ───────────────────────────────────────────────
abstract final class AdminCustomerRepository {
  /// Fetch list of all customers (replace with HTTP call when backend is live)
  static Future<List<AdminCustomerModel>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const [
      AdminCustomerModel(id: '1',  name: 'Arjun Kumar',     phone: '9876543210', accountNo: 'PGM-00842', area: 'Andheri East', agentAssigned: 'Rahul Ahire',    balance: 24500,  status: CollectionStatus.collected,    kycStatus: 'Verified'),
      AdminCustomerModel(id: '2',  name: 'Meera Deshpande', phone: '9845612378', accountNo: 'PGM-01193', area: 'Andheri East', agentAssigned: 'Rahul Ahire',    balance: 18400,  status: CollectionStatus.pending,      kycStatus: 'Verified'),
      AdminCustomerModel(id: '3',  name: 'Vikram Singh',    phone: '9123456780', accountNo: 'PGM-02271', area: 'Kurla West',   agentAssigned: 'Sanjay Sharma',  balance: 32000,  status: CollectionStatus.collected,    kycStatus: 'Verified'),
      AdminCustomerModel(id: '4',  name: 'Sunita Patil',    phone: '9988776655', accountNo: 'PGM-03345', area: 'Kurla West',   agentAssigned: 'Sanjay Sharma',  balance: 15000,  status: CollectionStatus.notAvailable, kycStatus: 'Pending'),
      AdminCustomerModel(id: '5',  name: 'Rahul Jadhav',    phone: '9765432109', accountNo: 'PGM-04421', area: 'Mulund',       agentAssigned: 'Priya Deshmukh', balance: 41200,  status: CollectionStatus.pending,      kycStatus: 'Verified'),
      AdminCustomerModel(id: '6',  name: 'Priya Mehta',     phone: '9654321098', accountNo: 'PGM-05512', area: 'Mulund',       agentAssigned: 'Priya Deshmukh', balance: 22000,  status: CollectionStatus.collected,    kycStatus: 'Verified'),
      AdminCustomerModel(id: '7',  name: 'Santosh Bhosle',  phone: '9543210987', accountNo: 'PGM-06634', area: 'Mulund',       agentAssigned: 'Arjun Kamble',   balance: 12500,  status: CollectionStatus.pending,      kycStatus: 'Rejected'),
      AdminCustomerModel(id: '8',  name: 'Kavita Nair',     phone: '9432109876', accountNo: 'PGM-07781', area: 'Ghatkopar',    agentAssigned: 'Meera Patil',    balance: 35000,  status: CollectionStatus.collected,    kycStatus: 'Verified'),
      AdminCustomerModel(id: '9',  name: 'Rajesh Yadav',    phone: '9321098765', accountNo: 'PGM-08892', area: 'Ghatkopar',    agentAssigned: 'Meera Patil',    balance: 28000,  status: CollectionStatus.pending,      kycStatus: 'Verified'),
      AdminCustomerModel(id: '10', name: 'Anjali Sharma',   phone: '9210987654', accountNo: 'PGM-09903', area: 'Andheri East', agentAssigned: 'Rahul Ahire',    balance: 16400,  status: CollectionStatus.pending,      kycStatus: 'Verified'),
      AdminCustomerModel(id: '11', name: 'Suresh Kamble',   phone: '9109876543', accountNo: 'PGM-10014', area: 'Kurla West',   agentAssigned: 'Sanjay Sharma',  balance: 22000,  status: CollectionStatus.collected,    kycStatus: 'Verified'),
      AdminCustomerModel(id: '12', name: 'Deepa Kulkarni',  phone: '9098765432', accountNo: 'PGM-11125', area: 'Ghatkopar',    agentAssigned: 'Meera Patil',    balance: 19500,  status: CollectionStatus.notAvailable, kycStatus: 'Pending'),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// CustomerManagementScreen
// ─────────────────────────────────────────────────────────────
class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CMSState();
}

class _CMSState extends State<CustomerManagementScreen> {
  final _searchCtrl = TextEditingController();

  List<AdminCustomerModel> _allCustomers = const [];
  bool _loading = true;
  String? _error;

  // Search & Filters
  String _search = '';
  String? _selectedArea;
  
  // Table Pagination
  int _rowsPerPage = 8;
  int _currentPage = 0;

  // Sorting state
  int? _sortColumnIndex;
  bool _sortAscending = true;

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

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await AdminCustomerRepository.fetchAll();
      if (mounted) {
        setState(() {
          _allCustomers = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Sorting ─────────────────────────────────────────────────
  void _onSort<T>(Comparable<T> Function(AdminCustomerModel c) getVal, int colIdx, bool ascending) {
    setState(() {
      _sortColumnIndex = colIdx;
      _sortAscending = ascending;
      _allCustomers.sort((a, b) {
        final aVal = getVal(a);
        final bVal = getVal(b);
        return ascending ? Comparable.compare(aVal, bVal) : Comparable.compare(bVal, aVal);
      });
    });
  }

  // ── Computed lists ──────────────────────────────────────────
  List<String> get _areas {
    final list = _allCustomers.map((c) => c.area).toSet().toList()..sort();
    return list;
  }

  List<AdminCustomerModel> get _filtered {
    final q = _search.toLowerCase();
    return _allCustomers.where((c) {
      final matchQ = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.accountNo.toLowerCase().contains(q) ||
          c.area.toLowerCase().contains(q) ||
          c.agentAssigned.toLowerCase().contains(q);
      final matchArea = _selectedArea == null || c.area == _selectedArea;
      return matchQ && matchArea;
    }).toList();
  }

  List<AdminCustomerModel> get _paginated {
    final list = _filtered;
    final start = _currentPage * _rowsPerPage;
    if (start >= list.length) return [];
    final end = (start + _rowsPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _totalPages {
    final count = _filtered.length;
    if (count == 0) return 1;
    return (count / _rowsPerPage).ceil();
  }

  // ── Actions ─────────────────────────────────────────────────
  void _addCustomer(AdminCustomerModel c) {
    setState(() {
      _allCustomers = [c, ..._allCustomers];
    });
  }

  void _deleteCustomer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text('Are you sure you want to delete this customer record? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _allCustomers.removeWhere((c) => c.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer record deleted.')),
      );
    }
  }

  // ── UI BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Add customer
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer Database', style: AppTextStyles.titleMedium),
                              const SizedBox(height: 2),
                              Text('Manage pigmy accounts, assigned agents, and verify documents.',
                                  style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openAddCustomerDialog(context),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('Add Customer'),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      
                      // Search and Filter Bar
                      _buildFilterBar(),
                      const SizedBox(height: 16),
                      
                      // Main Table Card
                      Expanded(child: _buildTableCard()),
                    ],
                  ),
                ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Search & Filter Bar
  // ─────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // Search
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _search = v;
                _currentPage = 0; // reset to first page
              }),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search customer name, account number, assigned agent…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() { _search = ''; _currentPage = 0; });
                        })
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Area Dropdown
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _selectedArea != null ? AppPalette.primaryContainer : AppPalette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: _selectedArea != null ? AppPalette.primary.withOpacity(0.4) : AppPalette.outlineVariant,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedArea,
              hint: Text('All Areas', style: AppTextStyles.bodySmall.copyWith(color: AppPalette.textSecondary)),
              style: AppTextStyles.bodySmall.copyWith(color: AppPalette.textPrimary),
              icon: Icon(
                _selectedArea != null ? Icons.close_rounded : Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppPalette.textSecondary,
              ),
              onTap: _selectedArea != null ? () => setState(() { _selectedArea = null; _currentPage = 0; }) : null,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All Areas')),
                ..._areas.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
              ],
              onChanged: (v) => setState(() { _selectedArea = v; _currentPage = 0; }),
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Data Table Container Card
  // ─────────────────────────────────────────────────────────
  Widget _buildTableCard() {
    final filtered = _filtered;
    final paginated = _paginated;
    final format = NumberFormat('#,##,##0.00', 'en_IN');

    if (filtered.isEmpty) {
      return const _EmptyState();
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Table container
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 320),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppPalette.surfaceVariant),
                  headingTextStyle: AppTextStyles.labelSmall.copyWith(color: AppPalette.textSecondary),
                  dataTextStyle: AppTextStyles.bodyMedium,
                  columnSpacing: 28,
                  horizontalMargin: 20,
                  dividerThickness: 0.5,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: AppPalette.outlineVariant, width: 0.5),
                  ),
                  columns: [
                    DataColumn(
                      label: const Text('Customer Name'),
                      onSort: (i, asc) => _onSort((c) => c.name, i, asc),
                    ),
                    DataColumn(
                      label: const Text('Account Number'),
                      onSort: (i, asc) => _onSort((c) => c.accountNo, i, asc),
                    ),
                    DataColumn(
                      label: const Text('Area'),
                      onSort: (i, asc) => _onSort((c) => c.area, i, asc),
                    ),
                    DataColumn(
                      label: const Text('Agent Assigned'),
                      onSort: (i, asc) => _onSort((c) => c.agentAssigned, i, asc),
                    ),
                    DataColumn(
                      label: const Text('Balance'),
                      numeric: true,
                      onSort: (i, asc) => _onSort((c) => c.balance, i, asc),
                    ),
                    DataColumn(
                      label: const Text('Collection Status'),
                      onSort: (i, asc) => _onSort((c) => c.status.name, i, asc),
                    ),
                    DataColumn(
                      label: const Text('KYC'),
                    ),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: paginated.map((c) {
                    final initials = c.name.split(' ').take(2).map((w) => w[0]).join().toUpperCase();
                    return DataRow(cells: [
                      // Name
                      DataCell(Row(children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: AppPalette.primaryContainer,
                          child: Text(initials, style: AppTextStyles.labelSmall.copyWith(color: AppPalette.onPrimaryContainer, fontSize: 10)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text(c.phone, style: AppTextStyles.caption),
                          ],
                        ),
                      ])),
                      // Account No
                      DataCell(Text(c.accountNo, style: AppTextStyles.labelMedium.copyWith(color: AppPalette.primary, fontFeatures: const [FontFeature.tabularFigures()]))),
                      // Area
                      DataCell(Text(c.area, style: AppTextStyles.bodySmall)),
                      // Agent Assigned
                      DataCell(Text(c.agentAssigned, style: AppTextStyles.bodySmall)),
                      // Balance
                      DataCell(Text('Rs.${format.format(c.balance)}',
                          style: AppTextStyles.bodyMediumNumeric.copyWith(
                            fontWeight: FontWeight.bold,
                            color: c.status == CollectionStatus.collected ? AppPalette.success : AppPalette.textPrimary,
                          ))),
                      // Collection Status
                      DataCell(StatusChip(status: c.status)),
                      // KYC Status
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.kycStatus == 'Verified'
                              ? AppPalette.successContainer
                              : c.kycStatus == 'Pending'
                                  ? AppPalette.warningContainer
                                  : AppPalette.errorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(c.kycStatus,
                            style: AppTextStyles.caption.copyWith(
                              color: c.kycStatus == 'Verified'
                                  ? AppPalette.onSuccessContainer
                                  : c.kycStatus == 'Pending'
                                      ? AppPalette.onWarningContainer
                                      : AppPalette.onErrorContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            )),
                      )),
                      // Actions
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppPalette.primary),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit customer details — coming soon')),
                          ),
                          tooltip: 'Edit Record',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppPalette.error),
                          onPressed: () => _deleteCustomer(c.id),
                          tooltip: 'Delete Record',
                        ),
                      ])),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        
        // Table Pagination Footer
        const Divider(height: 1),
        _buildPaginationFooter(filtered.length),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Table Pagination Footer UI
  // ─────────────────────────────────────────────────────────
  Widget _buildPaginationFooter(int totalRows) {
    final start = _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, totalRows);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        // Rows count selection
        Text('Rows per page:', style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _rowsPerPage,
          underline: const SizedBox.shrink(),
          style: AppTextStyles.labelSmall.copyWith(color: AppPalette.textPrimary),
          items: [5, 8, 10, 15]
              .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n')))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _rowsPerPage = v;
                _currentPage = 0; // reset to first page
              });
            }
          },
        ),
        const Spacer(),
        // Range indicator
        Text('$start - $end of $totalRows',
            style: AppTextStyles.caption.copyWith(
                color: AppPalette.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(width: 16),
        // Prev button
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          tooltip: 'Previous Page',
        ),
        // Next button
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
          tooltip: 'Next Page',
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Add Customer Modal Form Dialog
  // ─────────────────────────────────────────────────────────
  void _openAddCustomerDialog(BuildContext context) {
    final formKey   = GlobalKey<FormState>();
    final nameCtrl   = TextEditingController();
    final phoneCtrl  = TextEditingController();
    final areaCtrl   = TextEditingController();
    final balCtrl    = TextEditingController();
    final agentCtrl   = TextEditingController(text: 'Rahul Ahire');
    String kycStatus = 'Pending';
    bool uploading   = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.person_add_alt_1_rounded, color: AppPalette.primary),
            const SizedBox(width: 10),
            Text('Register Customer Record', style: AppTextStyles.titleMedium),
          ]),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('General Information', style: AppTextStyles.labelSmall.copyWith(color: AppPalette.textSecondary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Customer Full Name *', prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter customer name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter mobile number';
                        if (v.trim().length != 10) return 'Must be 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Area / Route *', prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter area' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    Text('Pigmy Account Details', style: AppTextStyles.labelSmall.copyWith(color: AppPalette.textSecondary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: balCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Opening Balance (Rs.) *', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty || double.tryParse(v) == null) ? 'Enter opening balance' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: agentCtrl,
                      decoration: const InputDecoration(labelText: 'Assign Agent *', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Assign an agent' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    Text('KYC Verification Documents', style: AppTextStyles.labelSmall.copyWith(color: AppPalette.textSecondary)),
                    const SizedBox(height: 10),
                    // Dash-border upload box placeholder
                    GestureDetector(
                      onTap: () async {
                        setDlgState(() => uploading = true);
                        await Future.delayed(const Duration(milliseconds: 1400));
                        setDlgState(() {
                          uploading = false;
                          kycStatus = 'Verified';
                        });
                      },
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppPalette.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppPalette.outlineVariant, style: BorderStyle.solid, width: 1.2),
                        ),
                        child: uploading
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    kycStatus == 'Verified' ? Icons.verified_user_rounded : Icons.cloud_upload_outlined,
                                    size: 32,
                                    color: kycStatus == 'Verified' ? AppPalette.success : AppPalette.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    kycStatus == 'Verified' ? 'KYC Document Verified Successfully' : 'Upload Identity Proof (Aadhar / PAN)',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: kycStatus == 'Verified' ? FontWeight.bold : FontWeight.normal,
                                      color: kycStatus == 'Verified' ? AppPalette.success : AppPalette.textPrimary,
                                    ),
                                  ),
                                  if (kycStatus != 'Verified')
                                    Text('Support PDF, PNG, JPG up to 5MB', style: AppTextStyles.caption.copyWith(fontSize: 9.5)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                
                // Construct a randomized pigmy account number
                final rng = (DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
                final customer = AdminCustomerModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  accountNo: 'PGM-$rng',
                  area: areaCtrl.text.trim(),
                  agentAssigned: agentCtrl.text.trim(),
                  balance: double.parse(balCtrl.text),
                  status: CollectionStatus.pending,
                  kycStatus: kycStatus,
                );
                
                _addCustomer(customer);
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Customer registered successfully. Account Number: ${customer.accountNo}'),
                    backgroundColor: AppPalette.success,
                  ),
                );
              },
              child: const Text('Save Customer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _EmptyState Component
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: AppPalette.surfaceVariant, shape: BoxShape.circle),
            child: const Icon(Icons.people_alt_outlined, size: 36, color: AppPalette.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('No customers matched your filter', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text('Try searching with different terms or check filter parameters.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _ErrorState Component
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
          Text('Failed to load database records', style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text(message, style: AppTextStyles.bodySmall, textAlign: TextAlign.center, maxLines: 3),
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
