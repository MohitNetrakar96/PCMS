import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  String get role => _user?.role ?? 'Collection Agent';
  String get email => _user?.email ?? '';
  String get name => _user?.name ?? 'User';
  String? get photoUrl => _user?.photoUrl;
  String? get phone => _user?.phone;
  String? get employeeId => _user?.employeeId;
  String? get area => _user?.area;
  String? get route => _user?.route;
  String? get address => _user?.address;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final name = prefs.getString('user_name');
    final role = prefs.getString('user_role');
    final token = prefs.getString('user_token');
    final employeeId = prefs.getString('user_employee_id');
    final phone = prefs.getString('user_phone');
    final photoUrl = prefs.getString('user_photo_url');
    final area = prefs.getString('user_area');
    final route = prefs.getString('user_route');
    final address = prefs.getString('user_address');

    if (email != null && role != null) {
      _user = UserModel(
        id: prefs.getInt('user_id') ?? 1,
        name: name ?? email.split('@')[0],
        email: email,
        role: role,
        employeeId: employeeId,
        phone: phone,
        photoUrl: photoUrl,
        area: area,
        route: route,
        address: address,
        token: token,
      );
      notifyListeners();

      // Silent sync with backend
      fetchProfile();
    }
  }

  Future<void> _saveToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    if (user.token != null) await prefs.setString('user_token', user.token!);
    if (user.employeeId != null) await prefs.setString('user_employee_id', user.employeeId!);
    if (user.phone != null) await prefs.setString('user_phone', user.phone!);
    if (user.photoUrl != null) await prefs.setString('user_photo_url', user.photoUrl!);
    if (user.area != null) await prefs.setString('user_area', user.area!);
    if (user.route != null) await prefs.setString('user_route', user.route!);
    if (user.address != null) await prefs.setString('user_address', user.address!);
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    await _saveToPrefs(user);
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (_user == null || _user!.email.isEmpty) return;
    try {
      final updated = await ApiService.getUserProfile(_user!.email);
      _user = _user!.copyWith(
        name: updated.name,
        phone: updated.phone,
        photoUrl: updated.photoUrl,
        area: updated.area,
        route: updated.route,
        address: updated.address,
        employeeId: updated.employeeId ?? _user!.employeeId,
      );
      await _saveToPrefs(_user!);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
    String? area,
    String? route,
    String? address,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await ApiService.updateUserProfile(
        email: _user!.email,
        name: name,
        phone: phone,
        photoUrl: photoUrl,
        area: area,
        route: route,
        address: address,
      );

      _user = _user!.copyWith(
        name: updated.name,
        phone: updated.phone,
        photoUrl: updated.photoUrl,
        area: updated.area,
        route: updated.route,
        address: updated.address,
        employeeId: updated.employeeId ?? _user!.employeeId,
      );

      await _saveToPrefs(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePhoto(String photoUrl) async {
    if (_user == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUrl = await ApiService.updateUserPhoto(email: _user!.email, photoUrl: photoUrl);
      _user = _user!.copyWith(photoUrl: newUrl);
      await _saveToPrefs(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password, {String? role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await ApiService.asyncLogin(email, password, expectedRole: role);
      _user = user;
      await _saveToPrefs(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
