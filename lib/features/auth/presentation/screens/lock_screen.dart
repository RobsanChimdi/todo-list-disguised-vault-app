// lib/features/auth/presentation/screens/lock_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final AuthController _authController;
  final RxString _enteredPin = ''.obs;
  final RxString _errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
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
                      // Lock icon
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
                        'Enter PIN',
                        style: AppStyles.heading1.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your PIN to access the secure vault',
                        style: AppStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // PIN display (dots)
                      _buildPinDisplay(),
                      const SizedBox(height: 32),

                      // Error message
                      if (_errorMessage.value.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage.value,
                            style: AppStyles.errorText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 32),

                      // PIN Pad
                      _buildPinPad(),

                      const SizedBox(height: 24),

                      // Cancel button
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.value.length
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('1'),
            _buildPinButton('2'),
            _buildPinButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('4'),
            _buildPinButton('5'),
            _buildPinButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('7'),
            _buildPinButton('8'),
            _buildPinButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('', isClear: true),
            _buildPinButton('0'),
            _buildPinButton('', isDelete: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPinButton(
    String digit, {
    bool isDelete = false,
    bool isClear = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isDelete) {
          _deleteDigit();
        } else if (isClear) {
          _clearPin();
        } else {
          _addDigit(digit);
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isDelete
              ? const Icon(Icons.backspace_outlined, size: 28)
              : isClear
              ? const Icon(Icons.clear, size: 28)
              : Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  void _addDigit(String digit) {
    if (_enteredPin.value.length < 6) {
      _enteredPin.value += digit;

      // Auto-submit when PIN reaches max length
      if (_enteredPin.value.length == 6) {
        _submitPin();
      }
    }
  }

  void _deleteDigit() {
    if (_enteredPin.value.isNotEmpty) {
      _enteredPin.value = _enteredPin.value.substring(
        0,
        _enteredPin.value.length - 1,
      );
      _errorMessage.value = '';
    }
  }

  void _clearPin() {
    _enteredPin.value = '';
    _errorMessage.value = '';
  }

  Future<void> _submitPin() async {
    final isValid = await _authController.verifyPin(_enteredPin.value);

    if (isValid) {
      // Success - navigate to vault
      Get.offAllNamed('/vault');
    } else {
      // Failed
      _enteredPin.value = '';
      _errorMessage.value = 'Invalid PIN';

      // Check if locked
      if (_authController.isLocked.value) {
        _errorMessage.value = 'Too many attempts. Locked for 5 minutes.';
      }

      // Auto clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_errorMessage.value.isNotEmpty) {
          _errorMessage.value = '';
        }
      });
    }
  }
}
