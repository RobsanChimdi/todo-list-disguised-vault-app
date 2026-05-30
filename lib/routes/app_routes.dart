// lib/routes/app_routes.dart

import 'package:get/get.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String todo = '/todo';
  static const String addTodo = '/add-todo';
  static const String editTodo = '/edit-todo';
  static const String todoDetail = '/todo-detail';
  static const String setPin = '/set-pin';
  static const String lockScreen = '/lock-screen';
  static const String login = '/login';
  static const String vault = '/vault';
  static const String fileViewer = '/file-viewer';
  static const String uploadFile = '/upload-file';

  // Navigation helper methods
  static Future<T?> toTodo<T>() => Get.toNamed<T>(todo) ?? Future.value(null);
  static Future<T?> toAddTodo<T>() =>
      Get.toNamed<T>(addTodo) ?? Future.value(null);

  static Future<T?> toEditTodo<T>({required String todoId}) =>
      Get.toNamed<T>(editTodo, arguments: {'id': todoId}) ?? Future.value(null);

  static Future<T?> toTodoDetail<T>({required String todoId}) =>
      Get.toNamed<T>(todoDetail, arguments: {'id': todoId}) ??
      Future.value(null);

  static Future<T?> toSetPin<T>() =>
      Get.toNamed<T>(setPin) ?? Future.value(null);
  static Future<T?> toLockScreen<T>() =>
      Get.toNamed<T>(lockScreen) ?? Future.value(null);
  static Future<T?> toLogin<T>() => Get.toNamed<T>(login) ?? Future.value(null);
  static Future<T?> toVault<T>() => Get.toNamed<T>(vault) ?? Future.value(null);

  static Future<T?> toFileViewer<T>({
    required String filePath,
    required String fileName,
  }) =>
      Get.toNamed<T>(
        fileViewer,
        arguments: {'path': filePath, 'name': fileName},
      ) ??
      Future.value(null);

  static Future<T?> toUploadFile<T>() =>
      Get.toNamed<T>(uploadFile) ?? Future.value(null);

  // Navigation with replacement
  static Future<T?> offAllToTodo<T>() =>
      Get.offAllNamed<T>(todo) ?? Future.value(null);
  static Future<T?> offAllToLogin<T>() =>
      Get.offAllNamed<T>(login) ?? Future.value(null);
  static Future<T?> offAllToVault<T>() =>
      Get.offAllNamed<T>(vault) ?? Future.value(null);

  // Navigation with replacement and data
  static Future<T?> offAllToTodoWithData<T>(dynamic data) =>
      Get.offAllNamed<T>(todo, arguments: data) ?? Future.value(null);
  static Future<T?> offAllToVaultWithData<T>(dynamic data) =>
      Get.offAllNamed<T>(vault, arguments: data) ?? Future.value(null);

  // Navigate and remove current route
  static Future<T?> offToTodo<T>() =>
      Get.offNamed<T>(todo) ?? Future.value(null);
  static Future<T?> offToVault<T>() =>
      Get.offNamed<T>(vault) ?? Future.value(null);
  static Future<T?> offToLogin<T>() =>
      Get.offNamed<T>(login) ?? Future.value(null);

  // Go back with result
  static void goBack<T>([T? result]) => Get.back(result: result);
  static void goBackWithResult<T>(T result) => Get.back(result: result);

  // Pop until specific route
  static void popUntilTodo() =>
      Get.until((route) => route.settings.name == todo);
  static void popUntilVault() =>
      Get.until((route) => route.settings.name == vault);

  // Pop multiple routes
  static void popTwice() {
    Get.back();
    Get.back();
  }

  static void popThrice() {
    Get.back();
    Get.back();
    Get.back();
  }

  // Check if a route is current
  static bool isCurrentRoute(String routeName) => Get.currentRoute == routeName;

  // Get current route
  static String get currentRoute => Get.currentRoute;

  // Get navigation arguments
  static T? getArguments<T>() => Get.arguments as T?;

  // Get typed arguments with default
  static T getTypedArguments<T>(T defaultValue) {
    final args = Get.arguments;
    if (args != null && args is T) {
      return args;
    }
    return defaultValue;
  }
}
