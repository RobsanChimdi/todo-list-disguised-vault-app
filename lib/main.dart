// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'core/services/local_storage_service.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/vault/data/models/vault_item_model.dart';
import 'features/vault/data/repositories/vault_repository.dart';
import 'features/vault/presentation/controllers/vault_controller.dart';
import 'core/services/encryption_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Step 1: Initialize Hive
    await Hive.initFlutter();
    print('✅ Hive initialized');

    // Step 2: Register adapter BEFORE anything else
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VaultItemModelAdapter());
      print('✅ Registered VaultItemModelAdapter (typeId: 1)');
    }

    // Step 3: Initialize storage service
    final localStorage = LocalStorageService();
    await localStorage.init();
    print('✅ Storage service initialized');

    // Step 4: Run app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('❌ Failed to initialize app: $e');
    print('Stack trace: $stackTrace');

    // Show error UI
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Failed to Initialize App',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Please restart the app.'),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Exit the app
                    },
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    print('InitialBinding: Registering core services...');

    // Register LocalStorageService
    if (!Get.isRegistered<LocalStorageService>()) {
      Get.put(LocalStorageService(), permanent: true);
    }

    // Register EncryptionHelper
    if (!Get.isRegistered<EncryptionHelper>()) {
      Get.put(EncryptionHelper(), permanent: true);
    }

    // Register AuthController
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    // Register VaultRepository
    if (!Get.isRegistered<VaultRepository>()) {
      final localStorage = Get.find<LocalStorageService>();
      Get.put(VaultRepository(localStorage), permanent: true);
    }

    // Register VaultController
    if (!Get.isRegistered<VaultController>()) {
      final repository = Get.find<VaultRepository>();
      Get.put(VaultController(repository), permanent: true);
    }

    print('InitialBinding: All services registered');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Secure Vault',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: AppRoutes.notebook,
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
