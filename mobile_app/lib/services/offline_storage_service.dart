import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_model.dart';
import 'api_service.dart';

class OfflineStorageService {
  static const String _cachedCollectionsPrefix = 'cached_collections_';
  static const String _offlineQueuePrefix = 'offline_queue_';

  /// Saves today's collections to persistent local device storage
  static Future<void> saveCachedCollections(String agentEmail, List<CollectionModel> collections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachedCollectionsPrefix${agentEmail.trim().toLowerCase()}';
      final jsonList = collections.map((c) => c.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Retrieves cached collections from local device storage
  static Future<List<CollectionModel>> getCachedCollections(String agentEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachedCollectionsPrefix${agentEmail.trim().toLowerCase()}';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        return decoded.map((item) => CollectionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Stores a doorstep collection in the offline sync queue
  static Future<void> queueOfflineDeposit(String agentEmail, Map<String, dynamic> depositData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_offlineQueuePrefix${agentEmail.trim().toLowerCase()}';
      final List<Map<String, dynamic>> queue = await getPendingOfflineDeposits(agentEmail);
      
      // Ensure unique queue item ID and timestamp
      depositData['queued_at'] = DateTime.now().toIso8601String();
      depositData['queue_id'] = 'QUEUE-${DateTime.now().millisecondsSinceEpoch}';
      queue.add(depositData);

      await prefs.setString(key, jsonEncode(queue));
    } catch (_) {}
  }

  /// Retrieves all pending offline deposits waiting to be synced to the vault
  static Future<List<Map<String, dynamic>>> getPendingOfflineDeposits(String agentEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_offlineQueuePrefix${agentEmail.trim().toLowerCase()}';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Returns the count of pending offline transactions
  static Future<int> getPendingQueueCount(String agentEmail) async {
    final list = await getPendingOfflineDeposits(agentEmail);
    return list.length;
  }

  /// Clears or updates the queue after syncing
  static Future<void> clearOfflineQueue(String agentEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_offlineQueuePrefix${agentEmail.trim().toLowerCase()}';
      await prefs.remove(key);
    } catch (_) {}
  }

  /// Synchronizes all queued offline deposits with the backend API
  static Future<Map<String, dynamic>> syncPendingDeposits(String agentEmail) async {
    final pending = await getPendingOfflineDeposits(agentEmail);
    if (pending.isEmpty) {
      return {'total': 0, 'synced': 0, 'failed': 0, 'remaining': 0};
    }

    int synced = 0;
    int failed = 0;
    final List<Map<String, dynamic>> remaining = [];

    for (final item in pending) {
      try {
        await ApiService.recordCollection(
          customerId: item['customerId'] ?? '',
          agentEmail: agentEmail,
          status: item['status'] ?? 'collected',
          collectedAmount: (item['collectedAmount'] as num?)?.toDouble() ?? 0.0,
          depositTotal: (item['depositTotal'] as num?)?.toDouble(),
          lateFee: (item['lateFee'] as num?)?.toDouble(),
          interest: (item['interest'] as num?)?.toDouble(),
          paymentMode: item['paymentMode'] ?? 'CASH',
          remarks: '${item['remarks'] ?? ""} (Offline Synced)'.trim(),
          latitude: (item['latitude'] as num?)?.toDouble(),
          longitude: (item['longitude'] as num?)?.toDouble(),
          photoCaptured: item['photoCaptured'] == true,
          signatureCaptured: item['signatureCaptured'] == true,
        );
        synced++;
      } catch (e) {
        failed++;
        remaining.add(item);
      }
    }

    // Save any items that failed to sync so they can be retried
    final prefs = await SharedPreferences.getInstance();
    final key = '$_offlineQueuePrefix${agentEmail.trim().toLowerCase()}';
    if (remaining.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(remaining));
    }

    return {
      'total': pending.length,
      'synced': synced,
      'failed': failed,
      'remaining': remaining.length,
    };
  }

  // ==========================================
  // OFFLINE CUSTOMER & PASSBOOK MANAGEMENT
  // ==========================================
  static const String _cachedCustomersKey = 'cached_customers_list';
  static const String _offlineCustomerQueueKey = 'offline_customer_queue';

  /// Saves customers list to local persistent cache
  static Future<void> saveCachedCustomers(List<dynamic> customers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedCustomersKey, jsonEncode(customers));
    } catch (_) {}
  }

  /// Retrieves cached customers
  static Future<List<Map<String, dynamic>>> getCachedCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedCustomersKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Queues a newly generated customer & passbook locally
  static Future<void> queueOfflineCustomer(Map<String, dynamic> custData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_offlineCustomerQueueKey);
      final List queue = raw != null && raw.isNotEmpty ? jsonDecode(raw) : [];
      queue.add(custData);
      await prefs.setString(_offlineCustomerQueueKey, jsonEncode(queue));

      // Also prepend to cached customers so it immediately appears in dropdowns & search
      final cached = await getCachedCustomers();
      cached.insert(0, custData);
      await saveCachedCustomers(cached);
    } catch (_) {}
  }

  /// Retrieves offline queued customers
  static Future<List<Map<String, dynamic>>> getPendingOfflineCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_offlineCustomerQueueKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Syncs queued offline customers to backend
  static Future<void> syncPendingCustomers() async {
    final pending = await getPendingOfflineCustomers();
    if (pending.isEmpty) return;

    final List<Map<String, dynamic>> remaining = [];
    for (final item in pending) {
      try {
        await ApiService.createCustomer(item);
      } catch (_) {
        remaining.add(item);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (remaining.isEmpty) {
      await prefs.remove(_offlineCustomerQueueKey);
    } else {
      await prefs.setString(_offlineCustomerQueueKey, jsonEncode(remaining));
    }
  }
}
