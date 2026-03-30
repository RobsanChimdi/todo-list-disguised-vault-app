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
      initialRoute: AppRoutes.notebook, // Start with notebook directly
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// Root widget that handles app initialization
class AppRoot extends StatefulWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
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

      // Initialize controllers but don't authenticate yet
      Get.put(AuthController());
      Get.put(DisguiseController());
      Get.put(NoteController());
      Get.put(VaultController());

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing app: $e');
      _showInitializationError();
    }
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

    return const MyApp();
  }
}
