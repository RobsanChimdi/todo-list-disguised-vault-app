// lib/features/auth/presentation/controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/biometric_service.dart'; // You'll need to create this
import '../../../../core/services/email_service.dart'; // You'll need to create this
import '../../../../core/services/user_repository.dart'; // You'll need to create this

class AuthController extends GetxController {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalStorageService _localStorage = Get.find<LocalStorageService>();

  // Add these services
  final BiometricService _biometricService = BiometricService();
  final EmailService _emailService = EmailService();
  final UserRepository _userRepository = UserRepository();

  var isAuthenticated = false.obs;
  var hasPin = false.obs;
  var pin = ''.obs;
  var isLoading = false.obs;
  var isLocked = false.obs;
  var failedAttempts = 0.obs;
  var lockoutUntil = Rx<DateTime?>(null);

  // Add this for biometric authentication state
  var isBiometricsEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkPinExists();
    checkBiometricsStatus();
  }

  Future<void> checkPinExists() async {
    final savedPin = await _secureStorage.read(key: 'user_pin');
    hasPin.value = savedPin != null && savedPin.isNotEmpty;
    if (hasPin.value) {
      pin.value = savedPin!;
    }
  }

  Future<void> checkBiometricsStatus() async {
    final enabled = await _secureStorage.read(key: 'biometrics_enabled');
    isBiometricsEnabled.value = enabled == 'true';
  }

  Future<bool> verifyPin(String enteredPin) async {
    // Check if locked out
    if (isLocked.value && lockoutUntil.value != null) {
      if (DateTime.now().isBefore(lockoutUntil.value!)) {
        // Calculate remaining lockout time
        final remaining = lockoutUntil.value!.difference(DateTime.now());
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        Get.snackbar(
          'Account Locked',
          'Too many failed attempts. Please try again in ${minutes}m ${seconds}s',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      } else {
        // Lockout expired
        isLocked.value = false;
        failedAttempts.value = 0;
        lockoutUntil.value = null;
      }
    }

    final savedPin = await _secureStorage.read(key: 'user_pin');
    if (savedPin == enteredPin) {
      // Successful login
      isAuthenticated.value = true;
      failedAttempts.value = 0;
      isLocked.value = false;
      lockoutUntil.value = null;
      return true;
    } else {
      // Failed login
      failedAttempts.value++;

      if (failedAttempts.value >= 5) {
        // Lock for 5 minutes
        isLocked.value = true;
        lockoutUntil.value = DateTime.now().add(const Duration(minutes: 5));
        Get.snackbar(
          'Account Locked',
          'Too many failed attempts. Locked for 5 minutes.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        final remainingAttempts = 5 - failedAttempts.value;
        Get.snackbar(
          'Invalid PIN',
          '${remainingAttempts} attempt${remainingAttempts != 1 ? 's' : ''} remaining',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }

      return false;
    }
  }

  Future<bool> setPin(String newPin) async {
    try {
      isLoading.value = true;
      await _secureStorage.write(key: 'user_pin', value: newPin);
      pin.value = newPin;
      hasPin.value = true;
      isAuthenticated.value = true;
      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      return false;
    }
  }

  // Add this method to enable/disable biometrics
  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      if (enabled) {
        // Check if biometrics is available
        final isAvailable = await _biometricService.isAvailable();
        if (!isAvailable) {
          Get.snackbar(
            'Not Available',
            'Biometric authentication is not available on this device',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // Test authentication first
        final authenticated = await _biometricService.authenticate();
        if (!authenticated) {
          Get.snackbar(
            'Failed',
            'Biometric authentication failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      await _secureStorage.write(
        key: 'biometrics_enabled',
        value: enabled.toString(),
      );
      isBiometricsEnabled.value = enabled;

      Get.snackbar(
        'Success',
        enabled ? 'Biometrics enabled' : 'Biometrics disabled',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error setting biometrics: $e');
      Get.snackbar(
        'Error',
        'Failed to ${enabled ? 'enable' : 'disable'} biometrics',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Add biometric authentication method
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!isBiometricsEnabled.value) {
        return false;
      }

      isLoading.value = true;
      final authenticated = await _biometricService.authenticate();
      isLoading.value = false;

      if (authenticated) {
        isAuthenticated.value = true;
        failedAttempts.value = 0;
        isLocked.value = false;
        lockoutUntil.value = null;
        return true;
      }
    } catch (e) {
      isLoading.value = false;
      print('Biometric error: $e');
      Get.snackbar(
        'Error',
        'Biometric authentication failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return false;
  }

  // Add PIN reset via email
  Future<bool> sendPinResetEmail(String email) async {
    try {
      isLoading.value = true;

      // Check if email exists in your system
      // You'll need to implement user storage
      final user = await _userRepository.findByEmail(email);
      if (user != null) {
        // Generate reset token
        final token = _generateResetToken();

        // Save token with expiry (1 hour)
        await _secureStorage.write(key: 'reset_token_$email', value: token);
        await _secureStorage.write(
          key: 'reset_token_expiry_$email',
          value: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        );

        // Send email
        await _emailService.sendPinResetEmail(email, token);

        isLoading.value = false;
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      isLoading.value = false;
      print('Send reset email error: $e');
      return false;
    }
  }

  // Add method to verify reset token and set new PIN
  Future<bool> resetPinWithToken(
    String email,
    String token,
    String newPin,
  ) async {
    try {
      isLoading.value = true;

      // Verify token
      final savedToken = await _secureStorage.read(key: 'reset_token_$email');
      final expiryString = await _secureStorage.read(
        key: 'reset_token_expiry_$email',
      );

      if (savedToken == null || expiryString == null) {
        isLoading.value = false;
        return false;
      }

      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry)) {
        isLoading.value = false;
        return false; // Token expired
      }

      if (savedToken != token) {
        isLoading.value = false;
        return false; // Invalid token
      }

      // Set new PIN
      await setPin(newPin);

      // Clear reset token
      await _secureStorage.delete(key: 'reset_token_$email');
      await _secureStorage.delete(key: 'reset_token_expiry_$email');

      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      print('Reset PIN error: $e');
      return false;
    }
  }

  String _generateResetToken() {
    // Generate a random 6-digit code or UUID
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(random.length - 6);
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Clear authentication state
      isAuthenticated.value = false;
      pin.value = '';
      failedAttempts.value = 0;
      isLocked.value = false;
      lockoutUntil.value = null;

      // Close all open boxes
      await _localStorage.closeAllBoxes();

      isLoading.value = false;

      // Navigate to lock screen
      Get.offAllNamed(
        '/login',
      ); // Changed to login screen instead of lock screen

      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      isLoading.value = false;
      print('Logout error: $e');
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> clearAllData() async {
    try {
      isLoading.value = true;

      // Clear secure storage
      await _secureStorage.delete(key: 'user_pin');
      await _secureStorage.delete(key: 'biometrics_enabled');

      // Clear all reset tokens
      final allKeys = await _secureStorage.readAll();
      for (var key in allKeys.keys) {
        if (key.startsWith('reset_token_')) {
          await _secureStorage.delete(key: key);
        }
      }

      // Clear all local storage boxes
      await _localStorage.resetAllStorage();

      // Reset state
      isAuthenticated.value = false;
      hasPin.value = false;
      pin.value = '';
      failedAttempts.value = 0;
      isLocked.value = false;
      lockoutUntil.value = null;
      isBiometricsEnabled.value = false;

      isLoading.value = false;
      Get.offAllNamed('/set-pin');
    } catch (e) {
      isLoading.value = false;
      print('Error clearing data: $e');
      rethrow;
    }
  }
}
