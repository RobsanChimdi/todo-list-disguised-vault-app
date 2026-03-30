// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize any pre-app services here
  await _initializeServices();

  runApp(const AppRoot());
}

Future<void> _initializeServices() async {
  // Add any pre-initialization services here
  // For example, crash reporting, analytics, etc.
}
