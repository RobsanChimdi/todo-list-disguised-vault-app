// lib/features/disguise/services/disguise_service.dart

import '../../../core/services/local_storage_service.dart';
import '../../../core/services/secure_storage_service.dart';

class DisguiseService {
  static const String _disguiseModeKey = 'disguise_mode_enabled';

  final LocalStorageService _localStorage = LocalStorageService();
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Check if disguise mode is enabled
  Future<bool> isDisguiseMode() async {
    try {
      final value = await _localStorage.getSetting(_disguiseModeKey);
      return value == true;
    } catch (e) {
      // Default to true for first launch
      return true;
    }
  }

  /// Enable disguise mode
  Future<void> enableDisguiseMode() async {
    await _localStorage.saveSetting(_disguiseModeKey, true);
  }

  /// Disable disguise mode (not recommended for production)
  Future<void> disableDisguiseMode() async {
    await _localStorage.saveSetting(_disguiseModeKey, false);
  }

  /// Check if this is first launch (for onboarding)
  Future<bool> isFirstLaunch() async {
    return await _secureStorage.isFirstLaunch();
  }

  /// Mark first launch as completed
  Future<void> setFirstLaunchCompleted() async {
    await _secureStorage.setFirstLaunch(false);
  }
}
