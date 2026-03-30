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

  // Constants
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    try {
      isLoading.value = true;

      // Check if PIN exists
      final pin = await _secureStorage.readSecureData('user_pin');
      hasPin.value = pin != null && pin.isNotEmpty;

      // Check if user is already logged in
      final userId = await _secureStorage.readSecureData('user_id');
      if (userId != null && hasPin.value) {
        await _loadUserData(userId);
        isAuthenticated.value = true;
      }

      // Check if app is locked
      final lockStatus = await _localStorage.readData('is_locked');
      isLocked.value = lockStatus == true;
    } catch (e) {
      debugPrint('Error checking auth state: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      // Load user data from local storage
      final userData = await _localStorage.readData('user_$userId');
      if (userData != null && userData is Map<String, dynamic>) {
        currentUser.value = User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Set initial PIN
  Future<bool> setPin(String pin, {String? userId}) async {
    try {
      isLoading.value = true;

      if (pin.length != 4 && pin.length != 6) {
        return false;
      }

      final user = User(
        id: userId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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

      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String enteredPin) async {
    try {
      isLoading.value = true;

      // Check if app is locked
      if (isLocked.value && lockoutUntil.value != null) {
        if (DateTime.now().isBefore(lockoutUntil.value!)) {
          return false;
        } else {
          // Lockout period expired
          await _resetFailedAttempts();
        }
      }

      final storedPin = await _secureStorage.readSecureData('user_pin');

      if (storedPin == enteredPin) {
        // Successful login
        await _resetFailedAttempts();
        isAuthenticated.value = true;
        isLocked.value = false;
        await _localStorage.writeData('is_locked', false);

        // Load user data if needed
        final userId = await _secureStorage.readSecureData('user_id');
        if (userId != null && currentUser.value == null) {
          await _loadUserData(userId);
        }

        return true;
      } else {
        // Failed attempt
        failedAttempts.value++;
        await _localStorage.writeData('failed_attempts', failedAttempts.value);

        // Check if max attempts reached
        if (failedAttempts.value >= maxFailedAttempts) {
          await _lockApp();
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

    // Trigger disguise if needed
    await _disguiseService.activateDisguise();
  }

  // Logout
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Clear authentication state
      isAuthenticated.value = false;
      currentUser.value = null;

      // Clear secure storage but keep PIN for next login
      await _secureStorage.deleteSecureData('user_id');

      // Clear sensitive data from local storage
      await _localStorage.deleteData('is_locked');
      await _localStorage.deleteData('failed_attempts');
      await _localStorage.deleteData('lockout_until');
    } catch (e) {
      debugPrint('Error logging out: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Change PIN (requires current PIN verification)
  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      isLoading.value = true;

      // Verify current PIN
      final isValid = await verifyPin(currentPin);
      if (!isValid) {
        return false;
      }

      if (newPin.length != 4 && newPin.length != 6) {
        return false;
      }

      // Update PIN
      await _secureStorage.writeSecureData('user_pin', newPin);

      // Update user data
      if (currentUser.value != null) {
        final updatedUser = currentUser.value!.copyWith(pin: newPin);
        await _localStorage.writeData(
          'user_${updatedUser.id}',
          updatedUser.toJson(),
        );
        currentUser.value = updatedUser;
      }

      return true;
    } catch (e) {
      debugPrint('Error changing PIN: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Check if initial setup is complete
  Future<bool> isInitialSetupComplete() async {
    try {
      final isComplete = await _localStorage.readData(
        'is_initial_setup_complete',
      );
      return isComplete == true;
    } catch (e) {
      return false;
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
    } catch (e) {
      debugPrint('Error resetting app: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
