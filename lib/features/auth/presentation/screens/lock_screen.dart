// lib/features/auth/presentation/screens/lock_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/custom_textfield.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final AuthController _authController;
  final RxString _enteredPin = ''.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isBiometricAvailable = false.obs;
  final RxInt _lockoutTimeRemaining = 0.obs;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _checkBiometricAvailability();
    _startLockoutTimer();
  }

  Future<void> _checkBiometricAvailability() async {
    _isBiometricAvailable.value = _authController.isBiometricsEnabled.value;
  }

  void _startLockoutTimer() {
    if (_authController.isLocked.value &&
        _authController.lockoutUntil.value != null) {
      _updateLockoutTimer();
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        _updateLockoutTimer();
        return _lockoutTimeRemaining.value > 0;
      });
    }
  }

  void _updateLockoutTimer() {
    if (_authController.lockoutUntil.value != null) {
      final remaining = _authController.lockoutUntil.value!.difference(
        DateTime.now(),
      );
      if (remaining.inSeconds > 0) {
        _lockoutTimeRemaining.value = remaining.inSeconds;
      } else {
        _lockoutTimeRemaining.value = 0;
        _authController.isLocked.value = false;
        _authController.failedAttempts.value = 0;
        _authController.lockoutUntil.value = null;
        _errorMessage.value = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              // SingleChildScrollView to prevent overflow
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Lock icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        _authController.isLocked.value
                            ? 'Account Locked'
                            : 'Enter PIN',
                        style: AppStyles.heading1.copyWith(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _authController.isLocked.value
                            ? 'Too many failed attempts'
                            : 'Enter your PIN to access the secure vault',
                        style: AppStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (_lockoutTimeRemaining.value > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Try again in ${(_lockoutTimeRemaining.value ~/ 60)}m ${(_lockoutTimeRemaining.value % 60)}s',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // PIN display
                      if (!_authController.isLocked.value) ...[
                        _buildPinDisplay(),
                        const SizedBox(height: 24),
                      ],

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
                      const SizedBox(height: 24),

                      // PIN Pad (only if not locked)
                      if (!_authController.isLocked.value) ...[
                        _buildPinPad(),
                        const SizedBox(height: 16),
                      ],

                      // Biometric button (if available)
                      if (_isBiometricAvailable.value &&
                          !_authController.isLocked.value)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: _authenticateWithBiometrics,
                            icon: Icon(
                              Platform.isIOS ? Icons.face : Icons.fingerprint,
                              size: 18,
                            ),
                            label: const Text('Use Biometric'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                      // Forgot PIN button
                      if (!_authController.isLocked.value)
                        TextButton(
                          onPressed: _showForgotPinDialog,
                          child: const Text(
                            'Forgot PIN?',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),

                      // Cancel button
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),

                      const SizedBox(height: 20),
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
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('1'),
            _buildPinButton('2'),
            _buildPinButton('3'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('4'),
            _buildPinButton('5'),
            _buildPinButton('6'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('7'),
            _buildPinButton('8'),
            _buildPinButton('9'),
          ],
        ),
        const SizedBox(height: 12),
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
      onTap: _authController.isLocked.value
          ? null
          : () {
              if (isDelete) {
                _deleteDigit();
              } else if (isClear) {
                _clearPin();
              } else {
                _addDigit(digit);
              }
            },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _authController.isLocked.value
              ? Colors.grey.shade200
              : Colors.grey.shade100,
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
              ? const Icon(Icons.backspace_outlined, size: 24)
              : isClear
              ? const Icon(Icons.clear, size: 24)
              : Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 24,
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
      Get.offAllNamed('/vault');
    } else {
      _enteredPin.value = '';

      if (_authController.isLocked.value) {
        _errorMessage.value = 'Too many attempts. Locked for 5 minutes.';
        _startLockoutTimer();
      } else {
        final remainingAttempts = 5 - _authController.failedAttempts.value;
        _errorMessage.value =
            'Invalid PIN. $remainingAttempts attempt${remainingAttempts != 1 ? 's' : ''} remaining.';
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (_errorMessage.value.isNotEmpty && !_authController.isLocked.value) {
          _errorMessage.value = '';
        }
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await _authController.authenticateWithBiometrics();
    if (success) {
      Get.offAllNamed('/vault');
    } else {
      Get.snackbar(
        'Authentication Failed',
        'Please use your PIN to unlock',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Forgot PIN?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'If you forgot your PIN, you have two options:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (_authController.isBiometricsEnabled.value)
                  _buildOptionCard(
                    icon: Platform.isIOS ? Icons.face : Icons.fingerprint,
                    title: 'Use Biometric Authentication',
                    description:
                        'If you have biometrics enabled, you can unlock using fingerprint/face ID',
                    onTap: () async {
                      Navigator.pop(context);
                      await _authenticateWithBiometrics();
                    },
                  ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  icon: Icons.email,
                  title: 'Reset via Email',
                  description:
                      'We\'ll send a verification code to your registered email',
                  onTap: () {
                    Navigator.pop(context);
                    _showResetPinDialog();
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  icon: Icons.logout,
                  title: 'Logout and Re-login',
                  description: 'You\'ll need to set up your PIN again',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetPinDialog() {
    final emailController = TextEditingController();
    final codeController = TextEditingController();
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    RxInt currentStep = 0.obs;
    RxString verificationCode = ''.obs;
    RxBool isCodeSent = false.obs;
    RxInt resendCooldown = 0.obs;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                currentStep.value == 0
                    ? 'Reset PIN'
                    : currentStep.value == 1
                    ? 'Enter Verification Code'
                    : 'Set New PIN',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentStep.value == 0) ...[
                      const Text(
                        'Enter your email address to receive a verification code.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: emailController,
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            _authController.isLoading.value ||
                                resendCooldown.value > 0
                            ? null
                            : () async {
                                final email = emailController.text.trim();
                                if (email.isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'Please enter your email',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final success = await _authController
                                    .sendPinResetCode(email);

                                if (success) {
                                  isCodeSent.value = true;
                                  currentStep.value = 1;

                                  resendCooldown.value = 60;
                                  _startResendCooldown(
                                    resendCooldown,
                                    setState,
                                  );

                                  Get.snackbar(
                                    'Code Sent',
                                    'Verification code sent to your email',
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    'Failed to send verification code',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              },
                        child: _authController.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                resendCooldown.value > 0
                                    ? 'Resend in ${resendCooldown.value}s'
                                    : 'Send Code',
                              ),
                      ),
                    ],

                    if (currentStep.value == 1) ...[
                      const Text(
                        'Enter the 6-digit verification code sent to your email.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: codeController,
                        hintText: 'Enter 6-digit code',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        prefixIcon: Icons.verified_user,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _authController.isLoading.value
                                  ? null
                                  : () async {
                                      final code = codeController.text.trim();
                                      if (code.length != 6) {
                                        Get.snackbar(
                                          'Error',
                                          'Please enter a valid 6-digit code',
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }
                                      currentStep.value = 2;
                                    },
                              child: const Text('Verify Code'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: resendCooldown.value > 0
                                  ? null
                                  : () async {
                                      final email = emailController.text.trim();
                                      await _authController.sendPinResetCode(
                                        email,
                                      );
                                      resendCooldown.value = 60;
                                      _startResendCooldown(
                                        resendCooldown,
                                        setState,
                                      );
                                    },
                              child: Text(
                                resendCooldown.value > 0
                                    ? 'Resend (${resendCooldown.value}s)'
                                    : 'Resend Code',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (currentStep.value == 2) ...[
                      const Text(
                        'Enter your new PIN',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: pinController,
                        hintText: 'Enter new PIN',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        prefixIcon: Icons.lock,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: confirmPinController,
                        hintText: 'Confirm new PIN',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (currentStep.value > 0) {
                      currentStep.value--;
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(currentStep.value == 0 ? 'Cancel' : 'Back'),
                ),
                if (currentStep.value == 2)
                  ElevatedButton(
                    onPressed: _authController.isLoading.value
                        ? null
                        : () async {
                            final newPin = pinController.text.trim();
                            final confirmPin = confirmPinController.text.trim();

                            if (newPin.isEmpty || newPin.length < 4) {
                              Get.snackbar(
                                'Error',
                                'PIN must be at least 4 digits',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            if (newPin != confirmPin) {
                              Get.snackbar(
                                'Error',
                                'PINs do not match',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            final success = await _authController
                                .verifyResetCodeAndSetPin(
                                  emailController.text.trim(),
                                  codeController.text.trim(),
                                  newPin,
                                );

                            Navigator.pop(context);

                            if (success) {
                              Get.snackbar(
                                'Success',
                                'PIN has been reset successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Failed to reset PIN. Please try again.',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                    child: const Text('Reset PIN'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _startResendCooldown(RxInt cooldown, StateSetter setState) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (cooldown.value > 0) {
        cooldown.value--;
        setState(() {});
        return true;
      }
      return false;
    });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout? You\'ll need to set up your PIN again to access the vault.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authController.logout();
                Get.offAllNamed('/set-pin');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
