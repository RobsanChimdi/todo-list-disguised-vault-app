// lib/core/services/fake_crash_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FakeCrashService {
  static void triggerFakeCrash() {
    // Show fake error dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Application Error'),
        content: const Text(
          'The application has encountered an unexpected error and needs to close.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Simulate app restart
              Get.offAllNamed('/notebook');
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static void showFakeLoading() {
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
      Get.back();
    });
  }
}
