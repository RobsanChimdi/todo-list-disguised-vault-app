// lib/features/auth/presentation/controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/user.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final SecureStorageService _secureStorage = SecureStorageService();

  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool hasPin = false.obs;
  final RxInt failedAttempts = 0.obs;
  final RxBool isLocked = false.obs;
  final Rx<DateTime?> lockoutUntil = Rx<DateTime?>(null);

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
    currentUser.value = User(id: userId, pin: '', createdAt: DateTime.now());
  }

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

      await _secureStorage.writeSecureData('user_pin', pin);
      await _secureStorage.writeSecureData('user_id', user.id);

      currentUser.value = user;
      hasPin.value = true;
      isAuthenticated.value = true;
      await _resetFailedAttempts();

      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyPin(String enteredPin) async {
    try {
      isLoading.value = true;

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
        await _resetFailedAttempts();
        isAuthenticated.value = true;

        if (currentUser.value != null) {
          final updatedUser = currentUser.value!.copyWith(
            lastLoginAt: DateTime.now(),
          );
          currentUser.value = updatedUser;
        }

        return true;
      } else {
        failedAttempts.value++;

        if (failedAttempts.value >= maxFailedAttempts) {
          await _lockApp();
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
  }

  Future<void> _lockApp() async {
    isLocked.value = true;
    lockoutUntil.value = DateTime.now().add(lockoutDuration);
  }

  // Logout from vault - called when user wants to exit vault
  void logoutFromVault() {
    isAuthenticated.value = false;
    // Navigate back to notebook
    Get.until((route) => route.settings.name == '/notebook');
  }

  Future<void> resetApp() async {
    try {
      isLoading.value = true;

      await _secureStorage.deleteSecureData('user_pin');
      await _secureStorage.deleteSecureData('user_id');

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
    super.onClose();
  }
}
