import 'package:flutter/material.dart';
import 'core/services/local_storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService().init(); // 🔥 initialize Hive

  runApp(MyApp());
}
