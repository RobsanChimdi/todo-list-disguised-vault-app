// lib/core/services/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _pinKey = 'app_pin';
  static const String _userIdKey = 'user_id';
  static const String _isFirstLaunchKey = 'is_first_launch';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ================= GENERIC METHODS (for AuthController) =================

  /// Generic write method
  Future<void> writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Generic read method
  Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  /// Generic delete method
  Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all secure data
  Future<void> clearAllSecureData() async {
    await _storage.deleteAll();
  }

  // ================= PIN SPECIFIC METHODS =================

  /// Save user PIN
  Future<void> savePin(String pin) async {
    await writeSecureData(_pinKey, pin);
  }

  /// Get user PIN
  Future<String?> getPin() async {
    return await readSecureData(_pinKey);
  }

  /// Check if PIN exists
  Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  /// Clear PIN
  Future<void> clearPin() async {
    await deleteSecureData(_pinKey);
    await deleteSecureData(_userIdKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await writeSecureData(_userIdKey, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await readSecureData(_userIdKey);
  }

  // ================= FIRST LAUNCH =================

  /// Set first launch flag
  Future<void> setFirstLaunch(bool value) async {
    await writeSecureData(_isFirstLaunchKey, value.toString());
  }

  /// Check if first launch
  Future<bool> isFirstLaunch() async {
    final value = await readSecureData(_isFirstLaunchKey);
    return value != 'false';
  }

  // ================= ENCRYPTED DATA =================

  /// Save encrypted data
  Future<void> saveEncryptedData(String key, String value) async {
    await writeSecureData(key, value);
  }

  /// Get encrypted data
  Future<String?> getEncryptedData(String key) async {
    return await readSecureData(key);
  }

  /// Delete encrypted data
  Future<void> deleteEncryptedData(String key) async {
    await deleteSecureData(key);
  }
}
