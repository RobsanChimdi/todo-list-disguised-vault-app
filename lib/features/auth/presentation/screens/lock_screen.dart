// lib/features/auth/presentation/screens/lock_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../routes/app_routes.dart';

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
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title based on state
                      if (_authController.isLocked.value) ...[
                        Text(
                          'Account Locked',
                          style: AppStyles.heading1.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Too many failed attempts',
                          style: AppStyles.bodyText.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else if (_authController.hasPin.value) ...[
                        Text(
                          'Enter PIN',
                          style: AppStyles.heading1.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your PIN to access the secure vault',
                          style: AppStyles.bodyText.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          'Welcome!',
                          style: AppStyles.heading1.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create a PIN to protect your hidden vault',
                          style: AppStyles.bodyText.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      // Lockout timer
                      if (_lockoutTimeRemaining.value > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'Try again in ${(_lockoutTimeRemaining.value ~/ 60)}m ${(_lockoutTimeRemaining.value % 60)}s',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // PIN display (only for PIN entry mode)
                      if (_authController.hasPin.value &&
                          !_authController.isLocked.value) ...[
                        _buildPinDisplay(),
                        const SizedBox(height: 24),
                      ],

                      // Error message
                      if (_errorMessage.value.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage.value,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // PIN Pad (only for PIN entry mode)
                      if (_authController.hasPin.value &&
                          !_authController.isLocked.value) ...[
                        _buildPinPad(),
                        const SizedBox(height: 16),
                      ],

                      // ============ CREATE PIN SECTION (for new users) ============
                      if (!_authController.hasPin.value &&
                          !_authController.isLocked.value) ...[
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.offAllNamed('/set-pin');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Create New PIN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Demo mode option
                        OutlinedButton.icon(
                          onPressed: () {
                            _showDemoModeDialog();
                          },
                          icon: const Icon(Icons.preview),
                          label: const Text('Try Demo Mode'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],

                      // ============ FORGOT PIN SECTION (for existing users) ============
                      if (_authController.hasPin.value &&
                          !_authController.isLocked.value) ...[
                        // Biometric button (if available)
                        if (_isBiometricAvailable.value)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: _authenticateWithBiometrics,
                              icon: Icon(
                                Platform.isIOS ? Icons.face : Icons.fingerprint,
                                size: 20,
                              ),
                              label: const Text('Use Biometric Authentication'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),

                        // Forgot PIN button
                        TextButton(
                          onPressed: _showForgotPinDialog,
                          child: const Text(
                            'Forgot PIN?',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],

                      // Cancel button (always show)
                      TextButton(
                        onPressed: () {
                          Get.offAllNamed('/todo');
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.value.length
                ? AppColors.primary
                : Colors.grey.shade300,
            boxShadow: index < _enteredPin.value.length
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ]
                : null,
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
              HapticFeedback.lightImpact();
              if (isDelete) {
                _deleteDigit();
              } else if (isClear) {
                _clearPin();
              } else {
                _addDigit(digit);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _authController.isLocked.value
              ? Colors.grey.shade200
              : Colors.grey.shade100,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: isDelete
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 28,
                  color: Colors.grey,
                )
              : isClear
              ? const Icon(Icons.clear, size: 28, color: Colors.red)
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

  void _showDemoModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Demo Mode'),
        content: const Text(
          'Demo mode allows you to explore the app without setting up a PIN. '
          'Your data will not be saved permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.offAllNamed('/todo');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continue as Guest'),
          ),
        ],
      ),
    );
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
                  'If you forgot your PIN, you have several options:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Option 1: Biometric (if available)
                if (_authController.isBiometricsEnabled.value)
                  _buildOptionCard(
                    icon: Platform.isIOS ? Icons.face : Icons.fingerprint,
                    title: 'Use Biometric Authentication',
                    description: 'Unlock using fingerprint or face ID',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      await _authenticateWithBiometrics();
                    },
                  ),

                // Option 2: Reset via Email
                _buildOptionCard(
                  icon: Icons.email,
                  title: 'Reset via Email',
                  description:
                      'Send verification code to your registered email',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _showResetPinDialog();
                  },
                ),

                // Option 3: Reset PIN (fresh start)
                _buildOptionCard(
                  icon: Icons.refresh,
                  title: 'Reset PIN (Fresh Start)',
                  description: 'Clear all data and set up new PIN',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showResetConfirmation();
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    RxInt resendCooldown = 0.obs;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Obx(
              () => AlertDialog(
                title: Text(
                  currentStep.value == 0
                      ? 'Reset PIN'
                      : currentStep.value == 1
                      ? 'Verification'
                      : 'Set New PIN',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentStep.value == 0) ...[
                        const Text(
                          'Enter your registered email address to receive a verification code.',
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
                                onPressed: () async {
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
                                child: const Text('Verify'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton(
                                onPressed: resendCooldown.value > 0
                                    ? null
                                    : () async {
                                        final email = emailController.text
                                            .trim();
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
                                      : 'Resend',
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
                      onPressed: () async {
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
                          Get.offAllNamed('/todo');
                        } else {
                          Get.snackbar(
                            'Error',
                            'Failed to reset PIN',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      child: const Text('Reset PIN'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startResendCooldown(RxInt cooldown, StateSetter setState) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (cooldown.value > 0 && mounted) {
        cooldown.value--;
        setState(() {});
        return true;
      }
      return false;
    });
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset PIN?'),
          content: const Text(
            'This will clear all your vault data and allow you to set up a new PIN. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authController.clearAllData();
                Get.offAllNamed('/set-pin');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
