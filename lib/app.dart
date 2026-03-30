// lib/app.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/disguise/controllers/disguise_controller.dart';
import 'features/notebook/presentation/controllers/note_controller.dart';
import 'features/vault/presentation/controllers/vault_controller.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'config/theme.dart';
import 'routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: _getInitialRoute(),
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      builder: (context, child) {
        return _buildWithControllers(child);
      },
    );
  }

  String _getInitialRoute() {
    // We'll determine the initial route based on auth state
    // This is a placeholder; actual implementation will be in the root widget
    return AppRoutes.splash;
  }

  Widget _buildWithControllers(Widget? child) {
    return GetBuilder<AuthController>(
      init: AuthController(),
      builder: (authController) {
        // Initialize other controllers after auth is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!Get.isRegistered<DisguiseController>()) {
            Get.put(DisguiseController());
          }
          if (!Get.isRegistered<NoteController>()) {
            Get.put(NoteController());
          }
          if (!Get.isRegistered<VaultController>()) {
            Get.put(VaultController());
          }
        });

        return child ?? const SizedBox.shrink();
      },
    );
  }
}

// Root widget that handles app initialization and routing
class AppRoot extends StatefulWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final AuthController _authController = Get.find<AuthController>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Initialize services
      await Get.putAsync<LocalStorageService>(
        () async => LocalStorageService(),
      );
      await Get.putAsync<SecureStorageService>(
        () async => SecureStorageService(),
      );

      // Check initial setup
      final isSetupComplete = await _authController.isInitialSetupComplete();

      setState(() {
        _isInitialized = true;
      });

      // Navigate based on setup and auth state
      if (isSetupComplete) {
        if (_authController.isAuthenticated.value) {
          _navigateToHome();
        } else {
          _navigateToLogin();
        }
      } else {
        _navigateToSetup();
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Show error dialog or fallback
      _showInitializationError();
    }
  }

  void _navigateToHome() {
    Get.offAllNamed(AppRoutes.home);
  }

  void _navigateToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  void _navigateToSetup() {
    Get.offAllNamed(AppRoutes.setPin);
  }

  void _showInitializationError() {
    Get.dialog(
      AlertDialog(
        title: const Text('Initialization Error'),
        content: const Text('Failed to initialize the app. Please restart.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Obx(() {
      // Handle locked state
      if (_authController.isLocked.value) {
        return _buildLockScreen();
      }

      // Handle authenticated state
      if (_authController.isAuthenticated.value) {
        return _buildMainApp();
      }

      // Handle unauthenticated state
      return _buildAuthScreen();
    });
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'App Locked',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Too many failed attempts. Please try again in ${_getRemainingLockoutTime()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Show PIN entry after lockout period
                  _showPinEntry();
                },
                child: const Text('Enter PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRemainingLockoutTime() {
    if (_authController.lockoutUntil.value == null) return '5 minutes';
    final remaining = _authController.lockoutUntil.value!.difference(
      DateTime.now(),
    );
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes minutes $seconds seconds';
  }

  Widget _buildMainApp() {
    return const MyApp();
  }

  Widget _buildAuthScreen() {
    return Container(); // Will be replaced by actual auth screen
  }

  void _showPinEntry() {
    Get.toNamed(AppRoutes.lockScreen);
  }
}

// Splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 80, color: AppColors.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
