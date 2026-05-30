// lib/features/todo/data/repositories/todo_repository.dart

import '../../../../core/services/local_storage_service.dart';
import '../models/todo_model.dart';

class TodoRepository {
  final LocalStorageService _storageService;

  TodoRepository(this._storageService);

  Future<List<Todo>> getAllTodos() async {
    final todosData = await _storageService.getAllNotes();
    return todosData.map((data) => Todo.fromJson(data)).toList();
  }

  Future<Todo?> getTodoById(String id) async {
    final todoData = await _storageService.getNote(id);
    if (todoData != null) {
      return Todo.fromJson(todoData);
    }
    return null;
  }

  Future<void> saveTodo(Todo todo) async {
    await _storageService.saveNote(todo.toJson());
  }

  Future<void> deleteTodo(String id) async {
    await _storageService.deleteNote(id);
  }

  Future<void> updateTodo(Todo todo) async {
    await _storageService.saveNote(todo.toJson());
  }

  Future<List<Todo>> getImportantTodos() async {
    final todos = await getAllTodos();
    return todos
        .where(
          (todo) => todo.isImportant && !todo.isCompleted && !todo.isArchived,
        )
        .toList();
  }

  Future<List<Todo>> getCompletedTodos() async {
    final todos = await getAllTodos();
    return todos.where((todo) => todo.isCompleted && !todo.isArchived).toList();
  }

  Future<List<Todo>> getArchivedTodos() async {
    final todos = await getAllTodos();
    return todos.where((todo) => todo.isArchived).toList();
  }

  Future<List<Todo>> getOverdueTodos() async {
    final todos = await getAllTodos();
    return todos
        .where(
          (todo) => todo.isOverdue && !todo.isCompleted && !todo.isArchived,
        )
        .toList();
  }

  Future<List<Todo>> getTodosForToday() async {
    final todos = await getAllTodos();
    return todos
        .where(
          (todo) => todo.isDueToday && !todo.isCompleted && !todo.isArchived,
        )
        .toList();
  }

  Future<List<Todo>> searchTodos(String query) async {
    final allTodos = await getAllTodos();

    if (query.isEmpty) return allTodos;

    final lowerQuery = query.toLowerCase();

    return allTodos.where((todo) {
      return todo.title.toLowerCase().contains(lowerQuery) ||
          todo.description.toLowerCase().contains(lowerQuery) ||
          todo.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
