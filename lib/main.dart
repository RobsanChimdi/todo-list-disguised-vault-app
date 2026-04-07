// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app
  runApp(const AppRoot());
}
