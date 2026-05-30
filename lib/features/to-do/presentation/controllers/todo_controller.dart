// lib/features/todo/presentation/controllers/todo_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/todo_repository.dart';
import '../../data/models/todo_model.dart';

class TodoController extends GetxController {
  final TodoRepository _repository;

  final RxList<Todo> _todos = <Todo>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // Filter and sort state - Initialize with default values
  final RxString _currentFilter = ''.obs;
  final RxString _currentSortBy = ''.obs;
  final RxList<Todo> _filteredTodos = <Todo>[].obs;
  final RxString _searchQuery = ''.obs;

  // ADD THESE TWO LINES - Search UI state
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;

  TodoController(this._repository) {
    // Initialize default sort
    _currentSortBy.value = 'date_desc';
    loadTodos();
  }

  // Getters with safe null handling
  List<Todo> get todos => _todos.value ?? [];
  bool get isLoading => _isLoading.value;
  String? get error => _error.value.isEmpty ? null : _error.value;

  // Filtered and sorted getters
  List<Todo> get pendingTodos {
    final allTodos = _getFilteredAndSortedTodos();
    return allTodos.where((t) => !t.isCompleted && !t.isArchived).toList();
  }

  List<Todo> get completedTodos {
    return (_todos.value ?? [])
        .where((t) => t.isCompleted && !t.isArchived)
        .toList();
  }

  List<Todo> get importantTodos {
    return (_todos.value ?? [])
        .where((t) => t.isImportant && !t.isCompleted && !t.isArchived)
        .toList();
  }

  List<Todo> get overdueTodos {
    return (_todos.value ?? [])
        .where((t) => t.isOverdue && !t.isCompleted && !t.isArchived)
        .toList();
  }

  List<Todo> get todayTodos {
    return (_todos.value ?? [])
        .where((t) => t.isDueToday && !t.isCompleted && !t.isArchived)
        .toList();
  }

  double get completionRate {
    final todosList = _todos.value ?? [];
    if (todosList.isEmpty) return 0;
    final completed = todosList
        .where((t) => t.isCompleted && !t.isArchived)
        .length;
    final total = todosList.where((t) => !t.isArchived).length;
    return total == 0 ? 0 : completed / total;
  }

  int get totalTodos {
    return (_todos.value ?? []).where((t) => !t.isArchived).length;
  }

  int get completedTodosCount {
    return (_todos.value ?? [])
        .where((t) => t.isCompleted && !t.isArchived)
        .length;
  }

  String get currentFilter => _currentFilter.value;
  String get currentSortBy => _currentSortBy.value;

  // Private helper method to apply filters and sorting
  List<Todo> _getFilteredAndSortedTodos() {
    // Safe check - return empty list if todos is null or empty
    final todosList = _todos.value;
    if (todosList == null || todosList.isEmpty) {
      return [];
    }

    List<Todo> result;

    // Apply search filter if active
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      result = todosList
          .where(
            (todo) =>
                todo.title.toLowerCase().contains(query) ||
                todo.description.toLowerCase().contains(query) ||
                todo.tags.any((tag) => tag.toLowerCase().contains(query)),
          )
          .toList();
    }
    // Apply custom filter if active
    else if (_filteredTodos.isNotEmpty) {
      result = List.from(_filteredTodos.value);
    }
    // Otherwise use all todos
    else {
      result = List.from(todosList);
    }

    // Apply sorting
    result = _applySorting(result);

    return result;
  }

  List<Todo> _applySorting(List<Todo> todos) {
    if (todos.isEmpty) return todos;

    final sortBy = _currentSortBy.value;

    switch (sortBy) {
      case 'date_desc':
        todos.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
        break;
      case 'date_asc':
        todos.sort((a, b) => a.lastEdited.compareTo(b.lastEdited));
        break;
      case 'title_asc':
        todos.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'title_desc':
        todos.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'priority':
        todos.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case 'due_date':
        todos.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      default:
        todos.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
    }
    return todos;
  }

  // ==================== SEARCH UI METHODS ====================

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      clearSearch();
    }
  }

  // Search methods
  void search(String query) {
    searchQuery.value = query;
    _searchQuery.value = query;
    update(); // Refresh UI
  }

  void clearSearch() {
    searchQuery.value = '';
    _searchQuery.value = '';
    update();
  }

  // Filter methods
  void setFilter(bool Function(Todo) filterFunction) {
    final todosList = _todos.value ?? [];
    _filteredTodos.value = todosList.where(filterFunction).toList();
    update();
  }

  void clearFilter() {
    _filteredTodos.clear();
    _currentFilter.value = '';
    update();
  }

  // Convenience filter methods
  void filterByImportant() {
    setFilter(
      (todo) => todo.isImportant && !todo.isCompleted && !todo.isArchived,
    );
    _currentFilter.value = 'important';
    _showSnackbar('Showing important tasks');
  }

  void filterByToday() {
    setFilter(
      (todo) => todo.isDueToday && !todo.isCompleted && !todo.isArchived,
    );
    _currentFilter.value = 'today';
    _showSnackbar('Showing tasks due today');
  }

  void filterByThisWeek() {
    final weekFromNow = DateTime.now().add(const Duration(days: 7));
    setFilter((todo) {
      if (todo.dueDate == null) return false;
      return todo.dueDate!.isBefore(weekFromNow) &&
          !todo.isCompleted &&
          !todo.isArchived;
    });
    _currentFilter.value = 'week';
    _showSnackbar('Showing tasks due this week');
  }

  void filterByOverdue() {
    setFilter(
      (todo) => todo.isOverdue && !todo.isCompleted && !todo.isArchived,
    );
    _currentFilter.value = 'overdue';
    _showSnackbar('Showing overdue tasks');
  }

  void filterByAll() {
    clearFilter();
    _showSnackbar('Showing all tasks');
  }

  // Sort methods
  void sortBy(String sortBy) {
    _currentSortBy.value = sortBy;
    update();

    String message;
    switch (sortBy) {
      case 'date_desc':
        message = 'Sorted by newest first';
        break;
      case 'date_asc':
        message = 'Sorted by oldest first';
        break;
      case 'title_asc':
        message = 'Sorted A to Z';
        break;
      case 'title_desc':
        message = 'Sorted Z to A';
        break;
      case 'priority':
        message = 'Sorted by priority';
        break;
      case 'due_date':
        message = 'Sorted by due date';
        break;
      default:
        message = 'Sorting applied';
    }
    _showSnackbar(message);
  }

  // Get filtered pending tasks (for display)
  List<Todo> getFilteredPendingTasks() {
    return pendingTodos;
  }

  // Clear all completed tasks
  Future<void> clearCompleted() async {
    final completed = (_todos.value ?? [])
        .where((t) => t.isCompleted && !t.isArchived)
        .toList();
    for (var todo in completed) {
      await _repository.deleteTodo(todo.id);
    }
    await loadTodos();
    _showSnackbar('Cleared ${completed.length} completed tasks');
  }

  // Clear all tasks (for disguise reset)
  Future<void> clearAllTasks() async {
    for (var todo in (_todos.value ?? [])) {
      await _repository.deleteTodo(todo.id);
    }
    await loadTodos();
    _showSnackbar('All tasks cleared');
  }

  // Export tasks as text
  String exportTasksAsText() {
    final todosList = _todos.value ?? [];
    if (todosList.isEmpty) {
      return 'No tasks to export';
    }

    String exportText = 'My Tasks Export\n';
    exportText += '=' * 40 + '\n';
    exportText += 'Generated: ${DateTime.now()}\n\n';

    // Pending tasks
    exportText += 'PENDING TASKS:\n';
    exportText += '-' * 20 + '\n';
    for (var task in pendingTodos) {
      exportText += '☐ ${task.title}\n';
      if (task.dueDate != null) {
        exportText += '   📅 Due: ${_formatDate(task.dueDate!)}\n';
      }
      if (task.description.isNotEmpty) {
        exportText += '   📝 ${task.description}\n';
      }
      exportText += '\n';
    }

    // Completed tasks
    exportText += '\nCOMPLETED TASKS:\n';
    exportText += '-' * 20 + '\n';
    for (var task in completedTodos) {
      exportText += '✓ ${task.title}\n';
      exportText += '\n';
    }

    // Statistics
    exportText += '\nSTATISTICS:\n';
    exportText += '-' * 20 + '\n';
    exportText += 'Total Tasks: ${totalTodos}\n';
    exportText += 'Completed: ${completedTodosCount}\n';
    exportText += 'Pending: ${pendingTodos.length}\n';
    exportText +=
        'Completion Rate: ${(completionRate * 100).toStringAsFixed(1)}%\n';

    return exportText;
  }

  // Update UI (notify listeners)
  void updateUI() {
    update();
  }

  // Private helper methods
  void _showSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
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
    return '${date.month}/${date.day}/${date.year}';
  }

  // ==================== EXISTING METHODS ====================

  Future<void> loadTodos() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final loadedTodos = await _repository.getAllTodos();
      _todos.value = loadedTodos;
      _todos.value.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
      // Clear any existing filters after reload
      clearFilter();
      _searchQuery.value = '';
      searchQuery.value = '';
      isSearching.value = false;
    } catch (e) {
      _error.value = e.toString();
    }

    _isLoading.value = false;
  }

  Future<Todo?> getTodoById(String id) async {
    try {
      return await _repository.getTodoById(id);
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  Future<void> addTodo(Todo todo) async {
    await _repository.saveTodo(todo);
    await loadTodos();
  }

  Future<void> updateTodo(Todo todo) async {
    await _repository.updateTodo(todo);
    await loadTodos();
  }

  Future<void> deleteTodoById(String id) async {
    await _repository.deleteTodo(id);
    await loadTodos();
  }

  Future<void> toggleComplete(Todo todo) async {
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await updateTodo(updated);
  }

  Future<void> toggleImportant(Todo todo) async {
    final updated = todo.copyWith(isImportant: !todo.isImportant);
    await updateTodo(updated);
  }

  Future<void> toggleArchive(Todo todo) async {
    final updated = todo.copyWith(isArchived: !todo.isArchived);
    await updateTodo(updated);
  }

  Future<void> toggleSubTask(Todo todo, int subTaskIndex) async {
    final newSubTasksCompleted = List<bool>.from(todo.subTasksCompleted);
    newSubTasksCompleted[subTaskIndex] = !newSubTasksCompleted[subTaskIndex];

    final updated = todo.copyWith(subTasksCompleted: newSubTasksCompleted);
    await updateTodo(updated);
  }

  Future<List<Todo>> searchTodos(String query) async {
    return await _repository.searchTodos(query);
  }
}
