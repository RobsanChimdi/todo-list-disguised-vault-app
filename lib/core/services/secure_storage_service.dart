// lib/core/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _pinKey = 'app_pin';
  static const String _isFirstLaunchKey = 'is_first_launch';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  Future<void> setFirstLaunch(bool value) async {
    await _storage.write(key: _isFirstLaunchKey, value: value.toString());
  }

  Future<bool> isFirstLaunch() async {
    final value = await _storage.read(key: _isFirstLaunchKey);
    return value != 'false';
  }

  Future<void> saveEncryptedData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getEncryptedData(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteEncryptedData(String key) async {
    await _storage.delete(key: key);
  }
}
