import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/collection_model.dart';
import '../models/account_model.dart';
import '../models/audit_model.dart';
import '../models/reconciliation_model.dart';
import '../models/vault_model.dart';

import 'offline_storage_service.dart';

class ApiService {
  // Candidate host URLs for production cloud & local testing
  static final List<String> candidateUrls = [
    'https://pcms-api.onrender.com/api',
    'http://127.0.0.1:3000/api',
    'http://192.168.31.102:3000/api',
    'http://10.0.2.2:3000/api',
    'http://localhost:3000/api',
  ];
  static String baseUrl = 'https://pcms-api.onrender.com/api';

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  /// Proactively discovers the fastest accessible backend endpoint
  static Future<String> autoDiscoverServer() async {
    for (final candidate in candidateUrls) {
      try {
        final res = await http.get(Uri.parse('$candidate/health')).timeout(const Duration(milliseconds: 800));
        if (res.statusCode == 200) {
          baseUrl = candidate;
          return candidate;
        }
      } catch (_) {}
    }
    return baseUrl;
  }

  // Fast POST with auto-fallback
  static Future<http.Response> _postWithFallback(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: 1500));
      if (res.statusCode < 500) return res;
    } catch (_) {}

    for (final alt in candidateUrls) {
      if (alt == baseUrl) continue;
      try {
        final res = await http.post(
          Uri.parse('$alt$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(milliseconds: 1200));
        if (res.statusCode < 500) {
          baseUrl = alt;
          return res;
        }
      } catch (_) {}
    }
    throw Exception('Connection unavailable.');
  }

  // Fast GET with auto-fallback
  static Future<http.Response> _getWithFallback(String pathAndQuery) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$pathAndQuery')).timeout(const Duration(milliseconds: 1500));
      if (res.statusCode < 500) return res;
    } catch (_) {}

    for (final alt in candidateUrls) {
      if (alt == baseUrl) continue;
      try {
        final res = await http.get(Uri.parse('$alt$pathAndQuery')).timeout(const Duration(milliseconds: 1200));
        if (res.statusCode < 500) {
          baseUrl = alt;
          return res;
        }
      } catch (_) {}
    }
    throw Exception('Connection unavailable.');
  }

  // Fast PUT with auto-fallback
  static Future<http.Response> _putWithFallback(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: 1500));
      if (res.statusCode < 500) return res;
    } catch (_) {}

    for (final alt in candidateUrls) {
      if (alt == baseUrl) continue;
      try {
        final res = await http.put(
          Uri.parse('$alt$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(milliseconds: 1200));
        if (res.statusCode < 500) {
          baseUrl = alt;
          return res;
        }
      } catch (_) {}
    }
    throw Exception('Connection unavailable.');
  }

  // Fast DELETE with auto-fallback
  static Future<http.Response> _deleteWithFallback(String path) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl$path')).timeout(const Duration(milliseconds: 1500));
      if (res.statusCode < 500) return res;
    } catch (_) {}

    for (final alt in candidateUrls) {
      if (alt == baseUrl) continue;
      try {
        final res = await http.delete(Uri.parse('$alt$path')).timeout(const Duration(milliseconds: 1200));
        if (res.statusCode < 500) {
          baseUrl = alt;
          return res;
        }
      } catch (_) {}
    }
    throw Exception('Connection unavailable.');
  }

  // ==========================================
  // 1. AUTHENTICATION & USERS
  // ==========================================

  static Future<UserModel> asyncLogin(String email, String password, {String? expectedRole}) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Email and password are required.');
    }

    try {
      final res = await _postWithFallback('/auth/login', {
        'email': cleanEmail,
        'password': password,
        'expectedRole': expectedRole,
      });

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true && data['user'] != null) {
        return UserModel.fromJson(data['user'], token: data['token']);
      } else if (data['error'] != null) {
        throw Exception(data['error'].toString());
      } else {
        throw Exception('Authentication failed. Please verify credentials.');
      }
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '').trim();
      if (err.toLowerCase().contains('connection unavailable') ||
          err.toLowerCase().contains('socketexception') ||
          err.toLowerCase().contains('timeoutexception') ||
          err.toLowerCase().contains('clientexception') ||
          err.toLowerCase().contains('failed host lookup')) {
        throw Exception('Unable to connect to banking server. Please check your network or server connection.');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? employeeId,
  }) async {
    final res = await _postWithFallback('/auth/register', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role,
      'employeeId': employeeId?.trim(),
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed.');
    }
  }

  static Future<Map<String, dynamic>> sendOtp(String target) async {
    final res = await _postWithFallback('/auth/send-otp', {'email': target.trim()});
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to send OTP.');
    }
  }

  static Future<UserModel> verifyOtp(String target, String code, {String? expectedRole}) async {
    final res = await _postWithFallback('/auth/verify-otp', {
      'email': target.trim(),
      'code': code.trim(),
      'expectedRole': expectedRole,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['user'], token: data['token']);
    } else {
      throw Exception(data['error'] ?? 'Invalid or expired OTP.');
    }
  }

  static Future<bool> resetPasswordOtp({
    required String email,
    required String code,
    required String password,
  }) async {
    final res = await _postWithFallback('/auth/reset-password-otp', {
      'email': email.trim(),
      'code': code.trim(),
      'password': password,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['error'] ?? 'Password reset failed.');
    }
  }

  static Future<List<UserModel>> getUsers() async {
    final res = await _getWithFallback('/auth/users');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((u) => UserModel.fromJson(u)).toList();
    } else {
      throw Exception('Failed to load system users.');
    }
  }

  static Future<List<UserModel>> getCollectionAgents() async {
    try {
      final res = await _getWithFallback('/agents');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((u) => UserModel.fromJson(u)).toList();
      }
    } catch (_) {}

    // Fallback known collection agents list
    return [
      UserModel(id: 4, name: 'Rahul Verma', email: 'agent@bankflow.com', role: 'Collection Agent', employeeId: 'CAG-301', phone: '+91 98765 43210', area: 'Sector 12', route: 'Route A', address: 'BankFlow Sector 12 Field Branch, Hubli'),
      UserModel(id: 8, name: 'Suresh Patil', email: 'agent2@bankflow.com', role: 'Collection Agent', employeeId: 'CAG-302', phone: '+91 98765 43211', area: 'Station Road', route: 'Route B', address: 'Station Road Market Center, Hubli'),
      UserModel(id: 9, name: 'Amit Desai', email: 'agent3@bankflow.com', role: 'Collection Agent', employeeId: 'CAG-303', phone: '+91 98765 43212', area: 'Market Yard', route: 'Route C', address: 'Market Yard APMC Complex, Hubli'),
      UserModel(id: 10, name: 'Vijay Kulkarni', email: 'agent4@bankflow.com', role: 'Collection Agent', employeeId: 'CAG-304', phone: '+91 98765 43213', area: 'Gokul Road', route: 'Route D', address: 'Gokul Road Industrial Hub, Hubli'),
    ];
  }

  static Future<UserModel> getUserProfile(String email) async {
    final res = await _getWithFallback('/users/profile?email=' + Uri.encodeComponent(email.trim().toLowerCase()));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return UserModel.fromJson(data['user']);
    } else {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Failed to load user profile.');
    }
  }

  static Future<UserModel> updateUserProfile({
    required String email,
    String? name,
    String? phone,
    String? photoUrl,
    String? area,
    String? route,
    String? address,
  }) async {
    final res = await _putWithFallback('/users/profile', {
      'email': email.trim().toLowerCase(),
      if (name != null) 'name': name.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (photoUrl != null) 'photo_url': photoUrl.trim(),
      if (area != null) 'area': area.trim(),
      if (route != null) 'route': route.trim(),
      if (address != null) 'address': address.trim(),
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception(data['error'] ?? 'Failed to update profile.');
    }
  }

  static Future<String> updateUserPhoto({
    required String email,
    required String photoUrl,
  }) async {
    final res = await _putWithFallback('/users/photo', {
      'email': email.trim().toLowerCase(),
      'photo_url': photoUrl.trim(),
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['photoUrl'] ?? photoUrl;
    } else {
      throw Exception(data['error'] ?? 'Failed to update photo.');
    }
  }

  // ==========================================
  // 2. CUSTOMER MANAGEMENT
  // ==========================================

  static Future<List<CustomerModel>> getCustomers({
    String? area,
    String? route,
    String? search,
    String? kyc,
    String requesterRole = 'Collection Agent',
  }) async {
    final params = <String, String>{
      'requesterRole': requesterRole,
    };
    if (area != null && area.isNotEmpty && area != 'All Areas') params['area'] = area;
    if (route != null && route.isNotEmpty) params['route'] = route;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (kyc != null && kyc.isNotEmpty) params['kyc'] = kyc;

    try {
      final queryStr = Uri(queryParameters: params).query;
      final res = await _getWithFallback('/customers?$queryStr');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        await OfflineStorageService.saveCachedCustomers(data);
        return data.map((c) => CustomerModel.fromJson(c)).toList();
      }
    } catch (_) {}

    // Offline cached customers
    final cached = await OfflineStorageService.getCachedCustomers();
    if (cached.isNotEmpty) {
      return cached.map((c) => CustomerModel.fromJson(c)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getAgentPassbook(String email) async {
    try {
      final res = await _getWithFallback('/agent/passbook?email=${Uri.encodeComponent(email.trim().toLowerCase())}');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> getCustomerMyPassbook({String? email, String? phone, String? id}) async {
    try {
      final params = <String, String>{};
      if (email != null && email.isNotEmpty) params['email'] = email;
      if (phone != null && phone.isNotEmpty) params['phone'] = phone;
      if (id != null && id.isNotEmpty) params['id'] = id;
      final queryStr = Uri(queryParameters: params).query;
      final res = await _getWithFallback('/customer/my-passbook?$queryStr');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<CustomerModel> getCustomer(String id, {String role = 'Collection Agent'}) async {
    try {
      final res = await _getWithFallback('/customers/$id?requesterRole=${Uri.encodeComponent(role)}');
      if (res.statusCode == 200) {
        return CustomerModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}

    // Offline cache lookup
    final cached = await OfflineStorageService.getCachedCustomers();
    final found = cached.firstWhere((c) => c['id'] == id || c['id'] == 'CUST-$id', orElse: () => {});
    if (found.isNotEmpty) {
      return CustomerModel.fromJson(found);
    }

    return CustomerModel(
      id: id,
      name: 'Depositor',
      email: '',
      phone: '',
      area: 'Sector 12',
      route: 'Route A',
      openingBalance: 1000.0,
      kycStatus: 'Pending',
      aadharNumber: '',
      panNumber: '',
      address: '',
    );
  }

  static Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> custData) async {
    final name = (custData['name'] ?? 'Depositor').toString().trim();
    final phone = (custData['phone'] ?? '').toString().trim();
    final area = (custData['area'] ?? 'Sector 12').toString().trim();
    final route = (custData['route'] ?? 'Route A').toString().trim();
    final openBal = (custData['opening_balance'] as num?)?.toDouble() ?? 1000.0;
    final target = (custData['daily_target'] as num?)?.toDouble() ?? 100.0;

    try {
      final res = await _postWithFallback('/customers', custData);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        // Also update local cache
        final localRecord = {
          'id': data['customerId'],
          'name': name,
          'phone': phone,
          'area': area,
          'route': route,
          'opening_balance': openBal,
          'daily_target': target,
          'accounts': [
            {
              'account_number': data['accountNumber'] ?? 'PCMS-10001',
              'account_type': 'Savings Passbook',
              'balance': openBal,
              'daily_target': target,
              'interest_rate': 4.5,
            }
          ],
          'history': [
            {
              'id': DateTime.now().millisecondsSinceEpoch,
              'customer_id': data['customerId'],
              'amount': openBal,
              'date': DateTime.now().toIso8601String().split('T')[0],
              'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              'payment_mode': 'CASH',
              'receipt_id': 'RCP-${DateTime.now().millisecondsSinceEpoch % 10000}',
              'remarks': 'Opening Passbook Deposit',
            }
          ],
          'kyc_status': 'Pending',
        };
        final cached = await OfflineStorageService.getCachedCustomers();
        cached.insert(0, localRecord);
        await OfflineStorageService.saveCachedCustomers(cached);

        return data;
      }
    } catch (_) {}

    // Instant offline generation
    final newId = 'CUST-${(DateTime.now().millisecondsSinceEpoch % 900) + 100}';
    final accNumber = 'PCMS-${(DateTime.now().millisecondsSinceEpoch % 90000) + 10000}';

    final offlineRecord = {
      'id': newId,
      'name': name,
      'phone': phone,
      'area': area,
      'route': route,
      'opening_balance': openBal,
      'daily_target': target,
      'accounts': [
        {
          'account_number': accNumber,
          'account_type': 'Savings Passbook',
          'balance': openBal,
          'daily_target': target,
          'interest_rate': 4.5,
        }
      ],
      'history': [
        {
          'id': DateTime.now().millisecondsSinceEpoch,
          'customer_id': newId,
          'amount': openBal,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'payment_mode': 'CASH',
          'receipt_id': 'RCP-OFFLINE-${DateTime.now().millisecondsSinceEpoch % 10000}',
          'remarks': 'Opening Passbook Deposit',
        }
      ],
      'kyc_status': 'Pending',
      'is_new': 1,
    };

    await OfflineStorageService.queueOfflineCustomer(offlineRecord);

    return {
      'success': true,
      'customerId': newId,
      'accountNumber': accNumber,
      'dailyTarget': target,
      'isOffline': true,
    };
  }

  static Future<bool> updateCustomer(String id, Map<String, dynamic> custData) async {
    final res = await _putWithFallback('/customers/$id', custData);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['error'] ?? 'Failed to update customer.');
    }
  }

  static Future<bool> deleteCustomer(String id) async {
    final res = await _deleteWithFallback('/customers/$id');
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['success'] == true;
  }

  static Future<bool> clearAllCustomers() async {
    final res = await _deleteWithFallback('/customers/clear-all');
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['success'] == true;
  }

  static Future<bool> uploadCustomerPhoto(String id, String base64Image) async {
    final res = await _putWithFallback('/customers/$id/photo', {'photo_url': base64Image});
    return res.statusCode == 200;
  }

  // ==========================================
  // 3. FIELD COLLECTIONS & VISITS
  // ==========================================

  static Future<List<CollectionModel>> getTodayCollections(String agentEmail) async {
    final res = await _getWithFallback('/collections/today?email=${Uri.encodeComponent(agentEmail)}');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((item) => CollectionModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load collections schedule.');
    }
  }

  static Future<Map<String, dynamic>> recordCollection({
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
    final res = await _postWithFallback('/collections/record', {
      'customerId': customerId,
      'agentEmail': agentEmail,
      'status': status,
      'collectedAmount': collectedAmount,
      'depositTotal': depositTotal ?? collectedAmount,
      'lateFee': lateFee ?? 0,
      'interest': interest ?? 0,
      'paymentMode': paymentMode.toUpperCase(),
      'remarks': remarks,
      'latitude': latitude,
      'longitude': longitude,
      'photoCaptured': (photoCaptured || (photoUrl != null && photoUrl.isNotEmpty)) ? 1 : 0,
      'photo_url': photoUrl,
      'signatureCaptured': signatureCaptured ? 1 : 0,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to record collection.');
    }
  }

  static Future<Map<String, dynamic>> syncOfflineCollections(String email, List<Map<String, dynamic>> transactions) async {
    final res = await _postWithFallback('/collections/sync', {
      'email': email,
      'transactions': transactions,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to sync offline collections.');
    }
  }

  static Future<Map<String, dynamic>> getReceipt(String customerId) async {
    final res = await _getWithFallback('/collections/receipt/$customerId');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Receipt not found.');
    }
  }

  static Future<bool> clearCollectionHistory() async {
    final res = await _deleteWithFallback('/collections/history/clear-all');
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['success'] == true;
  }

  // ==========================================
  // 4. ROUTE OPTIMIZATION
  // ==========================================

  static Future<Map<String, dynamic>> getOptimizedRoutes(String agentEmail) async {
    final res = await _getWithFallback('/routes/optimize?email=${Uri.encodeComponent(agentEmail)}');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load optimized route.');
    }
  }

  // ==========================================
  // 5. VAULT EOD HANDOVER WORKFLOW
  // ==========================================

  static Future<VaultSubmissionModel> getVaultToday(String agentEmail) async {
    final res = await _getWithFallback('/vault/today?agentEmail=${Uri.encodeComponent(agentEmail)}');
    if (res.statusCode == 200) {
      return VaultSubmissionModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to load vault status.');
    }
  }

  static Future<Map<String, dynamic>> submitVaultCash({
    required String agentEmail,
    required double cashSubmitted,
    required double expectedCash,
    List<dynamic>? auditTrail,
  }) async {
    final res = await _postWithFallback('/vault/submit', {
      'agentEmail': agentEmail,
      'cashSubmitted': cashSubmitted,
      'expectedCash': expectedCash,
      'auditTrail': auditTrail ?? [],
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Vault submission failed.');
    }
  }

  static Future<Map<String, dynamic>> requestManagerOtp({
    required String agentEmail,
    required double difference,
  }) async {
    final res = await _postWithFallback('/vault/manager-otp/request', {
      'agentEmail': agentEmail,
      'difference': difference,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to request manager OTP.');
    }
  }

  static Future<bool> verifyManagerOtp({
    required String agentEmail,
    required String otpCode,
  }) async {
    final res = await _postWithFallback('/vault/manager-otp/verify', {
      'agentEmail': agentEmail,
      'otpCode': otpCode,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['error'] ?? 'Invalid manager approval code.');
    }
  }

  static Future<bool> cashierAcceptVault({
    required String agentEmail,
    String? signatureUrl,
  }) async {
    final res = await _postWithFallback('/vault/cashier-accept', {
      'agentEmail': agentEmail,
      'signatureUrl': signatureUrl ?? 'digital_signature_verified',
    });
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['success'] == true;
  }

  static Future<bool> bankDepositSlip({
    required String agentEmail,
    required String bankReference,
  }) async {
    final res = await _postWithFallback('/vault/bank-deposit', {
      'agentEmail': agentEmail,
      'bankReference': bankReference,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['error'] ?? 'Bank deposit entry failed.');
    }
  }

  // ==========================================
  // 6. ACCOUNTS, PASSBOOKS & MATURITY
  // ==========================================

  static Future<Map<String, dynamic>> getPassbooks() async {
    final res = await _getWithFallback('/accounts/passbooks');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load passbooks.');
    }
  }

  static Future<AccountModel> getAccountByNumber(String accountNumber) async {
    final res = await _getWithFallback('/accounts/by-number/$accountNumber');
    if (res.statusCode == 200) {
      return AccountModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Account not found.');
    }
  }

  static Future<Map<String, dynamic>> getInterestHistory(dynamic accountId) async {
    final res = await _getWithFallback('/accounts/$accountId/interest-history');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load interest history.');
    }
  }

  static Future<Map<String, dynamic>> accrueSingleInterest(
    dynamic accountId, {
    String? month,
    String performedBy = 'Branch Manager',
    String performedByRole = 'Branch Manager',
  }) async {
    final res = await _postWithFallback('/accounts/$accountId/accrue-interest', {
      'month': month,
      'performedBy': performedBy,
      'performedByRole': performedByRole,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Interest accrual failed.');
    }
  }

  static Future<Map<String, dynamic>> runBatchAccrual({
    String? month,
    String performedBy = 'Administrator',
    String performedByRole = 'Administrator',
  }) async {
    final res = await _postWithFallback('/accrual/run-monthly', {
      'month': month,
      'performedBy': performedBy,
      'performedByRole': performedByRole,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Batch monthly accrual failed.');
    }
  }

  static Future<List<AccountModel>> getMaturingSoon({int days = 30}) async {
    final res = await _getWithFallback('/accounts/maturing-soon?days=$days');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List accs = data['accounts'] ?? [];
      return accs.map((a) => AccountModel.fromJson(a)).toList();
    } else {
      throw Exception('Failed to load maturing accounts.');
    }
  }

  static Future<Map<String, dynamic>> processMaturity({
    String performedBy = 'System',
    String performedByRole = 'Administrator',
  }) async {
    final res = await _postWithFallback('/maturity/process', {
      'performedBy': performedBy,
      'performedByRole': performedByRole,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Maturity processing failed.');
    }
  }

  static Future<Map<String, dynamic>> closeAccount(
    dynamic accountId, {
    String performedBy = 'Cashier',
    String performedByRole = 'Cashier',
    String? performedByEmail,
  }) async {
    final res = await _postWithFallback('/accounts/$accountId/close', {
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'performedByEmail': performedByEmail,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Account closure failed.');
    }
  }

  static Future<Map<String, dynamic>> renewAccount(
    dynamic accountId, {
    String performedBy = 'Cashier',
    String performedByRole = 'Cashier',
    String? performedByEmail,
  }) async {
    final res = await _postWithFallback('/accounts/$accountId/renew', {
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'performedByEmail': performedByEmail,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Account renewal failed.');
    }
  }

  // ==========================================
  // 7. ANALYTICS & LIVE VISITS
  // ==========================================

  static Future<Map<String, dynamic>> getDashboardAnalytics({String? email, String? role}) async {
    final queryStr = Uri(queryParameters: {
      if (email != null) 'email': email,
      if (role != null) 'role': role,
    }).query;

    final res = await _getWithFallback('/analytics/dashboard?$queryStr');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load dashboard analytics.');
    }
  }

  static Future<List<Map<String, dynamic>>> getLiveVisits({String? agentEmail}) async {
    final queryStr = agentEmail != null ? '?agentEmail=${Uri.encodeComponent(agentEmail)}' : '';
    final res = await _getWithFallback('/visits/live$queryStr');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List list = data['visits'] ?? [];
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load live visits feed.');
    }
  }

  // ==========================================
  // 8. DAILY CASH RECONCILIATION
  // ==========================================

  static Future<Map<String, dynamic>> getDailyReconciliation({String? date, String? agentEmail, String? role}) async {
    final qs = Uri(queryParameters: {
      if (date != null) 'date': date,
      if (agentEmail != null) 'agent_email': agentEmail,
      'requested_role': role ?? 'Branch Manager',
    }).query;

    final res = await _getWithFallback('/reconciliation/daily?$qs');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load reconciliation.');
    }
  }

  static Future<List<ReconciliationRecordModel>> getPendingMismatches({String role = 'Branch Manager'}) async {
    final res = await _getWithFallback('/reconciliation/pending-mismatches?requested_role=${Uri.encodeComponent(role)}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List mismatches = data['mismatches'] ?? [];
      return mismatches.map((m) => ReconciliationRecordModel.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load pending mismatches.');
    }
  }

  static Future<bool> resolveReconciliation(
    int id,
    String resolvedBy,
    String role, {
    String note = '',
  }) async {
    final res = await _postWithFallback('/reconciliation/resolve/$id', {
      'resolved_by': resolvedBy,
      'resolved_by_role': role,
      'note': note,
    });
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['success'] == true;
  }

  // ==========================================
  // 9. AUDIT TRAIL & SYSTEM INSPECTION
  // ==========================================

  static Future<List<AuditLogModel>> getAuditLogs() async {
    final res = await _getWithFallback('/audit');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((l) => AuditLogModel.fromJson(l)).toList();
    } else {
      throw Exception('Failed to load audit logs.');
    }
  }

  static Future<bool> clearAuditLogs() async {
    final res = await _deleteWithFallback('/audit/clear-all');
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['success'] == true;
  }

  static Future<Map<String, dynamic>> getDbTables() async {
    final res = await _getWithFallback('/admin/db-tables');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load database tables.');
    }
  }

  static Future<Map<String, dynamic>> getHealth() async {
    final res = await _getWithFallback('/health');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('System health check failed.');
    }
  }

  // ==========================================
  // 10. PAYMENT GATEWAY INTEGRATION
  // ==========================================

  static Future<Map<String, dynamic>> getPaymentGatewayConfig() async {
    final res = await _getWithFallback('/payment-gateway/config');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load payment gateway config.');
    }
  }

  static Future<Map<String, dynamic>> createPaymentOrder({
    required double amount,
    required String customerId,
    required String customerName,
    required String accountNumber,
  }) async {
    final res = await _postWithFallback('/payment-gateway/create-order', {
      'amount': amount,
      'customerId': customerId,
      'customerName': customerName,
      'accountNumber': accountNumber,
    });
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to create payment order.');
    }
  }

  // ==========================================
  // 11. COLLECTION HISTORY MANAGEMENT
  // ==========================================

  static Future<bool> deleteHistoryItem(dynamic id) async {
    try {
      final res = await _deleteWithFallback('/collections/history/$id');
      final data = jsonDecode(res.body);
      return res.statusCode == 200 && data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> clearAllHistory() async {
    try {
      final res = await _deleteWithFallback('/collections/history/clear-all');
      final data = jsonDecode(res.body);
      return res.statusCode == 200 && data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteCollection(dynamic id) async {
    try {
      final res = await _deleteWithFallback('/collections/$id');
      final data = jsonDecode(res.body);
      return res.statusCode == 200 && data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
