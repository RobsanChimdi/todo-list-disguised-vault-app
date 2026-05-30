// lib/routes/app_pages.dart

import 'package:get/get.dart';
import 'app_routes.dart';
import '../features/to-do/presentation/screens/todo_home_screen.dart';
import '../features/to-do/presentation/screens/add_edit_todo_screen.dart';
import '../features/to-do/presentation/screens/todo_detail_screen.dart';
import '../features/auth/presentation/screens/set_pin_screen.dart';
import '../features/auth/presentation/screens/lock_screen.dart';
import '../features/vault/presentation/screens/vault_home_screen.dart';
import '../features/vault/presentation/screens/file_viewer_screen.dart';
import '../features/vault/presentation/screens/upload_screen.dart';

class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.todo,
      page: () => const TodoHomeScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.addTodo,
      page: () => const AddEditTodoScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editTodo,
      page: () => const AddEditTodoScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.todoDetail,
      page: () => TodoDetailScreen(todo: Get.arguments['todo']),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.setPin,
      page: () => const SetPinScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.lockScreen,
      page: () => const LockScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.vault,
      page: () => const VaultHomeScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.fileViewer,
      page: () => const FileViewerScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.uploadFile,
      page: () => const UploadScreen(),
      transition: Transition.upToDown,
    ),
  ];
}
