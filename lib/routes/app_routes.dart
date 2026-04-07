// lib/routes/app_routes.dart

import 'package:get/get.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String notebook = '/notebook';
  static const String addNote = '/add-note';
  static const String editNote = '/edit-note';
  static const String noteDetail = '/note-detail';
  static const String setPin = '/set-pin';
  static const String lockScreen = '/lock-screen';
  static const String login = '/login';
  static const String vault = '/vault';
  static const String fileViewer = '/file-viewer';
  static const String uploadFile = '/upload-file';

  // Navigation helper methods
  static Future<T?> toNotebook<T>() => Get.toNamed<T>(notebook) ?? Future.value(null);
  static Future<T?> toAddNote<T>() => Get.toNamed<T>(addNote) ?? Future.value(null);
  static Future<T?> toEditNote<T>({required String noteId}) =>
      Get.toNamed<T>(editNote, arguments: {'id': noteId}) ?? Future.value(null);
    static Future<T?> toNoteDetail<T>({required String noteId}) =>
      Get.toNamed<T>(noteDetail, arguments: {'id': noteId}) ?? Future.value(null);
  static Future<T?> toSetPin<T>() => Get.toNamed<T>(setPin) ?? Future.value(null);
  static Future<T?> toLockScreen<T>() => Get.toNamed<T>(lockScreen) ?? Future.value(null);
  static Future<T?> toLogin<T>() => Get.toNamed<T>(login) ?? Future.value(null);
  static Future<T?> toVault<T>() => Get.toNamed<T>(vault) ?? Future.value(null);
  static Future<T?> toFileViewer<T>({
    required String filePath,
    required String fileName,
  }) => Get.toNamed<T>(
    fileViewer,
    arguments: {'path': filePath, 'name': fileName},
  ) ?? Future.value(null);
  static Future<T?> toUploadFile<T>() => Get.toNamed<T>(uploadFile) ?? Future.value(null);

  // Navigation with replacement
  static Future<T?> offAllToNotebook<T>() => Get.offAllNamed<T>(notebook) ?? Future.value(null);
  static Future<T?> offAllToLogin<T>() => Get.offAllNamed<T>(login) ?? Future.value(null);
  static Future<T?> offAllToVault<T>() => Get.offAllNamed<T>(vault) ?? Future.value(null);

  // Go back
  static void goBack<T>([T? result]) => Get.back(result: result);
  static void popUntilNotebook() =>
      Get.until((route) => route.settings.name == notebook);
}