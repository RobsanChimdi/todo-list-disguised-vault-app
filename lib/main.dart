// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/vault/data/models/vault_item_model_adapter.dart';
import 'features/vault/data/models/vault_item_model.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/secure_storage_service.dart';
import 'features/to-do/data/repositories/todo_repository.dart';
import 'features/to-do/presentation/controllers/todo_controller.dart';
import 'features/vault/data/repositories/vault_repository.dart';
import 'features/vault/presentation/controllers/vault_controller.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/disguise/controllers/disguise_controller.dart';
import 'core/services/user_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();
    print('✅ Hive initialized');

    // Register Hive adapter BEFORE anything else
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VaultItemModelAdapter());
      print('✅ Registered VaultItemModelAdapter');
    }

    // Initialize LocalStorageService FIRST
    final localStorage = LocalStorageService();
    await localStorage.init();
    print('✅ LocalStorageService initialized');

    // Register services with GetX BEFORE running app
    Get.put<LocalStorageService>(localStorage, permanent: true);
    Get.put<SecureStorageService>(SecureStorageService(), permanent: true);

    // Initialize repositories
    final todoRepository = TodoRepository(localStorage);
    final vaultRepository = VaultRepository(localStorage);

    Get.put<TodoRepository>(todoRepository, permanent: true);
    Get.put<VaultRepository>(vaultRepository, permanent: true);

    // Initialize controllers - THIS IS CRITICAL
    final todoController = TodoController(todoRepository);
    final vaultController = VaultController(vaultRepository);

    Get.put<TodoController>(todoController, permanent: true);
    Get.put<VaultController>(vaultController, permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<DisguiseController>(DisguiseController(), permanent: true);
    Get.put<UserRepository>(UserRepository(), permanent: true);

    // Load initial data
    await todoController.loadTodos();
    await vaultController.loadItems();

    print('✅ All controllers registered and data loaded');

    // Run the app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('❌ Failed to initialize app: $e');
    print('Stack trace: $stackTrace');

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
                  Text('Error: $e'),
                  const SizedBox(height: 32),
                  ElevatedButton(onPressed: () {}, child: const Text('Exit')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
