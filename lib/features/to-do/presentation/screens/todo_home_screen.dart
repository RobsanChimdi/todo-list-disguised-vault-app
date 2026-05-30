// lib/features/todo/presentation/screens/todo_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../controllers/todo_controller.dart';
import '../../data/models/todo_model.dart';
import 'add_edit_todo_screen.dart';
import 'todo_detail_screen.dart';

class TodoHomeScreen extends StatelessWidget {
  const TodoHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TodoController? controller;
    try {
      controller = Get.find<TodoController>();
    } catch (e) {
      print('TodoController not found yet: $e');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(controller, context),
        body: _buildBody(controller, context),
        floatingActionButton: _buildFloatingActionButton(controller, context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    TodoController controller,
    BuildContext context,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'My Tasks',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: Colors.black87,
        ),
      ),
      centerTitle: false,
      actions: [
        // Search Button - opens search bar
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _toggleSearch(controller),
          tooltip: 'Search Tasks',
        ),

        // Sort Button
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort, color: Colors.black87),
          tooltip: 'Sort Tasks',
          onSelected: (value) => _sortTasks(controller, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'date_desc',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18),
                  SizedBox(width: 12),
                  Text('Newest First'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'date_asc',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18),
                  SizedBox(width: 12),
                  Text('Oldest First'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'title_asc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha, size: 18),
                  SizedBox(width: 12),
                  Text('A to Z'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'title_desc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha, size: 18),
                  SizedBox(width: 12),
                  Text('Z to A'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'priority',
              child: Row(
                children: [
                  Icon(Icons.flag, size: 18),
                  SizedBox(width: 12),
                  Text('Priority'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'due_date',
              child: Row(
                children: [
                  Icon(Icons.event, size: 18),
                  SizedBox(width: 12),
                  Text('Due Date'),
                ],
              ),
            ),
          ],
        ),

        // Filter Button
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, color: Colors.black87),
          tooltip: 'Filter Tasks',
          onSelected: (value) => _filterTasks(controller, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'all',
              child: Row(
                children: [
                  Icon(Icons.list, size: 18),
                  SizedBox(width: 12),
                  Text('All Tasks'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'important',
              child: Row(
                children: [
                  Icon(Icons.flag, size: 18, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Important'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'today',
              child: Row(
                children: [
                  Icon(Icons.today, size: 18, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Due Today'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'week',
              child: Row(
                children: [
                  Icon(Icons.weekend, size: 18, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Due This Week'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'overdue',
              child: Row(
                children: [
                  Icon(Icons.warning, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Overdue'),
                ],
              ),
            ),
          ],
        ),

        // Settings Button (Secret Vault Access)
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black87),
          onPressed: () => _showSettingsMenu(controller, context),
          tooltip: 'Settings',
        ),

        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            // Search Bar (shown when searching)
            Obx(
              () => controller.isSearching.value
                  ? _buildSearchBar(controller)
                  : const SizedBox.shrink(),
            ),
            // Stats Bar
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.assignment,
                      label: 'Total',
                      value: '${controller.totalTodos}',
                      color: Colors.blue,
                    ),
                    _buildStatItem(
                      icon: Icons.check_circle,
                      label: 'Completed',
                      value: '${controller.completedTodosCount}',
                      color: Colors.green,
                    ),
                    _buildStatItem(
                      icon: Icons.pending,
                      label: 'Pending',
                      value: '${controller.pendingTodos.length}',
                      color: Colors.orange,
                    ),
                    _buildStatItem(
                      icon: Icons.flag,
                      label: 'Important',
                      value: '${controller.importantTodos.length}',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            // Tab Bar
            const TabBar(
              indicatorColor: Color(0xFF6366F1),
              labelColor: Color(0xFF6366F1),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(TodoController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => controller.clearSearch(),
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => controller.search(value),
            ),
          ),
          TextButton(
            onPressed: () => _toggleSearch(controller),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleSearch(TodoController controller) {
    controller.toggleSearch();
    if (!controller.isSearching.value) {
      controller.clearSearch();
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  void _sortTasks(TodoController controller, String sortBy) {
    controller.sortBy(sortBy);

    String message;
    switch (sortBy) {
      case 'date_desc':
        message = 'Newest first';
        break;
      case 'date_asc':
        message = 'Oldest first';
        break;
      case 'title_asc':
        message = 'A to Z';
        break;
      case 'title_desc':
        message = 'Z to A';
        break;
      case 'priority':
        message = 'By priority';
        break;
      case 'due_date':
        message = 'By due date';
        break;
      default:
        message = 'Sorting applied';
    }

    Get.snackbar(
      'Sorted',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void _filterTasks(TodoController controller, String filterBy) {
    switch (filterBy) {
      case 'important':
        controller.filterByImportant();
        break;
      case 'today':
        controller.filterByToday();
        break;
      case 'week':
        controller.filterByThisWeek();
        break;
      case 'overdue':
        controller.filterByOverdue();
        break;
      case 'all':
      default:
        controller.filterByAll();
        break;
    }

    Get.snackbar(
      'Filtered',
      'Showing ${filterBy} tasks',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void _showSettingsMenu(TodoController controller, BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Clear completed tasks
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_sweep, color: Colors.green),
              ),
              title: const Text('Clear Completed'),
              subtitle: const Text('Remove all completed tasks'),
              onTap: () {
                Navigator.pop(context);
                _confirmClearCompleted(controller);
              },
            ),

            // Export data
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share, color: Colors.blue),
              ),
              title: const Text('Export Tasks'),
              subtitle: const Text('Share your tasks as text'),
              onTap: () {
                Navigator.pop(context);
                _exportTasks(controller);
              },
            ),

            // About
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info, color: Colors.grey),
              ),
              title: const Text('About'),
              subtitle: const Text('Version 1.0.0'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmClearCompleted(TodoController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Completed Tasks'),
        content: const Text(
          'Are you sure you want to delete all completed tasks? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearCompleted();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportTasks(TodoController controller) {
    final exportText = controller.exportTasksAsText();

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: exportText));
    Get.snackbar(
      'Exported',
      'Tasks copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Manager Pro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            const Text(
              'A powerful task management app to help you stay organized and productive.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💡 Tip: Long press any task for secure access',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _onTaskLongPress(Todo todo) {
    HapticFeedback.heavyImpact();

    // Show fake message
    Get.snackbar(
      'Secure Access',
      'Authenticating...',
      backgroundColor: Colors.purple,
      colorText: Colors.white,
      duration: const Duration(milliseconds: 800),
      snackPosition: SnackPosition.BOTTOM,
    );

    // After delay, navigate to PIN screen for vault access
    Future.delayed(const Duration(milliseconds: 800), () {
      Get.toNamed(
        '/lock-screen',
        arguments: {'returnToVault': true, 'taskId': todo.id},
      );
    });
  }

  Widget _buildBody(TodoController controller, BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final pendingTodos = controller.getFilteredPendingTasks();
      final completedTodos = controller.completedTodos;

      return TabBarView(
        children: [
          // Pending Tasks Tab
          pendingTodos.isEmpty
              ? _buildEmptyState('No pending tasks', 'Tap + to create a task')
              : RefreshIndicator(
                  onRefresh: () => controller.loadTodos(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingTodos.length,
                    itemBuilder: (ctx, index) {
                      final todo = pendingTodos[index];
                      return _buildTodoCard(todo, controller, ctx);
                    },
                  ),
                ),

          // Completed Tasks Tab
          completedTodos.isEmpty
              ? _buildEmptyState(
                  'No completed tasks',
                  'Complete a task to see it here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: completedTodos.length,
                  itemBuilder: (ctx, index) {
                    final todo = completedTodos[index];
                    return _buildCompletedTodoCard(todo, controller, ctx);
                  },
                ),
        ],
      );
    });
  }

  Widget _buildTodoCard(
    Todo todo,
    TodoController controller,
    BuildContext context,
  ) {
    return GestureDetector(
      onLongPress: () => _onTaskLongPress(todo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Color(todo.backgroundColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TodoDetailScreen(todo: todo)),
              );
              if (result != null) {
                controller.loadTodos();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Checkbox for completion
                      GestureDetector(
                        onTap: () => controller.toggleComplete(todo),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: todo.isCompleted
                                ? Colors.green
                                : Colors.transparent,
                            border: Border.all(
                              color: todo.isCompleted
                                  ? Colors.green
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: todo.isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (todo.isImportant)
                        const Icon(Icons.flag, size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          todo.priority.toString().split('.').last,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getPriorityColor(todo.priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (todo.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      todo.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (todo.dueDate != null)
                        _buildChip(
                          icon: Icons.calendar_today,
                          label: _formatDate(todo.dueDate!),
                          color: todo.isOverdue ? Colors.red : Colors.grey,
                        ),
                      if (todo.subTasks.isNotEmpty)
                        _buildChip(
                          icon: Icons.checklist,
                          label:
                              '${todo.completedSubTasks}/${todo.subTasks.length}',
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTodoCard(
    Todo todo,
    TodoController controller,
    BuildContext context,
  ) {
    return GestureDetector(
      onLongPress: () => _onTaskLongPress(todo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Color(todo.backgroundColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TodoDetailScreen(todo: todo)),
              );
              if (result != null) {
                controller.loadTodos();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Dismissible(
              key: Key(todo.id),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => controller.deleteTodoById(todo.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Checkbox for completion (shows as checked)
                        GestureDetector(
                          onTap: () => controller.toggleComplete(todo),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            todo.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        if (todo.isImportant)
                          const Icon(
                            Icons.flag,
                            size: 20,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        todo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (todo.dueDate != null)
                          _buildChip(
                            icon: Icons.calendar_today,
                            label: _formatDate(todo.dueDate!),
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(
    TodoController controller,
    BuildContext context,
  ) {
    return GestureDetector(
      onLongPress: () => _onTaskLongPress(Todo.create(title: '')),
      child: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTodoScreen()),
          );
          if (result != null) {
            controller.addTodo(result);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow';
    }
    return DateFormat('MMM dd').format(date);
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return Colors.green;
      case TodoPriority.medium:
        return Colors.blue;
      case TodoPriority.high:
        return Colors.orange;
      case TodoPriority.urgent:
        return Colors.red;
    }
  }
}
