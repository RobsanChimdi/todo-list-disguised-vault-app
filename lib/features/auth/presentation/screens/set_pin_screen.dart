// lib/features/auth/presentation/screens/set_pin_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({Key? key}) : super(key: key);

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final RxBool _isPinVisible = false.obs;
  final RxBool _isConfirmPinVisible = false.obs;
  final RxString _pinError = ''.obs;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Header
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text('Set Up Your Secret PIN', style: AppStyles.heading1),
                    const SizedBox(height: 12),
                    Text(
                      'This PIN will be used to access your secure vault. '
                      'Choose a PIN you can remember but others won\'t guess.',
                      style: AppStyles.bodyText.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // PIN Input
                    Text('Enter PIN', style: AppStyles.labelText),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _pinController,
                      obscureText: !_isPinVisible.value,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPinVisible.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => _isPinVisible.toggle(),
                      ),
                      onChanged: (value) {
                        if (_pinError.value.isNotEmpty) {
                          _pinError.value = '';
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Confirm PIN
                    Text('Confirm PIN', style: AppStyles.labelText),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _confirmPinController,
                      obscureText: !_isConfirmPinVisible.value,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPinVisible.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => _isConfirmPinVisible.toggle(),
                      ),
                      onChanged: (value) {
                        if (_pinError.value.isNotEmpty) {
                          _pinError.value = '';
                        }
                      },
                    ),

                    if (_pinError.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _pinError.value,
                          style: AppStyles.errorText,
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Keep your PIN safe! If you forget it, you will lose access to your vault.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            onPressed: () {
                              _authController.showVaultAccess.value = false;
                              Get.back();
                            },
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => CustomButton(
                              text: 'Set PIN',
                              onPressed: _authController.isLoading.value
                                  ? null
                                  : _setPin,
                              isLoading: _authController.isLoading.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (_authController.isLoading.value)
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

  Future<void> _setPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    // Validate PIN
    if (pin.isEmpty) {
      _pinError.value = 'Please enter a PIN';
      return;
    }

    if (pin.length < 4) {
      _pinError.value = 'PIN must be at least 4 digits';
      return;
    }

    if (pin.length > 6) {
      _pinError.value = 'PIN must be at most 6 digits';
      return;
    }

    if (pin != confirmPin) {
      _pinError.value = 'PINs do not match';
      return;
    }

    // Set PIN
    final success = await _authController.setPin(pin);

    if (!success) {
      Get.snackbar(
        'Error',
        'Failed to set PIN. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
