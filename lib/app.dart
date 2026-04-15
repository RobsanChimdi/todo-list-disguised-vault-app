// lib/app.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/disguise/controllers/disguise_controller.dart';
import 'features/notebook/presentation/controllers/note_controller.dart';
import 'features/vault/presentation/controllers/vault_controller.dart';
import 'features/notebook/data/repositories/note_repository.dart';
import 'features/vault/data/repositories/vault_repository.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/constants/app_strings.dart';
import 'config/theme.dart';
import 'routes/app_routes.dart';
import 'routes/app_pages.dart';
import 'features/vault/data/models/vault_item_model_adapter.dart';

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
      initialRoute: AppRoutes.notebook, // Change this to notebook
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const NotFoundScreen(),
        transition: Transition.fade,
      ),
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
      // Register Hive adapter
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(VaultItemModelAdapter());
        print('✅ Registered VaultItemModelAdapter');
      }

      // Initialize services
      final localStorage = LocalStorageService();
      await localStorage.init();
      Get.put<LocalStorageService>(localStorage);

      final secureStorage = SecureStorageService();
      Get.put<SecureStorageService>(secureStorage);

      // Initialize repositories
      final noteRepository = NoteRepository(localStorage);
      final vaultRepository = VaultRepository(localStorage);
      Get.put<NoteRepository>(noteRepository);
      Get.put<VaultRepository>(vaultRepository);

      // Initialize controllers
      Get.put<AuthController>(AuthController());
      Get.put<DisguiseController>(DisguiseController());
      Get.put<NoteController>(NoteController(noteRepository));
      Get.put<VaultController>(VaultController(vaultRepository));

      // Load initial data
      await Get.find<NoteController>().loadNotes();
      await Get.find<VaultController>().loadItems();

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ App initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
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

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'The requested page does not exist',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed(AppRoutes.notebook),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
