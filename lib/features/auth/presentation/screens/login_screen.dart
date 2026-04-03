// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Secure Vault Access',
                        style: AppStyles.heading1.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Authenticate to access your private files',
                        style: AppStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // PIN Entry Button
                      CustomButton(
                        text: 'Enter PIN',
                        onPressed: () {
                          authController.requestVaultAccess();
                        },
                        icon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 16),

                      // Biometric option (if available)
                      if (false) // Add biometric check here
                        CustomButton(
                          text: 'Use Fingerprint',
                          onPressed: () {
                            // Implement biometric authentication
                          },
                          isOutlined: true,
                          icon: Icons.fingerprint,
                        ),
                      const SizedBox(height: 24),

                      // Forgot PIN option
                      TextButton(
                        onPressed: () {
                          _showForgotPinDialog(context);
                        },
                        child: Text(
                          'Forgot PIN?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),

                      // Cancel button
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (authController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPinDialog(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'If you forgot your PIN, you will need to reset the app. '
          'This will delete all vault data. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog

              // Show confirmation
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Confirm Reset'),
                  content: const Text(
                    'This action cannot be undone. All vault data will be permanently deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('No'),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Yes, Reset'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await authController.resetApp();
                Get.offAllNamed('/notebook');
                Get.snackbar(
                  'App Reset',
                  'All data has been cleared. You can set up a new PIN.',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: const Text('Reset App', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
