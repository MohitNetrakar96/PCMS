import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class PaymentConfigService {
  static const String _keyUpiVpa = 'agent_payment_upi_vpa';
  static const String _keyUpiName = 'agent_payment_upi_name';
  static const String _keyQrImageBase64 = 'agent_payment_qr_image_base64';
  static const String _keyQrMode = 'agent_payment_qr_mode'; // 'IMAGE' or 'DYNAMIC'

  static final ImagePicker _picker = ImagePicker();

  /// Gets the agent's custom UPI VPA/ID (e.g., 9880011223@ybl, bankflow@upi)
  static Future<String> getUpiVpa() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUpiVpa) ?? 'bankflow@upi';
  }

  /// Gets the agent's payment receiver name
  static Future<String> getUpiName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUpiName) ?? 'BankFlow Pigmy Deposit';
  }

  /// Gets the agent's custom PhonePe / GPay QR image in base64 format
  static Future<String?> getCustomQrImageBase64() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyQrImageBase64);
  }

  /// Gets the preferred QR display mode ('IMAGE' or 'DYNAMIC')
  static Future<String> getQrMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyQrMode) ?? 'DYNAMIC';
  }

  /// Saves UPI configuration
  static Future<void> saveConfig({
    required String upiVpa,
    required String upiName,
    String? qrImageBase64,
    String? qrMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUpiVpa, upiVpa.trim());
    await prefs.setString(_keyUpiName, upiName.trim());
    if (qrImageBase64 != null) {
      if (qrImageBase64.isEmpty) {
        await prefs.remove(_keyQrImageBase64);
      } else {
        await prefs.setString(_keyQrImageBase64, qrImageBase64);
      }
    }
    if (qrMode != null) {
      await prefs.setString(_keyQrMode, qrMode);
    }
  }

  /// Picks a PhonePe/GPay QR code image from the gallery
  static Future<String?> pickQrImageFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await File(photo.path).readAsBytes();
        final base64String = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyQrImageBase64, base64String);
        await prefs.setString(_keyQrMode, 'IMAGE');
        return base64String;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Takes a photo of a physical PhonePe/GPay QR standee with camera
  static Future<String?> captureQrImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await File(photo.path).readAsBytes();
        final base64String = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyQrImageBase64, base64String);
        await prefs.setString(_keyQrMode, 'IMAGE');
        return base64String;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Removes custom QR image
  static Future<void> removeCustomQrImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyQrImageBase64);
    await prefs.setString(_keyQrMode, 'DYNAMIC');
  }
}
