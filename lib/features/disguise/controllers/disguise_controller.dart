// lib/features/disguise/controllers/disguise_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/disguise_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../to-do/presentation/controllers/todo_controller.dart';
import '../../to-do/data/models/todo_model.dart';

class DisguiseController extends GetxController {
  final DisguiseService _disguiseService = DisguiseService();

  final RxBool isDisguiseMode = false.obs;
  final RxString fakeErrorMessage = ''.obs;
  final RxBool isVaultLocked = true.obs;

  // Secret gesture detection
  final List<String> _secretPattern = [
    'up',
    'up',
    'down',
    'down',
    'left',
    'right',
  ];
  final List<String> _currentPattern = [];

  @override
  void onInit() {
    super.onInit();
    _checkDisguiseMode();
  }

  @override
  void onReady() {
    super.onReady();
    _addDecoyTasks();
  }

  Future<void> _checkDisguiseMode() async {
    isDisguiseMode.value = await _disguiseService.isDisguiseMode();
  }

  /// Show fake error message to maintain disguise
  void showFakeError() {
    fakeErrorMessage.value = 'Feature not available in free version';
    Get.snackbar(
      'Upgrade Required',
      fakeErrorMessage.value,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show fake loading when trying to access hidden features
  void showFakeLoading() {
    Get.dialog(
      AlertDialog(
        title: const Text('Upgrading...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Please wait while we upgrade your account...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      barrierDismissible: false,
    );

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen ?? false) {
        Get.back();
        showFakeError();
      }
    });
  }

  /// Add decoy tasks to make the app look legitimate
  Future<void> _addDecoyTasks() async {
    if (!isDisguiseMode.value) return;

    // Wait for TodoController to be registered
    await Future.delayed(const Duration(milliseconds: 500));

    if (Get.isRegistered<TodoController>()) {
      final todoController = Get.find<TodoController>();

      // Only add decoys if no tasks exist (first launch)
      if (todoController.todos.isEmpty) {
        final decoyTasks = [
          Todo.create(
            title: 'Team meeting tomorrow at 3 PM',
            description: 'Discuss Q4 goals and project updates',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            priority: TodoPriority.high,
            category: TodoCategory.work,
          ),
          Todo.create(
            title: 'Buy groceries',
            description: 'Milk, eggs, bread, vegetables, fruits',
            dueDate: DateTime.now().add(const Duration(days: 2)),
            priority: TodoPriority.medium,
            category: TodoCategory.shopping,
          ),
          Todo.create(
            title: 'Call dentist',
            description: 'Schedule annual checkup appointment',
            dueDate: DateTime.now().add(const Duration(days: 5)),
            priority: TodoPriority.medium,
            category: TodoCategory.health,
          ),
          Todo.create(
            title: 'Read book - Atomic Habits',
            description: 'Complete chapters 5-8',
            dueDate: DateTime.now().add(const Duration(days: 3)),
            priority: TodoPriority.low,
            category: TodoCategory.learning,
          ),
          Todo.create(
            title: 'Pay electricity bill',
            description: 'Due date approaching',
            dueDate: DateTime.now().add(const Duration(days: 7)),
            priority: TodoPriority.high,
            category: TodoCategory.personal,
          ),
          Todo.create(
            title: 'Exercise - 30 min cardio',
            description: 'Don\'t skip today!',
            dueDate: DateTime.now(),
            priority: TodoPriority.medium,
            category: TodoCategory.health,
          ),
          Todo.create(
            title: 'Review weekly budget',
            description: 'Check expenses and savings goals',
            dueDate: DateTime.now().add(const Duration(days: 6)),
            priority: TodoPriority.medium,
            category: TodoCategory.personal,
          ),
        ];

        for (var task in decoyTasks) {
          await todoController.addTodo(task);
        }

        debugPrint('✅ Added ${decoyTasks.length} decoy tasks for disguise');
      }
    }
  }

  /// Record secret gesture for vault access
  void recordSecretGesture(String direction) {
    _currentPattern.add(direction);

    // Keep only last N gestures (pattern length)
    while (_currentPattern.length > _secretPattern.length) {
      _currentPattern.removeAt(0);
    }

    // Check if pattern matches
    bool matches = true;
    for (int i = 0; i < _currentPattern.length; i++) {
      if (_currentPattern[i] != _secretPattern[i]) {
        matches = false;
        break;
      }
    }

    if (matches && _currentPattern.length == _secretPattern.length) {
      _currentPattern.clear();
      _onSecretGestureDetected();
    }
  }

  void _onSecretGestureDetected() {
    if (!isVaultLocked.value) return;

    // Show PIN entry to access vault
    Get.toNamed('/lock-screen', arguments: {'returnToVault': true});
  }

  /// Long press on FAB to access vault (3 seconds)
  void onFabLongPress() {
    HapticFeedback.heavyImpact();

    // Show a fake message first to maintain disguise
    Get.snackbar(
      'Premium Feature',
      'Checking subscription status...',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(milliseconds: 800),
      snackPosition: SnackPosition.BOTTOM,
    );

    // After short delay, show PIN entry
    Future.delayed(const Duration(milliseconds: 800), () {
      if (isVaultLocked.value) {
        // Show PIN entry with vault intent
        Get.toNamed('/lock-screen', arguments: {'returnToVault': true});
      } else {
        // Direct to vault
        Get.toNamed('/vault');
      }
    });
  }

  /// Double tap on empty area to trigger secret menu
  void onDoubleTapSecret() {
    HapticFeedback.lightImpact();

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Secret Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.blue),
                title: const Text('Access Secure Vault'),
                subtitle: const Text('Enter PIN to access hidden files'),
                onTap: () {
                  Get.back();
                  onFabLongPress();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Reset Disguise Data'),
                subtitle: const Text('Add fresh decoy tasks'),
                onTap: () {
                  Get.back();
                  _resetDecoyTasks();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('Clear All Tasks'),
                subtitle: const Text('Remove all decoy tasks'),
                onTap: () {
                  Get.back();
                  _confirmClearTasks();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text('About Disguise Mode'),
                subtitle: const Text('Version 1.0.0 - Hidden Vault'),
                onTap: () {
                  Get.back();
                  _showAboutDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetDecoyTasks() async {
    if (Get.isRegistered<TodoController>()) {
      final todoController = Get.find<TodoController>();

      // Keep only completed tasks as they look natural
      final completedTasks = todoController.todos
          .where((t) => t.isCompleted)
          .toList();
      final otherTasks = todoController.todos
          .where((t) => !t.isCompleted)
          .toList();

      // Delete non-completed decoy tasks
      for (var task in otherTasks) {
        await todoController.deleteTodoById(task.id);
      }

      // Add fresh decoys
      await _addDecoyTasks();

      Get.snackbar(
        'Refreshed',
        'Added fresh sample tasks',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _confirmClearTasks() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear All Tasks?'),
        content: const Text(
          'This will remove all your tasks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (result == true && Get.isRegistered<TodoController>()) {
      final todoController = Get.find<TodoController>();
      final tasksToDelete = todoController.todos.toList();

      for (var task in tasksToDelete) {
        await todoController.deleteTodoById(task.id);
      }

      // Add fresh decoys again
      await _addDecoyTasks();

      Get.snackbar(
        'Cleared',
        'All tasks have been reset',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Disguise Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This app appears as a simple task manager.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔐 Hidden Features:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Long press + button for 3 seconds'),
                  Text('• Double tap empty area in Settings'),
                  Text('• Secret gesture: ↑↑↓↓←→'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Note:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('No one will know about the hidden vault'),
                  Text('PIN protects your sensitive data'),
                  Text('Files are encrypted for security'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Unlock vault (called after successful PIN entry)
  void unlockVault() {
    isVaultLocked.value = false;
    // Navigate to vault
    Get.offAllNamed('/vault');
  }

  /// Lock vault (called when app goes to background or timeout)
  void lockVault() {
    isVaultLocked.value = true;
  }

  /// Check if user can access vault
  bool get canAccessVault => !isVaultLocked.value;

  /// Simulate app crash (for advanced disguise)
  void simulateCrash() {
    Get.dialog(
      AlertDialog(
        title: const Text('App Error'),
        content: const Text(
          'The application has encountered an error and needs to restart.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Just close the dialog - it's a fake crash
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Fake "Pro" upgrade screen
  void showFakeUpgradeScreen() {
    Get.bottomSheet(
      Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.star, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Pro',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get access to premium features',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(Icons.cloud_queue, 'Cloud Sync'),
            _buildFeatureRow(Icons.palette, 'Custom Themes'),
            _buildFeatureRow(Icons.backup, 'Auto Backup'),
            _buildFeatureRow(Icons.share, 'Share Notes'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Get.back();
                showFakeError();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Upgrade Now', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Not now',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
