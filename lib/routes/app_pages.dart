// lib/routes/app_pages.dart

import 'package:get/get.dart';
import 'app_routes.dart';
import '../features/notebook/presentation/screens/notebook_home_screen.dart';
import '../features/notebook/presentation/screens/add_edit_note_screen.dart';
import '../features/notebook/presentation/screens/note_detail_screen.dart';
import '../features/auth/presentation/screens/set_pin_screen.dart';
import '../features/auth/presentation/screens/lock_screen.dart';
import '../features/vault/presentation/screens/vault_home_screen.dart';
import '../features/vault/presentation/screens/file_viewer_screen.dart';
import '../features/vault/presentation/screens/upload_screen.dart';
import '../features/notebook/presentation/controllers/note_controller.dart';
import '../features/vault/presentation/controllers/vault_controller.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../../core/services/local_storage_service.dart';
import '../features/notebook/data/repositories/note_repository.dart';
import '../features/vault/data/repositories/vault_repository.dart';

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
      name: AppRoutes.vault,
      page: () => const VaultHomeScreen(),
      transition: Transition.rightToLeft,
      binding: VaultBinding(),
    ),
    GetPage(
      name: AppRoutes.fileViewer,
      page: () => FileViewerScreen(),
      transition: Transition.fade,
      binding: VaultBinding(),
    ),
    GetPage(
      name: AppRoutes.uploadFile,
      page: () => const UploadScreen(),
      transition: Transition.upToDown,
      binding: VaultBinding(),
    ),
  ];
}

class NotebookBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocalStorageService>()) {
      Get.put(LocalStorageService(), permanent: true);
    }

    if (!Get.isRegistered<NoteController>()) {
      Get.lazyPut<NoteController>(() {
        final localStorage = Get.find<LocalStorageService>();
        final repository = NoteRepository(localStorage);
        return NoteController(repository);
      });
    }
  }
}

class NoteBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocalStorageService>()) {
      Get.put(LocalStorageService(), permanent: true);
    }

    if (!Get.isRegistered<NoteController>()) {
      Get.lazyPut<NoteController>(() {
        final localStorage = Get.find<LocalStorageService>();
        final repository = NoteRepository(localStorage);
        return NoteController(repository);
      });
    }
  }
}

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
  }
}

// lib/routes/app_pages.dart - VaultBinding section

class VaultBinding extends Bindings {
  @override
  void dependencies() {
    print('VaultBinding: Starting dependencies registration...');

    // Only register if not already registered (from InitialBinding)
    if (!Get.isRegistered<LocalStorageService>()) {
      print('VaultBinding: Registering LocalStorageService');
      Get.put(LocalStorageService(), permanent: true);
    }

    if (!Get.isRegistered<VaultRepository>()) {
      print('VaultBinding: Registering VaultRepository');
      final localStorage = Get.find<LocalStorageService>();
      Get.put(VaultRepository(localStorage), permanent: true);
    }

    if (!Get.isRegistered<VaultController>()) {
      print('VaultBinding: Registering VaultController');
      final repository = Get.find<VaultRepository>();
      Get.put(VaultController(repository), permanent: true);
    }

    print('VaultBinding: All dependencies registered successfully');
  }
}
