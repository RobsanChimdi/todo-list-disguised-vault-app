// lib/app.dart (Improved version with proper dependency order)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/disguise/controllers/disguise_controller.dart';
import 'features/notebook/presentation/controllers/note_controller.dart';
import 'features/vault/presentation/controllers/vualt_controller.dart';
import 'features/notebook/data/repositories/note_repository.dart';
import 'features/vault/data/repositories/vault_repository.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/secure_storage_service.dart';
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
      initialRoute: AppRoutes.notebook,
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

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
      // Step 1: Initialize Hive
      await Hive.initFlutter();
      
      // Step 2: Initialize and register LocalStorageService
      final localStorage = LocalStorageService();
      await localStorage.init();
      Get.put<LocalStorageService>(localStorage);
      
      // Step 3: Initialize SecureStorageService
      final secureStorage = SecureStorageService();
      Get.put<SecureStorageService>(secureStorage);
      
      // Step 4: Initialize repositories
      final noteRepository = NoteRepository(localStorage);
      final vaultRepository = VaultRepository(localStorage);
      
      // Step 5: Initialize controllers (order matters if they depend on each other)
      // AuthController doesn't depend on others
      Get.put<AuthController>(AuthController());
      
      // DisguiseController depends on LocalStorageService
      Get.put<DisguiseController>(DisguiseController());
      
      // NoteController depends on NoteRepository
      Get.put<NoteController>(NoteController(noteRepository));
      
      // VaultController depends on VaultRepository
      Get.put<VaultController>(VaultController(vaultRepository));
      
      // Step 6: Load initial data
      await Get.find<NoteController>().loadNotes();
      await Get.find<VaultController>().loadItems();
      
      setState(() {
        _isInitialized = true;
      });
      
      debugPrint('App initialized successfully');
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
          TextButton(
            onPressed: () {
              Get.back();
              // Optionally exit the app
              // SystemNavigator.pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Initializing secure vault...',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MyApp();
  }
}