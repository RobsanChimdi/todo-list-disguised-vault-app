// lib/features/todo/presentation/screens/add_edit_todo_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/models/todo_model.dart';

class ColorOption {
  final String name;
  final Color color;
  final int? value;

  const ColorOption({required this.name, required this.color, this.value});
}

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo;

  const AddEditTodoScreen({Key? key, this.todo}) : super(key: key);

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  DateTime? _dueDate;
  DateTime? _reminderDate;
  TodoPriority _priority = TodoPriority.medium;
  TodoCategory _category = TodoCategory.personal;
  Color _selectedColor = Colors.white;
  bool _isImportant = false;
  bool _isEditing = false;

  List<String> _subTasks = [];
  List<bool> _subTasksCompleted = [];
  final TextEditingController _subTaskController = TextEditingController();

  final List<ColorOption> _colorOptions = [
    const ColorOption(name: 'Default', color: Colors.white, value: 0xFFFFFFFF),
    const ColorOption(
      name: 'Sunset',
      color: Color(0xFFFFE4B5),
      value: 0xFFFFE4B5,
    ),
    const ColorOption(
      name: 'Ocean',
      color: Color(0xFFE0F7FA),
      value: 0xFFE0F7FA,
    ),
    const ColorOption(
      name: 'Forest',
      color: Color(0xFFE8F5E9),
      value: 0xFFE8F5E9,
    ),
    const ColorOption(
      name: 'Rose',
      color: Color(0xFFFCE4EC),
      value: 0xFFFCE4EC,
    ),
    const ColorOption(
      name: 'Lavender',
      color: Color(0xFFF3E5F5),
      value: 0xFFF3E5F5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.todo != null;

    if (_isEditing) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _tags = List.from(widget.todo!.tags);
      _dueDate = widget.todo!.dueDate;
      _reminderDate = widget.todo!.reminderDate;
      _priority = widget.todo!.priority;
      _category = widget.todo!.category;
      _isImportant = widget.todo!.isImportant;
      _subTasks = List.from(widget.todo!.subTasks);
      _subTasksCompleted = List.from(widget.todo!.subTasksCompleted);

      if (widget.todo!.backgroundColor != 0xFFFFFFFF) {
        final colorOption = _colorOptions.firstWhere(
          (option) => option.value == widget.todo!.backgroundColor,
          orElse: () => _colorOptions.first,
        );
        _selectedColor = colorOption.color;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _subTaskController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    HapticFeedback.lightImpact();
  }

  void _addSubTask() {
    final subTask = _subTaskController.text.trim();
    if (subTask.isNotEmpty) {
      setState(() {
        _subTasks.add(subTask);
        _subTasksCompleted.add(false);
        _subTaskController.clear();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
      _subTasksCompleted.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _toggleSubTaskComplete(int index) {
    setState(() {
      _subTasksCompleted[index] = !_subTasksCompleted[index];
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _reminderDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _saveTodo() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a title');
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();

    Todo todo;

    if (_isEditing) {
      todo = widget.todo!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tags,
        dueDate: _dueDate,
        reminderDate: _reminderDate,
        priority: _priority,
        category: _category,
        isImportant: _isImportant,
        subTasks: _subTasks,
        subTasksCompleted: _subTasksCompleted,
        backgroundColor: _getSelectedColorValue(),
      );
    } else {
      todo =
          Todo.create(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            tags: _tags,
            dueDate: _dueDate,
            priority: _priority,
            category: _category,
          ).copyWith(
            isImportant: _isImportant,
            subTasks: _subTasks,
            subTasksCompleted: _subTasksCompleted,
            backgroundColor: _getSelectedColorValue(),
          );
    }
    Navigator.pop(context, todo);
  }

  int? _getSelectedColorValue() {
    final selected = _colorOptions.firstWhere(
      (option) => option.color == _selectedColor,
      orElse: () => _colorOptions.first,
    );
    return selected.value;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _selectedColor.withOpacity(0.95),
      elevation: 0,
      foregroundColor: Colors.black87,
      title: Text(
        _isEditing ? 'Edit Task' : 'New Task',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black87,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isImportant ? Icons.flag : Icons.flag_outlined,
                key: ValueKey(_isImportant),
                color: _isImportant ? Colors.orange : Colors.grey[600],
              ),
            ),
            onPressed: () {
              setState(() => _isImportant = !_isImportant);
              HapticFeedback.lightImpact();
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: _saveTodo,
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Task title...',
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Priority Section
          _buildPrioritySection(),
          const SizedBox(height: 24),

          // Category Section
          _buildCategorySection(),
          const SizedBox(height: 24),

          // Due Date Section
          _buildDueDateSection(),
          const SizedBox(height: 24),

          // Reminder Section
          _buildReminderSection(),
          const SizedBox(height: 24),

          // Subtasks Section
          _buildSubTasksSection(),
          const SizedBox(height: 24),

          // Description Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              maxLines: 5,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Add description...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tags Section
          _buildTagsSection(),
          const SizedBox(height: 24),

          // Color Section
          _buildColorSection(),
        ],
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: TodoPriority.values.map((priority) {
            final isSelected = _priority == priority;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(
                    priority.toString().split('.').last,
                    style: TextStyle(
                      color: isSelected
                          ? _getPriorityColor(priority)
                          : Colors.grey[700],
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _priority = priority),
                  backgroundColor: Colors.grey[200],
                  selectedColor: _getPriorityColor(priority).withOpacity(0.2),
                  checkmarkColor: _getPriorityColor(priority),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TodoCategory.values.map((category) {
            final isSelected = _category == category;
            return FilterChip(
              label: Text(
                _getCategoryIcon(category) +
                    ' ' +
                    category.toString().split('.').last,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _category = category),
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue.withOpacity(0.2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due Date',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDueDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _dueDate != null
                      ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                      : 'No due date',
                  style: TextStyle(
                    color: _dueDate != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _dueDate = null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectReminderDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _reminderDate != null
                      ? DateFormat(
                          'MMM dd, yyyy • hh:mm a',
                        ).format(_reminderDate!)
                      : 'No reminder',
                  style: TextStyle(
                    color: _reminderDate != null
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_reminderDate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _reminderDate = null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // lib/features/todo/presentation/screens/add_edit_todo_screen.dart

  // Fix the _buildSubTasksSection method - update the TextField for adding subtasks:

  Widget _buildSubTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subtasks',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subTasks.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    value: _subTasksCompleted[index],
                    onChanged: (_) => _toggleSubTaskComplete(index),
                    title: Text(
                      _subTasks[index],
                      style: TextStyle(
                        decoration: _subTasksCompleted[index]
                            ? TextDecoration.lineThrough
                            : null,
                        color: _subTasksCompleted[index]
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                    secondary: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () => _removeSubTask(index),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100], // Added background color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _subTaskController,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add subtask...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _addSubTask(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _addSubTask,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Update the _buildTagsSection method:

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map(
                (tag) => Chip(
                  label: Text(
                    '#$tag',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  onDeleted: () => _removeTag(tag),
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.blue,
                  ),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ),
              Container(
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Added background color
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _tagController,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add tag...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Color',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colorOptions.length,
              itemBuilder: (context, index) {
                final option = _colorOptions[index];
                final isSelected = _selectedColor == option.color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = option.color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.blue, size: 24)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _saveTodo,
      child: const Icon(Icons.check_rounded),
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
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

  String _getCategoryIcon(TodoCategory category) {
    switch (category) {
      case TodoCategory.personal:
        return '👤';
      case TodoCategory.work:
        return '💼';
      case TodoCategory.shopping:
        return '🛒';
      case TodoCategory.health:
        return '🏃';
      case TodoCategory.learning:
        return '📚';
      case TodoCategory.other:
        return '📌';
    }
  }
}
