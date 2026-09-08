import 'package:flutter/material.dart';
import '../models/collection_model.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class CollectionProvider with ChangeNotifier {
  List<CollectionModel> _collections = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentIndex = 0;
  int _pendingOfflineCount = 0;
  bool _isOfflineMode = false;

  List<CollectionModel> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentIndex => _currentIndex;
  int get pendingOfflineCount => _pendingOfflineCount;
  bool get isOfflineMode => _isOfflineMode;

  void setNavIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  double get totalCollected => _collections
      .where((c) => c.status == 'collected')
      .fold(0.0, (sum, c) => sum + c.collectedAmount);

  double get totalTarget => _collections.fold(0.0, (sum, c) => sum + c.pendingAmount);

  int get completedCount => _collections.where((c) => c.status == 'collected').length;

  List<CollectionModel> get pendingCustomers =>
      _collections.where((c) => c.status != 'collected').toList();

  CollectionModel? get nextStop => pendingCustomers.isNotEmpty ? pendingCustomers[0] : null;
  CollectionModel? get nextNextStop => pendingCustomers.length > 1 ? pendingCustomers[1] : null;

  Future<void> fetchTodayCollections(String agentEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Check pending offline transactions
    _pendingOfflineCount = await OfflineStorageService.getPendingQueueCount(agentEmail);

    try {
      final fetched = await ApiService.getTodayCollections(agentEmail);
      _collections = fetched;
      _isOfflineMode = false;
      await OfflineStorageService.saveCachedCollections(agentEmail, _collections);

      // If online and have pending offline items, automatically sync them
      if (_pendingOfflineCount > 0) {
        await syncOfflineQueue(agentEmail);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Offline fallback: load cached route from device storage
      final cached = await OfflineStorageService.getCachedCollections(agentEmail);
      if (cached.isNotEmpty) {
        _collections = cached;
        _isOfflineMode = true;
        _errorMessage = 'Offline Mode: Using cached doorstep ledger.';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> recordDeposit({
    required String customerId,
    required String agentEmail,
    required String status,
    required double collectedAmount,
    double? depositTotal,
    double? lateFee,
    double? interest,
    String paymentMode = 'CASH',
    String remarks = '',
    double? latitude,
    double? longitude,
    bool photoCaptured = false,
    String? photoUrl,
    bool signatureCaptured = false,
  }) async {
    final depositPayload = {
      'customerId': customerId,
      'agentEmail': agentEmail,
      'status': status,
      'collectedAmount': collectedAmount,
      'depositTotal': depositTotal,
      'lateFee': lateFee,
      'interest': interest,
      'paymentMode': paymentMode,
      'remarks': remarks,
      'latitude': latitude,
      'longitude': longitude,
      'photoCaptured': photoCaptured || (photoUrl != null && photoUrl.isNotEmpty),
      'photoUrl': photoUrl,
      'signatureCaptured': signatureCaptured,
    };

    try {
      // Try sending live to backend
      final res = await ApiService.recordCollection(
        customerId: customerId,
        agentEmail: agentEmail,
        status: status,
        collectedAmount: collectedAmount,
        depositTotal: depositTotal,
        lateFee: lateFee,
        interest: interest,
        paymentMode: paymentMode,
        remarks: remarks,
        latitude: latitude,
        longitude: longitude,
        photoCaptured: photoCaptured,
        photoUrl: photoUrl,
        signatureCaptured: signatureCaptured,
      );

      // Refetch live list and update local cache
      await fetchTodayCollections(agentEmail);
      return res;
    } catch (e) {
      // Network failed: Queue transaction locally for offline sync
      await OfflineStorageService.queueOfflineDeposit(agentEmail, depositPayload);
      _pendingOfflineCount = await OfflineStorageService.getPendingQueueCount(agentEmail);
      _isOfflineMode = true;

      // Update in-memory collections so UI immediately marks the stop visited
      final offlineReceiptId = 'OFFLINE-RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final updatedList = _collections.map((item) {
        if (item.customerId == customerId || item.id == customerId) {
          return CollectionModel(
            id: item.id,
            customerId: item.customerId,
            name: item.name,
            phone: item.phone,
            email: item.email,
            area: item.area,
            route: item.route,
            pigmyAccountNumber: item.pigmyAccountNumber,
            amount: item.amount,
            pendingAmount: item.pendingAmount > collectedAmount ? item.pendingAmount - collectedAmount : 0.0,
            collectedAmount: item.collectedAmount + collectedAmount,
            balance: item.balance + collectedAmount,
            status: 'collected',
            visitTime: DateTime.now().toIso8601String(),
            paymentMode: paymentMode,
            remarks: remarks,
            latitude: latitude ?? item.latitude,
            longitude: longitude ?? item.longitude,
            photoUrl: item.photoUrl,
            receiptId: offlineReceiptId,
            address: item.address,
          );
        }
        return item;
      }).toList();

      _collections = updatedList;
      await OfflineStorageService.saveCachedCollections(agentEmail, _collections);
      notifyListeners();

      return {
        'success': true,
        'offline': true,
        'receipt_id': offlineReceiptId,
        'message': 'Deposit stored in Offline Ledger. Will sync to vault when online.',
      };
    }
  }

  /// Explicitly syncs all pending offline transactions
  Future<Map<String, dynamic>> syncOfflineQueue(String agentEmail) async {
    _isLoading = true;
    notifyListeners();

    final result = await OfflineStorageService.syncPendingDeposits(agentEmail);
    _pendingOfflineCount = await OfflineStorageService.getPendingQueueCount(agentEmail);

    try {
      final fetched = await ApiService.getTodayCollections(agentEmail);
      _collections = fetched;
      _isOfflineMode = false;
      await OfflineStorageService.saveCachedCollections(agentEmail, _collections);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return result;
  }
}
