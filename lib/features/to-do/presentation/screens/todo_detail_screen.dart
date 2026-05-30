// lib/features/todo/presentation/screens/todo_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../data/models/todo_model.dart';
import '../controllers/todo_controller.dart';
import 'add_edit_todo_screen.dart';

class TodoDetailScreen extends StatefulWidget {
  final Todo todo;

  const TodoDetailScreen({Key? key, required this.todo}) : super(key: key);

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late Todo _currentTodo;
  late TodoController _controller;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentTodo = widget.todo;
    _controller = Get.find<TodoController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_currentTodo.backgroundColor),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(_currentTodo.backgroundColor).withOpacity(0.95),
              Color(_currentTodo.backgroundColor).withOpacity(0),
            ],
          ),
        ),
      ),
      title: const Text(''),
      actions: [
        _buildActionButton(
          icon: _currentTodo.isImportant ? Icons.flag : Icons.flag_outlined,
          onPressed: _toggleImportant,
          color: _currentTodo.isImportant ? Colors.orange : Colors.grey,
        ),
        _buildActionButton(
          icon: _currentTodo.isArchived ? Icons.unarchive : Icons.archive,
          onPressed: _toggleArchive,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCompleteCheckbox(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentTodo.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    decoration: _currentTodo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: _currentTodo.isCompleted
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriorityBadge(),
          const SizedBox(height: 16),
          _buildMetadataSection(),
          const SizedBox(height: 24),
          if (_currentTodo.subTasks.isNotEmpty) _buildSubTasksSection(),
          if (_currentTodo.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDescriptionSection(),
          ],
          if (_currentTodo.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildTagsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteCheckbox() {
    return GestureDetector(
      onTap: _toggleComplete,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentTodo.isCompleted ? Colors.green : Colors.transparent,
          border: Border.all(
            color: _currentTodo.isCompleted ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: _currentTodo.isCompleted
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String label;

    switch (_currentTodo.priority) {
      case TodoPriority.low:
        color = Colors.green;
        label = 'Low Priority';
        break;
      case TodoPriority.medium:
        color = Colors.blue;
        label = 'Medium Priority';
        break;
      case TodoPriority.high:
        color = Colors.orange;
        label = 'High Priority';
        break;
      case TodoPriority.urgent:
        color = Colors.red;
        label = 'Urgent';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_currentTodo.dueDate != null)
          _buildMetadataChip(
            icon: Icons.calendar_today,
            label:
                'Due: ${DateFormat('MMM dd, yyyy').format(_currentTodo.dueDate!)}',
            color: _currentTodo.isOverdue ? Colors.red : Colors.grey[700]!,
          ),
        if (_currentTodo.reminderDate != null)
          _buildMetadataChip(
            icon: Icons.notifications,
            label:
                'Reminder: ${DateFormat('MMM dd, hh:mm a').format(_currentTodo.reminderDate!)}',
            color: Colors.grey[700]!,
          ),
        _buildMetadataChip(
          icon: Icons.category,
          label: _currentTodo.category.toString().split('.').last,
          color: Colors.grey[700]!,
        ),
      ],
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildSubTasksSection() {
    final completedCount = _currentTodo.subTasksCompleted
        .where((c) => c == true)
        .length;
    final totalCount = _currentTodo.subTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '$completedCount/$totalCount completed',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: completedCount / totalCount,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentTodo.subTasks.length,
          itemBuilder: (context, index) {
            return CheckboxListTile(
              value: _currentTodo.subTasksCompleted[index],
              onChanged: (_) => _toggleSubTask(index),
              title: Text(
                _currentTodo.subTasks[index],
                style: TextStyle(
                  decoration: _currentTodo.subTasksCompleted[index]
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            _currentTodo.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentTodo.tags
              .map(
                (tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.blue.withOpacity(0.15),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _editTodo,
      icon: const Icon(Icons.edit),
      label: const Text('Edit Task'),
      backgroundColor: const Color(0xFF6366F1),
    );
  }

  Future<void> _toggleComplete() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    HapticFeedback.lightImpact();

    try {
      await _controller.toggleComplete(_currentTodo);
      setState(
        () => _currentTodo = _currentTodo.copyWith(
          isCompleted: !_currentTodo.isCompleted,
        ),
      );
      _showSnackBar(
        _currentTodo.isCompleted ? 'Task completed!' : 'Task reopened',
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleImportant() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    HapticFeedback.lightImpact();

    try {
      await _controller.toggleImportant(_currentTodo);
      setState(
        () => _currentTodo = _currentTodo.copyWith(
          isImportant: !_currentTodo.isImportant,
        ),
      );
      _showSnackBar(
        _currentTodo.isImportant
            ? 'Marked as important'
            : 'Removed from important',
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleArchive() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    HapticFeedback.lightImpact();

    try {
      await _controller.toggleArchive(_currentTodo);
      setState(
        () => _currentTodo = _currentTodo.copyWith(
          isArchived: !_currentTodo.isArchived,
        ),
      );
      _showSnackBar(
        _currentTodo.isArchived ? 'Task archived' : 'Task unarchived',
      );

      if (_currentTodo.isArchived) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleSubTask(int index) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      await _controller.toggleSubTask(_currentTodo, index);
      final newSubTasksCompleted = List<bool>.from(
        _currentTodo.subTasksCompleted,
      );
      newSubTasksCompleted[index] = !newSubTasksCompleted[index];
      setState(
        () => _currentTodo = _currentTodo.copyWith(
          subTasksCompleted: newSubTasksCompleted,
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _editTodo() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<Todo>(
      context,
      MaterialPageRoute(builder: (_) => AddEditTodoScreen(todo: _currentTodo)),
    );
    if (result != null && mounted) {
      setState(() => _currentTodo = result);
      _showSnackBar('Task updated successfully');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
