// lib/features/disguise/services/disguise_service.dart

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/services/local_storage_service.dart';

class DisguiseService extends GetxService {
  final LocalStorageService _storage = LocalStorageService();

  // ================= DISGUISE MODE =================
  
  /// Check if disguise mode is active
  Future<bool> isDisguiseMode() async {
    final isActive = await _storage.readData('disguise_active');
    return isActive == true;
  }

  /// Set disguise mode
  Future<void> setDisguiseMode(bool active) async {
    await _storage.writeData('disguise_active', active);
  }

  /// Activate disguise mode (called after failed attempts)
  Future<void> activateDisguise() async {
    await setDisguiseMode(true);
    await _addDecoyContent();
    await _showFakeErrorMessage();
  }

  /// Deactivate disguise mode
  Future<void> deactivateDisguise() async {
    await setDisguiseMode(false);
  }

  // ================= DECOY CONTENT =================
  
  /// Add decoy notes to make app look legitimate
  Future<void> _addDecoyContent() async {
    try {
      // Check if we already added decoys
      final decoysAdded = await _storage.readData('decoys_added');
      if (decoysAdded == true) return;
      
      // Add sample notes (will be implemented by NoteController)
      await _storage.writeData('decoys_added', true);
    } catch (e) {
      print('Error adding decoy content: $e');
    }
  }

  /// Show fake error message when disguise is active
  Future<void> _showFakeErrorMessage() async {
    // This will be handled by the UI layer
    print('Disguise activated - showing fake errors');
  }

  // ================= FAKE FEATURES =================
  
  /// Show fake "premium required" message
  void showFakePremiumRequired() {
    Get.snackbar(
      'Premium Feature',
      'This feature requires a premium subscription',
      backgroundColor: Colors.grey.shade800,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show fake loading screen
  void showFakeLoading() {
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    });
  }

  /// Trigger fake crash
  void triggerFakeCrash() {
    Get.dialog(
      AlertDialog(
        title: const Text('Application Error'),
        content: const Text(
          'The application has encountered an unexpected error.\n\n'
          'Error code: 0x80004005',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.offAllNamed('/notebook');
            },
            child: const Text('Restart'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}