import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ── Roles ─────────────────────────────────────────────────────
enum UserRole { admin, branchManager, cashier, collectionAgent, auditor }

extension RoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:           return 'Administrator';
      case UserRole.branchManager:   return 'Branch Manager';
      case UserRole.cashier:         return 'Cashier';
      case UserRole.collectionAgent: return 'Collection Agent';
      case UserRole.auditor:         return 'Auditor';
    }
  }
}

class UserData {
  final String username;
  final String password;
  final String name;
  final UserRole role;
  final String? employeeId;
  final String? email;

  const UserData({
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.employeeId,
    this.email,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'name': name,
    'role': role.index,
    'employeeId': employeeId,
    'email': email,
  };

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    username: json['username'] as String,
    password: json['password'] as String,
    name: json['name'] as String,
    role: UserRole.values[json['role'] as int],
    employeeId: json['employeeId'] as String?,
    email: json['email'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────
// AuthService - Singleton (API Integration)
// ─────────────────────────────────────────────────────────────
class AuthService {
  AuthService._privateConstructor();

  static final AuthService instance = AuthService._privateConstructor();

  static const String _baseUrl = 'http://localhost:3000/api/auth';

  late SharedPreferences _prefs;
  bool _initialized = false;

  // In-memory cache loaded from SharedPreferences (for offline authentication)
  final Map<String, UserData> _offlineUsersCache = {};

  UserData? _currentUser;
  UserData? get currentUser => _currentUser;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Load offline cached accounts
    final cachedJson = _prefs.getString('offline_users_cache');
    if (cachedJson != null) {
      try {
        final decoded = json.decode(cachedJson) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          _offlineUsersCache[key] = UserData.fromJson(val as Map<String, dynamic>);
        });
      } catch (e) {
        debugPrint('Error loading cached offline users: $e');
      }
    }

    _initialized = true;
  }

  Future<void> _saveOfflineCache() async {
    final encoded = _offlineUsersCache.map((key, value) => MapEntry(key, value.toJson()));
    await _prefs.setString('offline_users_cache', json.encode(encoded));
  }

  /// Register a new user account.
  /// Hits backend endpoint: POST /api/auth/register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? employeeId,
  }) async {
    await init();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'role': role.name,
          'employeeId': employeeId,
        }),
      );

      if (response.statusCode == 200) {
        // Cache account details locally to support subsequent offline logins
        _offlineUsersCache[email] = UserData(
          username: email,
          password: password,
          name: name,
          role: role,
          employeeId: employeeId,
          email: email,
        );
        await _saveOfflineCache();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Registration network error: $e');
      return false;
    }
  }

  /// Authenticate user credentials.
  /// Hits backend endpoint: POST /api/auth/login OR POST /api/auth/verify-otp
  Future<UserData?> login({
    required String email,
    required String password,
    required UserRole expectedRole,
    required bool isOffline,
  }) async {
    await init();

    if (isOffline) {
      // Offline mode check
      final cachedUser = _offlineUsersCache[email];
      if (cachedUser != null && cachedUser.password == password && cachedUser.role == expectedRole) {
        _currentUser = cachedUser;
        return cachedUser;
      }
      return null;
    }

    // Online authentication
    try {
      final url = password.length == 6 // Password of length 6 represents mock verification OTP code
          ? '$_baseUrl/verify-otp'
          : '$_baseUrl/login';

      final body = password.length == 6
          ? {
              'phone': email,
              'code': password,
              'expectedRole': expectedRole.name,
            }
          : {
              'email': email,
              'password': password,
              'expectedRole': expectedRole.name,
            };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final userMap = data['user'] as Map<String, dynamic>;
        
        final user = UserData(
          username: userMap['email'] as String,
          password: password.length == 6 ? 'pass@123' : password,
          name: userMap['name'] as String,
          role: expectedRole,
          employeeId: userMap['employeeId'] as String?,
          email: userMap['email'] as String,
        );

        // Store user in local offline cache
        _offlineUsersCache[email] = user;
        await _saveOfflineCache();

        _currentUser = user;
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Authentication network error: $e');
      return null;
    }
  }

  /// Reset user password using verified OTP and authenticate session.
  /// Hits backend endpoint: POST /api/auth/reset-password-otp
  Future<UserData?> resetPasswordWithOtp({
    required String username,
    required String code,
    required String newPassword,
    required UserRole expectedRole,
  }) async {
    await init();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': username,
          'code': code,
          'password': newPassword,
          'expectedRole': expectedRole.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final userMap = data['user'] as Map<String, dynamic>;
        
        final user = UserData(
          username: userMap['email'] as String,
          password: newPassword, // Cache updated password locally for offline support
          name: userMap['name'] as String,
          role: expectedRole,
          employeeId: userMap['employeeId'] as String?,
          email: userMap['email'] as String,
        );

        // Store user in local offline cache
        _offlineUsersCache[user.username] = user;
        await _saveOfflineCache();

        _currentUser = user;
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Reset password via OTP network error: $e');
      return null;
    }
  }

  /// Requests the backend to generate and dispatch an OTP
  /// Hits backend endpoint: POST /api/auth/send-otp
  Future<String?> sendOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['otp'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error requesting OTP: $e');
      return null;
    }
  }

  /// Checks if the device is registered online/offline.
  /// Hits backend endpoint: POST /api/auth/check-device
  Future<bool> isDeviceRegisteredApi(String username) async {
    await init();
    
    // Check locally first as fallback
    final local = _prefs.getBool('device_registered_$username') ?? false;
    if (local) return true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'deviceId': 'chrome-windows-web',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final isRegistered = data['isRegistered'] as bool;
        if (isRegistered) {
          await _prefs.setBool('device_registered_$username', true);
        }
        return isRegistered;
      }
      return false;
    } catch (_) {
      return local;
    }
  }

  /// Helper indicating if device status is cached locally.
  bool isDeviceRegistered(String username) {
    return _prefs.getBool('device_registered_$username') ?? false;
  }

  /// Registers the device for the given user both locally and online.
  /// Hits backend endpoint: POST /api/auth/register-device
  Future<void> registerDevice(String username) async {
    await init();
    await _prefs.setBool('device_registered_$username', true);

    try {
      await http.post(
        Uri.parse('$_baseUrl/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'deviceId': 'chrome-windows-web',
        }),
      );
    } catch (e) {
      debugPrint('Device binding network warning: $e');
    }
  }

  /// Logout current session.
  void logout() {
    _currentUser = null;
  }
}
