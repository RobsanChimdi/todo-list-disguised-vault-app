// lib/features/auth/presentation/controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/local_storage_service.dart';

class AuthController extends GetxController {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalStorageService _localStorage = Get.find<LocalStorageService>();

  var isAuthenticated = false.obs;
  var hasPin = false.obs;
  var pin = ''.obs;
  var isLoading = false.obs;
  var isLocked = false.obs;
  var failedAttempts = 0.obs;
  var lockoutUntil = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    checkPinExists();
  }

  Future<void> checkPinExists() async {
    final savedPin = await _secureStorage.read(key: 'user_pin');
    hasPin.value = savedPin != null && savedPin.isNotEmpty;
    if (hasPin.value) {
      pin.value = savedPin!;
    }
  }

  Future<bool> verifyPin(String enteredPin) async {
    // Check if locked out
    if (isLocked.value && lockoutUntil.value != null) {
      if (DateTime.now().isBefore(lockoutUntil.value!)) {
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
      Get.offAllNamed('/lock-screen');

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

      // Clear all local storage boxes
      await _localStorage.resetAllStorage();

      // Reset state
      isAuthenticated.value = false;
      hasPin.value = false;
      pin.value = '';
      failedAttempts.value = 0;
      isLocked.value = false;
      lockoutUntil.value = null;

      isLoading.value = false;
      Get.offAllNamed('/set-pin');
    } catch (e) {
      isLoading.value = false;
      print('Error clearing data: $e');
      rethrow;
    }
  }
}
