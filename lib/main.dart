// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final localStorage = LocalStorageService();
  await localStorage.init();

  final secureStorage = SecureStorageService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: localStorage),
        Provider.value(value: secureStorage),
        // Add more providers as needed
      ],
      child: MyApp(),
    ),
  );
}
