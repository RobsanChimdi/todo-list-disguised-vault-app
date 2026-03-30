// lib/features/auth/presentation/controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/user.dart';
import '../../../disguise/services/disguise_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final SecureStorageService _secureStorage = SecureStorageService();
  final LocalStorageService _localStorage = LocalStorageService();
  final DisguiseService _disguiseService = DisguiseService();

  // Observables
  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool hasPin = false.obs;
  final RxInt failedAttempts = 0.obs;
  final RxBool isLocked = false.obs;
  final Rx<DateTime?> lockoutUntil = Rx<DateTime?>(null);
  final RxBool showVaultAccess =
      false.obs; // Track if vault access is requested

  // Constants
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    try {
      final pin = await _secureStorage.readSecureData('user_pin');
      hasPin.value = pin != null && pin.isNotEmpty;

      if (hasPin.value) {
        final userId = await _secureStorage.readSecureData('user_id');
        if (userId != null) {
          await _loadUserData(userId);
        }
      }
    } catch (e) {
      debugPrint('Error checking PIN: $e');
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _localStorage.readData('user_$userId');
      if (userData != null && userData is Map<String, dynamic>) {
        currentUser.value = User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Trigger vault access (called after secret gesture)
  Future<void> requestVaultAccess() async {
    if (!hasPin.value) {
      // First time setup - show PIN creation
      showVaultAccess.value = true;
      Get.toNamed('/set-pin');
    } else {
      // Show PIN entry screen
      showVaultAccess.value = true;
      Get.toNamed('/lock-screen');
    }
  }

  // Set initial PIN
  Future<bool> setPin(String pin) async {
    try {
      isLoading.value = true;

      if (pin.length != 4 && pin.length != 6) {
        return false;
      }

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pin: pin,
        createdAt: DateTime.now(),
      );

      // Store PIN securely
      await _secureStorage.writeSecureData('user_pin', pin);
      await _secureStorage.writeSecureData('user_id', user.id);

      // Store user data
      await _localStorage.writeData('user_${user.id}', user.toJson());

      // Store initial setup flag
      await _localStorage.writeData('is_initial_setup_complete', true);

      currentUser.value = user;
      hasPin.value = true;
      isAuthenticated.value = true;

      // Reset failed attempts
      await _resetFailedAttempts();

      // Close PIN setup screen and open vault
      Get.back();
      _openVaultAfterAuth();

      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Verify PIN for vault access
  Future<bool> verifyPinForVault(String enteredPin) async {
    try {
      isLoading.value = true;

      // Check if app is locked
      if (isLocked.value && lockoutUntil.value != null) {
        if (DateTime.now().isBefore(lockoutUntil.value!)) {
          Get.snackbar(
            'Locked',
            'Too many failed attempts. Try again in ${_getRemainingLockoutTime()}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        } else {
          await _resetFailedAttempts();
        }
      }

      final storedPin = await _secureStorage.readSecureData('user_pin');

      if (storedPin == enteredPin) {
        // Successful authentication
        await _resetFailedAttempts();
        isAuthenticated.value = true;

        // Update last login
        if (currentUser.value != null) {
          final updatedUser = currentUser.value!.copyWith(
            lastLoginAt: DateTime.now(),
          );
          await _localStorage.writeData(
            'user_${updatedUser.id}',
            updatedUser.toJson(),
          );
          currentUser.value = updatedUser;
        }

        // Close lock screen and open vault
        Get.back();
        _openVaultAfterAuth();

        return true;
      } else {
        // Failed attempt
        failedAttempts.value++;
        await _localStorage.writeData('failed_attempts', failedAttempts.value);

        // Check if max attempts reached
        if (failedAttempts.value >= maxFailedAttempts) {
          await _lockApp();
          Get.back(); // Close PIN screen
          Get.snackbar(
            'App Locked',
            'Too many failed attempts. Please try again later.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'Invalid PIN',
            '${maxFailedAttempts - failedAttempts.value} attempts remaining',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String _getRemainingLockoutTime() {
    if (lockoutUntil.value == null) return '5 minutes';
    final remaining = lockoutUntil.value!.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes minutes $seconds seconds';
  }

  Future<void> _resetFailedAttempts() async {
    failedAttempts.value = 0;
    isLocked.value = false;
    lockoutUntil.value = null;
    await _localStorage.writeData('failed_attempts', 0);
    await _localStorage.writeData('is_locked', false);
    await _localStorage.deleteData('lockout_until');
  }

  Future<void> _lockApp() async {
    isLocked.value = true;
    lockoutUntil.value = DateTime.now().add(lockoutDuration);
    await _localStorage.writeData('is_locked', true);
    await _localStorage.writeData(
      'lockout_until',
      lockoutUntil.value!.toIso8601String(),
    );

    // Trigger disguise - make app look more like a regular notes app
    await _disguiseService.activateDisguise();
  }

  void _openVaultAfterAuth() {
    // Reset the vault access flag
    showVaultAccess.value = false;

    // Navigate to vault home
    Get.toNamed('/vault');
  }

  // Logout from vault (return to notebook)
  Future<void> logoutFromVault() async {
    try {
      isLoading.value = true;

      // Clear authentication state but keep PIN
      isAuthenticated.value = false;

      // Navigate back to notebook
      Get.until((route) => route.settings.name == '/notebook');
    } catch (e) {
      debugPrint('Error logging out: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Reset app (clear all data)
  Future<void> resetApp() async {
    try {
      isLoading.value = true;

      // Clear all secure storage
      await _secureStorage.deleteSecureData('user_pin');
      await _secureStorage.deleteSecureData('user_id');

      // Clear all local storage
      await _localStorage.clearAll();

      // Reset state
      isAuthenticated.value = false;
      currentUser.value = null;
      hasPin.value = false;
      failedAttempts.value = 0;
      isLocked.value = false;
      lockoutUntil.value = null;
      showVaultAccess.value = false;
    } catch (e) {
      debugPrint('Error resetting app: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
