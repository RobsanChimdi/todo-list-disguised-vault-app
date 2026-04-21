// lib/features/auth/presentation/screens/set_pin_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/services/user_repository.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({Key? key}) : super(key: key);

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  late final AuthController _authController;
  late final UserRepository _userRepository;

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  final RxBool _isPinVisible = false.obs;
  final RxBool _isConfirmPinVisible = false.obs;
  final RxString _pinError = ''.obs;
  final RxString _emailError = ''.obs;
  final RxString _verificationError = ''.obs;
  final RxBool _isEmailVerified = false.obs;
  final RxString _verificationCode = ''.obs;
  final RxInt _resendCooldown = 0.obs;

  final RxInt _currentStep = 0.obs;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _userRepository = Get.find<UserRepository>();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _emailController.dispose();
    _verificationCodeController.dispose();
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

                    // Step indicator
                    _buildStepIndicator(),
                    const SizedBox(height: 32),

                    // Step 1: Set PIN
                    if (_currentStep.value == 0) ...[
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
                        hintText: '',
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
                        hintText: '',
                      ),

                      if (_pinError.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _pinError.value,
                            style: AppStyles.errorText,
                          ),
                        ),
                    ],

                    // Step 2: Enter Email for recovery
                    if (_currentStep.value == 1 && !_isEmailVerified.value) ...[
                      Text('Recovery Email', style: AppStyles.heading1),
                      const SizedBox(height: 12),
                      Text(
                        'Add a recovery email address. '
                        'This will be used to reset your PIN if you forget it.',
                        style: AppStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email Input
                      Text('Email Address', style: AppStyles.labelText),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email,
                              hintText: 'your@email.com',
                              onChanged: (value) {
                                if (_emailError.value.isNotEmpty) {
                                  _emailError.value = '';
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _authController.isLoading.value
                                ? null
                                : _sendVerificationCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(100, 56),
                            ),
                            child: _authController.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Send Code'),
                          ),
                        ],
                      ),

                      if (_emailError.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _emailError.value,
                            style: AppStyles.errorText,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Verification Code Input
                      if (_verificationCode.value.isNotEmpty) ...[
                        Text('Verification Code', style: AppStyles.labelText),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _verificationCodeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                prefixIcon: Icons.verified_user,
                                hintText: 'Enter 6-digit code',
                                onChanged: (value) {
                                  if (_verificationError.value.isNotEmpty) {
                                    _verificationError.value = '';
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed:
                                  _resendCooldown.value > 0 ||
                                      _authController.isLoading.value
                                  ? null
                                  : _sendVerificationCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: AppColors.primary,
                                minimumSize: const Size(100, 56),
                              ),
                              child: _resendCooldown.value > 0
                                  ? Text('${_resendCooldown.value}s')
                                  : const Text('Resend'),
                            ),
                          ],
                        ),
                        if (_verificationError.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _verificationError.value,
                              style: AppStyles.errorText,
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _authController.isLoading.value
                              ? null
                              : _verifyEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _authController.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Verify Email'),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Info about email usage
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your email is only used for PIN recovery and will be stored securely.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Success message after verification
                    if (_isEmailVerified.value) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                              size: 60,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Email Verified!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _emailController.text.trim(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 32),

                    // Info box (only show in step 1)
                    if (_currentStep.value == 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Important: Keep your PIN safe! While you can reset it via email, '
                                'it\'s best to use a PIN you\'ll remember.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.amber.shade700,
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
                        if (_currentStep.value == 1)
                          Expanded(
                            child: CustomButton(
                              text: 'Back',
                              onPressed: _goToPreviousStep,
                              isOutlined: true,
                            ),
                          ),
                        if (_currentStep.value == 1) const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => CustomButton(
                              text: _currentStep.value == 0
                                  ? 'Next'
                                  : (_isEmailVerified.value
                                        ? 'Complete Setup'
                                        : 'Skip for now'),
                              onPressed: _authController.isLoading.value
                                  ? null
                                  : _currentStep.value == 0
                                  ? _validateAndNext
                                  : (_isEmailVerified.value
                                        ? _completeSetup
                                        : _skipEmailSetup),
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

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(0, 'Set PIN'),
        Container(
          width: 40,
          height: 2,
          color: _currentStep.value >= 1 ? AppColors.primary : Colors.grey[300],
        ),
        _buildStepCircle(1, 'Recovery Email'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep.value >= step;
    final isCompleted = _currentStep.value > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.grey[300],
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    // Comprehensive email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    // Additional validation rules
    if (!emailRegex.hasMatch(email)) return false;

    // Check for consecutive dots
    if (email.contains('..')) return false;

    // Check length limits
    if (email.length > 254) return false;

    // Split local part and domain
    final parts = email.split('@');
    if (parts.length != 2) return false;

    final localPart = parts[0];
    final domain = parts[1];

    // Local part validation
    if (localPart.isEmpty || localPart.length > 64) return false;

    // Domain validation
    if (domain.isEmpty || domain.length > 255) return false;

    // Check for valid domain characters
    final domainRegex = RegExp(r'^[a-zA-Z0-9.-]+$');
    if (!domainRegex.hasMatch(domain)) return false;

    // Check domain has at least one dot and valid TLD
    final domainParts = domain.split('.');
    if (domainParts.length < 2) return false;

    final tld = domainParts.last;
    if (tld.length < 2 || tld.length > 63) return false;

    return true;
  }

  bool _isWeakPin(String pin) {
    // Check for common weak PINs
    final weakPins = [
      '0000',
      '1111',
      '2222',
      '3333',
      '4444',
      '5555',
      '6666',
      '7777',
      '8888',
      '9999',
      '1234',
      '2345',
      '3456',
      '4567',
      '5678',
      '6789',
      '000000',
      '111111',
      '222222',
      '333333',
      '444444',
      '555555',
      '666666',
      '777777',
      '888888',
      '999999',
      '123456',
      '234567',
      '345678',
      '456789',
      '12345678',
      '012345',
      '987654',
      '112233',
      '121212',
      '123123',
      '101010',
    ];

    // Check for sequential patterns
    bool isSequential = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != (int.parse(pin[i - 1]) + 1) % 10) {
        isSequential = false;
        break;
      }
    }

    // Check for reverse sequential patterns
    bool isReverseSequential = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != (int.parse(pin[i - 1]) - 1 + 10) % 10) {
        isReverseSequential = false;
        break;
      }
    }

    return weakPins.contains(pin) || isSequential || isReverseSequential;
  }

  void _showWeakPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weak PIN Detected'),
        content: const Text(
          'Your PIN is too easy to guess. Please use a more secure PIN that\'s not a common sequence or repeated digits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _currentStep.value = 1; // Continue anyway if user insists
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _validateAndNext() async {
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

    // Check if PIN is too simple
    if (_isWeakPin(pin)) {
      _showWeakPinDialog();
      return;
    }

    // Proceed to email step
    _currentStep.value = 1;
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    // Validate email format
    if (email.isEmpty) {
      _emailError.value = 'Please enter your email address';
      return;
    }

    if (!_isValidEmail(email)) {
      _emailError.value =
          'Please enter a valid email address (e.g., name@domain.com)';
      return;
    }

    // Clear previous verification
    _verificationError.value = '';
    _verificationCodeController.clear();

    // Send verification code
    final success = await _authController.sendEmailVerificationCode(email);

    if (success) {
      _verificationCode.value = 'sent';
      _startResendCooldown();
      Get.snackbar(
        'Verification Code Sent',
        'Please check your email for the 6-digit verification code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      _emailError.value = 'Failed to send verification code. Please try again.';
    }
  }

  void _startResendCooldown() {
    _resendCooldown.value = 60; // 60 seconds cooldown
    Future.delayed(const Duration(seconds: 1), () {
      if (_resendCooldown.value > 0) {
        _resendCooldown.value--;
        _startResendCooldown();
      }
    });
  }

  Future<void> _verifyEmail() async {
    final code = _verificationCodeController.text.trim();
    final email = _emailController.text.trim();

    if (code.isEmpty) {
      _verificationError.value = 'Please enter the verification code';
      return;
    }

    if (code.length != 6) {
      _verificationError.value = 'Please enter a valid 6-digit code';
      return;
    }

    // Verify the code
    final isValid = await _authController.verifyEmailCode(email, code);

    if (isValid) {
      _isEmailVerified.value = true;
      // Save email to repository
      await _userRepository.saveUserEmail(email);
      Get.snackbar(
        'Success',
        'Email verified successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      _verificationError.value = 'Invalid verification code. Please try again.';
    }
  }

  void _goToPreviousStep() {
    _currentStep.value = 0;
  }

  void _skipEmailSetup() async {
    // Show confirmation dialog
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Email Setup?'),
        content: const Text(
          'Without a recovery email, you won\'t be able to reset your PIN if you forget it. '
          'Are you sure you want to skip this step?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (shouldSkip == true) {
      await _completeSetup(skipEmail: true);
    }
  }

  Future<void> _completeSetup({bool skipEmail = false}) async {
    final pin = _pinController.text.trim();

    // Set the PIN
    final success = await _authController.setPin(pin);

    if (success) {
      if (!skipEmail && _isEmailVerified.value) {
        // Email is already saved in verification step
        Get.snackbar(
          'Setup Complete',
          'Your PIN has been set. You can use your email to recover your PIN if needed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else if (skipEmail) {
        Get.snackbar(
          'Setup Complete',
          'Your PIN has been set. Remember to keep it safe as you won\'t have email recovery.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }

      // Navigate to vault
      Get.offAllNamed('/vault');
    } else {
      Get.snackbar(
        'Error',
        'Failed to set PIN. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
