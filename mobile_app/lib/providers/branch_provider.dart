import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/audit_model.dart';
import '../models/reconciliation_model.dart';
import '../models/vault_model.dart';
import '../services/api_service.dart';

class BranchProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Analytics & KPIs
  Map<String, dynamic>? _dashboardMetrics;
  List<Map<String, dynamic>> _liveVisits = [];
  List<ReconciliationRecordModel> _pendingMismatches = [];
  Map<String, dynamic>? _dailyRecon;
  List<AccountModel> _maturingAccounts = [];
  List<AuditLogModel> _auditLogs = [];
  VaultSubmissionModel? _vaultToday;
  Map<String, dynamic>? _dbTables;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get dashboardMetrics => _dashboardMetrics;
  List<Map<String, dynamic>> get liveVisits => _liveVisits;
  List<ReconciliationRecordModel> get pendingMismatches => _pendingMismatches;
  Map<String, dynamic>? get dailyRecon => _dailyRecon;
  List<AccountModel> get maturingAccounts => _maturingAccounts;
  List<AuditLogModel> get auditLogs => _auditLogs;
  VaultSubmissionModel? get vaultToday => _vaultToday;
  Map<String, dynamic>? get dbTables => _dbTables;

  // 1. Fetch Manager / Branch KPIs
  Future<void> fetchDashboardMetrics({String? email, String? role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardMetrics = await ApiService.getDashboardAnalytics(email: email, role: role);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // 2. Fetch Live Visits
  Future<void> fetchLiveVisits({String? agentEmail}) async {
    try {
      _liveVisits = await ApiService.getLiveVisits(agentEmail: agentEmail);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // 3. Fetch Pending Reconciliation Mismatches
  Future<void> fetchPendingMismatches({String role = 'Branch Manager'}) async {
    try {
      _pendingMismatches = await ApiService.getPendingMismatches(role: role);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // 4. Fetch Daily Reconciliation
  Future<void> fetchDailyReconciliation({String? date, String? agentEmail, String? role}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _dailyRecon = await ApiService.getDailyReconciliation(date: date, agentEmail: agentEmail, role: role);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // 5. Resolve Mismatch
  Future<bool> resolveMismatch(int id, String resolvedBy, String role, {String note = ''}) async {
    try {
      final success = await ApiService.resolveReconciliation(id, resolvedBy, role, note: note);
      if (success) {
        await fetchPendingMismatches(role: role);
        await fetchDailyReconciliation(role: role);
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // 6. Maturing Accounts
  Future<void> fetchMaturingAccounts({int days = 30}) async {
    try {
      _maturingAccounts = await ApiService.getMaturingSoon(days: days);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // 7. Batch Accrual Runner
  Future<Map<String, dynamic>?> runBatchAccrual({String? month, required String performedBy, required String role}) async {
    try {
      final res = await ApiService.runBatchAccrual(month: month, performedBy: performedBy, performedByRole: role);
      await fetchDashboardMetrics(role: role);
      return res;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // 8. Process Due Maturities
  Future<Map<String, dynamic>?> processMaturity({required String performedBy, required String role}) async {
    try {
      final res = await ApiService.processMaturity(performedBy: performedBy, performedByRole: role);
      await fetchMaturingAccounts();
      return res;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // 9. Fetch Vault Status for Agent / Cashier
  Future<void> fetchVaultToday(String agentEmail) async {
    try {
      _vaultToday = await ApiService.getVaultToday(agentEmail);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // 10. Audit Logs
  Future<void> fetchAuditLogs() async {
    try {
      _auditLogs = await ApiService.getAuditLogs();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // 11. Database Inspection
  Future<void> fetchDbTables() async {
    try {
      _dbTables = await ApiService.getDbTables();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
