// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart'; // Import AppRoot from your app.dart file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();
    print('✅ Hive initialized');

    // Run the app with AppRoot
    runApp(const AppRoot());
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
