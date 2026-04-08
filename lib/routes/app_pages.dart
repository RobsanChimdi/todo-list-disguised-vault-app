// lib/routes/app_pages.dart

import 'package:get/get.dart';
import 'app_routes.dart';
import '../features/notebook/presentation/screens/notebook_home_screen.dart';
import '../features/notebook/presentation/screens/add_edit_note_screen.dart';
import '../features/notebook/presentation/screens/note_detail_screen.dart';
import '../features/auth/presentation/screens/set_pin_screen.dart';
import '../features/auth/presentation/screens/lock_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/vault/presentation/screens/vault_home_screen.dart';
import '../features/vault/presentation/screens/file_viewer_screen.dart';
import '../features/vault/presentation/screens/upload_screen.dart';
import '../features/notebook/presentation/controllers/note_controller.dart';
import '../features/vault/presentation/controllers/vualt_controller.dart'; 
import '../features/auth/presentation/controllers/auth_controller.dart';

class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.notebook,
      page: () => const NotebookHomeScreen(),
      transition: Transition.fade,
      binding: NotebookBinding(),
    ),
    GetPage(
      name: AppRoutes.addNote,
      page: () => const AddEditNoteScreen(),
      transition: Transition.rightToLeft,
      binding: NoteBinding(),
    ),
    GetPage(
      name: AppRoutes.editNote,
      page: () => const AddEditNoteScreen(),
      transition: Transition.rightToLeft,
      binding: NoteBinding(),
    ),
    GetPage(
      name: AppRoutes.noteDetail,
      page: () => NoteDetailScreen(note: Get.arguments['note']),
      transition: Transition.rightToLeft,
      binding: NoteBinding(),
    ),
    GetPage(
      name: AppRoutes.setPin,
      page: () => const SetPinScreen(),
      transition: Transition.rightToLeft,
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.lockScreen,
      page: () => const LockScreen(),
      transition: Transition.fade,
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.rightToLeft,
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.vault,
      page: () => const VaultHomeScreen(),
      transition: Transition.rightToLeft,
      binding: VaultBinding(),
    ),
    GetPage(
      name: AppRoutes.fileViewer,
      page: () => FileViewerScreen(), // Removed 'const' since it needs parameters via Get.arguments
      transition: Transition.fade,
      binding: VaultBinding(),
    ),
    GetPage(
      name: AppRoutes.uploadFile,
      page: () => const UploadScreen(),
      transition: Transition.upToDown, // FIXED: changed from 'bottomToTop' to 'upToDown'
      binding: VaultBinding(),
    ),
  ];
}

// Bindings for dependency injection
class NotebookBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NoteController>()) {
      Get.lazyPut<NoteController>(() => Get.find<NoteController>());
    }
  }
}

class NoteBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NoteController>()) {
      Get.lazyPut<NoteController>(() => Get.find<NoteController>());
    }
  }
}

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => Get.find<AuthController>());
    }
  }
}

class VaultBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<VaultController>()) {
      Get.lazyPut<VaultController>(() => Get.find<VaultController>());
    }
  }
}