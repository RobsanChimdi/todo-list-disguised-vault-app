// lib/features/auth/presentation/screens/lock_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../vault/presentation/screens/vault_home_screen.dart';
import 'set_pin_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  late final AuthController _authController;
  final RxString _enteredPin = ''.obs;
  final RxString _errorMessage = ''.obs;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    // Ensure AuthController is registered
    _authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Check if PIN exists, if not, redirect to SetPinScreen
    _checkPinAndRedirect();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward();
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  void _checkPinAndRedirect() {
    // Wait a moment for the UI to load
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_authController.hasPin.value && mounted) {
        // No PIN exists - redirect to SetPinScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetPinScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no PIN exists, show loading or redirect (handled in initState)
    if (!_authController.hasPin.value) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // PIN exists - show normal lock screen
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
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
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                        // Lockout info
                        if (_authController.isLocked.value &&
                            _authController.lockoutUntil.value != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              'Locked for ${_getRemainingLockoutTime()}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        // Failed attempts count
                        if (_authController.failedAttempts.value > 0 &&
                            !_authController.isLocked.value)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${_authController.failedAttempts.value} of 5 attempts used',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading overlay
              if (_authController.isLoading.value || _isLoading.value)
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VaultHomeScreen()),
      );
    } else {
      // Failed
      _enteredPin.value = '';
      _errorMessage.value = 'Invalid PIN';
      _shake();

      // Auto clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_errorMessage.value.isNotEmpty) {
          _errorMessage.value = '';
        }
      });
    }
  }

  String _getRemainingLockoutTime() {
    if (_authController.lockoutUntil.value == null) return '5 minutes';
    final remaining = _authController.lockoutUntil.value!.difference(
      DateTime.now(),
    );
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''} $seconds second${seconds > 1 ? 's' : ''}';
    }
    return '$seconds second${seconds > 1 ? 's' : ''}';
  }
}
