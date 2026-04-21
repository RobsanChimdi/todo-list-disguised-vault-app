// lib/features/auth/presentation/controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/services/user_repository.dart';

class AuthController extends GetxController {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalStorageService _localStorage = Get.find<LocalStorageService>();

  // Services
  final BiometricService _biometricService = BiometricService();
  final EmailService _emailService = EmailService();
  final UserRepository _userRepository = UserRepository();

  // Authentication state
  var isAuthenticated = false.obs;
  var hasPin = false.obs;
  var pin = ''.obs;
  var isLoading = false.obs;
  var isLocked = false.obs;
  var failedAttempts = 0.obs;
  var lockoutUntil = Rx<DateTime?>(null);

  // Biometric state
  var isBiometricsEnabled = false.obs;

  // Email verification state
  var emailVerificationCodes = <String, Map<String, dynamic>>{}.obs;
  var isEmailVerified = false.obs;
  var verifiedEmail = ''.obs;

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

  // Email Verification Methods
  Future<bool> sendEmailVerificationCode(String email) async {
    try {
      isLoading.value = true;

      // Check if email is valid
      if (!_isValidEmailFormat(email)) {
        isLoading.value = false;
        return false;
      }

      // Generate a random 6-digit code
      final Random random = Random();
      final String code = (100000 + random.nextInt(900000)).toString();

      // Store code with expiry (5 minutes)
      await _secureStorage.write(
        key: 'email_verification_${_sanitizeEmailKey(email)}',
        value: code,
      );
      await _secureStorage.write(
        key: 'email_verification_expiry_${_sanitizeEmailKey(email)}',
        value: DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      );

      // Store attempt count for rate limiting
      final attemptsKey = 'verification_attempts_${_sanitizeEmailKey(email)}';
      final attempts = await _secureStorage.read(key: attemptsKey);
      int attemptCount = attempts != null ? int.parse(attempts) : 0;

      if (attemptCount >= 3) {
        final lastAttempt = await _secureStorage.read(
          key: 'last_verification_attempt_${_sanitizeEmailKey(email)}',
        );
        if (lastAttempt != null) {
          final lastAttemptTime = DateTime.parse(lastAttempt);
          if (DateTime.now().difference(lastAttemptTime).inMinutes < 15) {
            isLoading.value = false;
            Get.snackbar(
              'Rate Limited',
              'Too many verification attempts. Please try again later.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return false;
          }
        }
      }

      // Update attempt tracking
      await _secureStorage.write(
        key: attemptsKey,
        value: (attemptCount + 1).toString(),
      );
      await _secureStorage.write(
        key: 'last_verification_attempt_${_sanitizeEmailKey(email)}',
        value: DateTime.now().toIso8601String(),
      );

      // Send email with verification code
      final emailSent = await _emailService.sendVerificationCode(email, code);

      isLoading.value = false;
      return emailSent;
    } catch (e) {
      isLoading.value = false;
      print('Send verification code error: $e');
      return false;
    }
  }

  Future<bool> verifyEmailCode(String email, String code) async {
    try {
      isLoading.value = true;

      // Get stored verification code
      final storedCode = await _secureStorage.read(
        key: 'email_verification_${_sanitizeEmailKey(email)}',
      );
      final expiryString = await _secureStorage.read(
        key: 'email_verification_expiry_${_sanitizeEmailKey(email)}',
      );

      if (storedCode == null || expiryString == null) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'No verification code found. Please request a new code.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Check if code has expired
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry)) {
        // Clean up expired code
        await _secureStorage.delete(
          key: 'email_verification_${_sanitizeEmailKey(email)}',
        );
        await _secureStorage.delete(
          key: 'email_verification_expiry_${_sanitizeEmailKey(email)}',
        );
        isLoading.value = false;
        Get.snackbar(
          'Code Expired',
          'The verification code has expired. Please request a new one.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Verify code
      if (storedCode != code) {
        // Track failed verification attempts
        final failedAttemptsKey =
            'failed_verification_${_sanitizeEmailKey(email)}';
        final failedAttempts = await _secureStorage.read(
          key: failedAttemptsKey,
        );
        int failedCount = failedAttempts != null
            ? int.parse(failedAttempts)
            : 0;
        failedCount++;

        await _secureStorage.write(
          key: failedAttemptsKey,
          value: failedCount.toString(),
        );

        if (failedCount >= 3) {
          // Clear verification code after too many failed attempts
          await _secureStorage.delete(
            key: 'email_verification_${_sanitizeEmailKey(email)}',
          );
          await _secureStorage.delete(
            key: 'email_verification_expiry_${_sanitizeEmailKey(email)}',
          );
          isLoading.value = false;
          Get.snackbar(
            'Too Many Attempts',
            'Too many failed verification attempts. Please request a new code.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }

        isLoading.value = false;
        Get.snackbar(
          'Invalid Code',
          'The verification code is incorrect. ${3 - failedCount} attempts remaining.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Clean up verification code after successful verification
      await _secureStorage.delete(
        key: 'email_verification_${_sanitizeEmailKey(email)}',
      );
      await _secureStorage.delete(
        key: 'email_verification_expiry_${_sanitizeEmailKey(email)}',
      );
      await _secureStorage.delete(
        key: 'verification_attempts_${_sanitizeEmailKey(email)}',
      );
      await _secureStorage.delete(
        key: 'failed_verification_${_sanitizeEmailKey(email)}',
      );
      await _secureStorage.delete(
        key: 'last_verification_attempt_${_sanitizeEmailKey(email)}',
      );

      // Mark email as verified
      isEmailVerified.value = true;
      verifiedEmail.value = email;

      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      print('Verify email code error: $e');
      return false;
    }
  }

  // PIN Reset via Email
  Future<bool> sendPinResetCode(String email) async {
    try {
      isLoading.value = true;

      // Validate email format
      if (!_isValidEmailFormat(email)) {
        isLoading.value = false;
        return false;
      }

      // Check if email exists in your system
      final user = await _userRepository.findByEmail(email);
      if (user != null) {
        // Check rate limiting for reset requests
        final resetAttemptsKey = 'reset_attempts_${_sanitizeEmailKey(email)}';
        final resetAttempts = await _secureStorage.read(key: resetAttemptsKey);
        int attemptCount = resetAttempts != null ? int.parse(resetAttempts) : 0;

        if (attemptCount >= 3) {
          final lastResetAttempt = await _secureStorage.read(
            key: 'last_reset_attempt_${_sanitizeEmailKey(email)}',
          );
          if (lastResetAttempt != null) {
            final lastAttemptTime = DateTime.parse(lastResetAttempt);
            if (DateTime.now().difference(lastAttemptTime).inMinutes < 30) {
              isLoading.value = false;
              Get.snackbar(
                'Rate Limited',
                'Too many reset requests. Please try again later.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return false;
            }
          }
        }

        // Generate a 6-digit reset code
        final Random random = Random();
        final String resetCode = (100000 + random.nextInt(900000)).toString();

        // Save reset code with expiry (1 hour)
        await _secureStorage.write(
          key: 'reset_code_${_sanitizeEmailKey(email)}',
          value: resetCode,
        );
        await _secureStorage.write(
          key: 'reset_code_expiry_${_sanitizeEmailKey(email)}',
          value: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        );

        // Update attempt tracking
        await _secureStorage.write(
          key: resetAttemptsKey,
          value: (attemptCount + 1).toString(),
        );
        await _secureStorage.write(
          key: 'last_reset_attempt_${_sanitizeEmailKey(email)}',
          value: DateTime.now().toIso8601String(),
        );

        // Send reset code via email
        final emailSent = await _emailService.sendPinResetCode(
          email,
          resetCode,
        );

        isLoading.value = false;
        return emailSent;
      }

      isLoading.value = false;
      // Don't reveal if email exists or not for security
      Get.snackbar(
        'If Email Exists',
        'If an account exists with this email, you will receive a reset code.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      isLoading.value = false;
      print('Send reset email error: $e');
      return false;
    }
  }

  Future<bool> verifyResetCodeAndSetPin(
    String email,
    String resetCode,
    String newPin,
  ) async {
    try {
      isLoading.value = true;

      // Validate new PIN
      if (newPin.length < 4 || newPin.length > 6) {
        isLoading.value = false;
        return false;
      }

      // Verify reset code
      final savedCode = await _secureStorage.read(
        key: 'reset_code_${_sanitizeEmailKey(email)}',
      );
      final expiryString = await _secureStorage.read(
        key: 'reset_code_expiry_${_sanitizeEmailKey(email)}',
      );

      if (savedCode == null || expiryString == null) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'No reset code found. Please request a new one.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry)) {
        // Clean up expired code
        await _secureStorage.delete(
          key: 'reset_code_${_sanitizeEmailKey(email)}',
        );
        await _secureStorage.delete(
          key: 'reset_code_expiry_${_sanitizeEmailKey(email)}',
        );
        isLoading.value = false;
        Get.snackbar(
          'Code Expired',
          'The reset code has expired. Please request a new one.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (savedCode != resetCode) {
        // Track failed reset attempts
        final failedResetKey = 'failed_reset_${_sanitizeEmailKey(email)}';
        final failedAttempts = await _secureStorage.read(key: failedResetKey);
        int failedCount = failedAttempts != null
            ? int.parse(failedAttempts)
            : 0;
        failedCount++;

        await _secureStorage.write(
          key: failedResetKey,
          value: failedCount.toString(),
        );

        if (failedCount >= 3) {
          // Clear reset code after too many failed attempts
          await _secureStorage.delete(
            key: 'reset_code_${_sanitizeEmailKey(email)}',
          );
          await _secureStorage.delete(
            key: 'reset_code_expiry_${_sanitizeEmailKey(email)}',
          );
          isLoading.value = false;
          Get.snackbar(
            'Too Many Attempts',
            'Too many failed reset attempts. Please request a new code.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }

        isLoading.value = false;
        Get.snackbar(
          'Invalid Code',
          'The reset code is incorrect. ${3 - failedCount} attempts remaining.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Set new PIN
      final success = await setPin(newPin);

      if (success) {
        // Clear reset code and attempt tracking
        await _secureStorage.delete(
          key: 'reset_code_${_sanitizeEmailKey(email)}',
        );
        await _secureStorage.delete(
          key: 'reset_code_expiry_${_sanitizeEmailKey(email)}',
        );
        await _secureStorage.delete(
          key: 'reset_attempts_${_sanitizeEmailKey(email)}',
        );
        await _secureStorage.delete(
          key: 'failed_reset_${_sanitizeEmailKey(email)}',
        );
        await _secureStorage.delete(
          key: 'last_reset_attempt_${_sanitizeEmailKey(email)}',
        );

        isLoading.value = false;
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      isLoading.value = false;
      print('Reset PIN error: $e');
      return false;
    }
  }

  // Biometric Methods
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

  // Logout and Clear Data Methods
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Clear authentication state
      isAuthenticated.value = false;
      pin.value = '';
      failedAttempts.value = 0;
      isLocked.value = false;
      lockoutUntil.value = null;
      isEmailVerified.value = false;
      verifiedEmail.value = '';

      // Close all open boxes
      await _localStorage.closeAllBoxes();

      isLoading.value = false;

      // Navigate to login screen
      Get.offAllNamed('/login');

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

      // Clear all email-related data
      final allKeys = await _secureStorage.readAll();
      for (var key in allKeys.keys) {
        if (key.startsWith('email_verification_') ||
            key.startsWith('reset_code_') ||
            key.startsWith('verification_attempts_') ||
            key.startsWith('failed_verification_') ||
            key.startsWith('reset_attempts_') ||
            key.startsWith('failed_reset_') ||
            key.startsWith('last_verification_attempt_') ||
            key.startsWith('last_reset_attempt_')) {
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
      isEmailVerified.value = false;
      verifiedEmail.value = '';

      isLoading.value = false;
      Get.offAllNamed('/set-pin');
    } catch (e) {
      isLoading.value = false;
      print('Error clearing data: $e');
      rethrow;
    }
  }

  // Helper Methods
  String _sanitizeEmailKey(String email) {
    // Replace special characters to create a valid storage key
    return email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }

  bool _isValidEmailFormat(String email) {
    // Comprehensive email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) return false;

    // Additional validation rules
    if (email.contains('..')) return false;
    if (email.length > 254) return false;

    final parts = email.split('@');
    if (parts.length != 2) return false;

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.isEmpty || localPart.length > 64) return false;
    if (domain.isEmpty || domain.length > 255) return false;

    final domainRegex = RegExp(r'^[a-zA-Z0-9.-]+$');
    if (!domainRegex.hasMatch(domain)) return false;

    final domainParts = domain.split('.');
    if (domainParts.length < 2) return false;

    final tld = domainParts.last;
    if (tld.length < 2 || tld.length > 63) return false;

    return true;
  }

  // Legacy method for backward compatibility
  Future<bool> sendPinResetEmail(String email, String token) async {
    return sendPinResetCode(email);
  }

  Future<bool> resetPinWithToken(
    String email,
    String token,
    String newPin,
  ) async {
    return verifyResetCodeAndSetPin(email, token, newPin);
  }
}
