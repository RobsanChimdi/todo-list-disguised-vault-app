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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register VaultItemModel adapter
  Hive.registerAdapter(VaultItemModelAdapter());

  // Initialize LocalStorageService
  final localStorage = LocalStorageService();
  await localStorage.init();

  runApp(const MyApp());
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    print('InitialBinding: Registering core services...');

    // Register LocalStorageService
    if (!Get.isRegistered<LocalStorageService>()) {
      Get.put(LocalStorageService(), permanent: true);
    }

    // Register AuthController globally
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
    print('AuthController registered: ${Get.isRegistered<AuthController>()}');
    print('VaultController registered: ${Get.isRegistered<VaultController>()}');
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
