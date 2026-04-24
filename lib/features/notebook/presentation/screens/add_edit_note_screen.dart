// lib/features/notebook/presentation/screens/add_edit_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/note_model.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({Key? key, this.note}) : super(key: key);

  @override
  _AddEditNoteScreenState createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  Color _selectedColor = Colors.white;
  bool _isFavorite = false;
  bool _isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<ColorOption> _colorOptions = [
    ColorOption(
      name: 'Default',
      color: Colors.white,
      gradient: null,
      value: null,
    ),
    ColorOption(
      name: 'Sunset',
      color: Color(0xFFFFE4B5),
      gradient: LinearGradient(
        colors: [Color(0xFFFFE4B5), Color(0xFFFFD6A5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      value: 0xFFFFE4B5,
    ),
    ColorOption(
      name: 'Ocean',
      color: Color(0xFFE0F7FA),
      gradient: LinearGradient(
        colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      value: 0xFFE0F7FA,
    ),
    ColorOption(
      name: 'Forest',
      color: Color(0xFFE8F5E9),
      gradient: LinearGradient(
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      value: 0xFFE8F5E9,
    ),
    ColorOption(
      name: 'Rose',
      color: Color(0xFFFCE4EC),
      gradient: LinearGradient(
        colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      value: 0xFFFCE4EC,
    ),
    ColorOption(
      name: 'Lavender',
      color: Color(0xFFF3E5F5),
      gradient: LinearGradient(
        colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      value: 0xFFF3E5F5,
    ),
    ColorOption(
      name: 'Peach',
      color: Color(0xFFFFF3E0),
      gradient: LinearGradient(
        colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      value: 0xFFFFF3E0,
    ),
    ColorOption(
      name: 'Mint',
      color: Color(0xFFE0F2F1),
      gradient: LinearGradient(
        colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      value: 0xFFE0F2F1,
    ),
  ];

  int _wordCount = 0;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _isEditing = widget.note != null;

    if (_isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _tags = List.from(widget.note!.tags);
      _isFavorite = widget.note!.isFavorite;

      if (widget.note!.backgroundColor != 0xFFFFFFFF) {
        final colorOption = _colorOptions.firstWhere(
          (option) => option.value == widget.note!.backgroundColor,
          orElse: () => _colorOptions.first,
        );
        _selectedColor = colorOption.color;
      }
    }

    _contentController.addListener(_updateCounts);
    _updateCounts();
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateCounts);
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateCounts() {
    final text = _contentController.text;
    if (text.isEmpty) {
      _wordCount = 0;
      _characterCount = 0;
    } else {
      _wordCount = text.trim().split(RegExp(r'\s+')).length;
      _characterCount = text.length;
    }
    if (mounted) setState(() {});
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

  void _saveNote() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a title');
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();

    Note note;

    if (_isEditing) {
      note = widget.note!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim().isEmpty
            ? ''
            : _contentController.text.trim(),
        isFavorite: _isFavorite,
        tags: _tags,
        backgroundColor: _getSelectedColorValue(),
      );
    } else {
      note =
          Note.create(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            tags: _tags,
          ).copyWith(
            isFavorite: _isFavorite,
            backgroundColor: _getSelectedColorValue(),
          );
    }
    Navigator.pop(context, note);
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
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDiscardDialog() {
    if (_titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _tags.isNotEmpty) {
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Discard Changes?'),
            ],
          ),
          content: Text(
            'You have unsaved changes. Do you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: _selectedColor,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _selectedColor.withOpacity(0.95),
      elevation: 0,
      foregroundColor: Colors.black87,
      title: Text(
        _isEditing ? 'Edit Note' : 'New Note',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black87,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close, size: 20),
        ),
        onPressed: _showDiscardDialog,
      ),
      actions: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(_isFavorite),
                color: _isFavorite ? Colors.red : Colors.grey[600],
              ),
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              HapticFeedback.lightImpact();
            },
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: _saveNote,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    // Use LayoutBuilder to ensure proper scrolling
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
                MediaQuery.of(context).padding.bottom +
                80, // Extra space for FAB
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(
                          icon: Icons.text_fields,
                          label: '$_wordCount words',
                        ),
                        _buildStatChip(
                          icon: Icons.email,
                          label: '$_characterCount chars',
                        ),
                        if (_tags.isNotEmpty)
                          _buildStatChip(
                            icon: Icons.tag,
                            label: '${_tags.length} tags',
                          ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.grey[300]),
                  SizedBox(height: 24),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      maxLines: null,
                      expands: true,
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildTagsSection(),
                  SizedBox(height: 24),
                  _buildColorSection(),
                  if (_isEditing) ...[
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Created: ${_formatDate(widget.note!.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16), // Extra bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._tags.map(
              (tag) => AnimatedContainer(
                duration: Duration(milliseconds: 200),
                child: Chip(
                  label: Text(
                    '#$tag',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onDeleted: () => _removeTag(tag),
                  deleteIcon: Icon(Icons.close, size: 16),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.blue[700]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add tag...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: _addTag,
                  ),
                ),
                onSubmitted: (_) => _addTag(),
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Background Style',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _colorOptions.length,
            itemBuilder: (context, index) {
              final option = _colorOptions[index];
              final isSelected = _selectedColor == option.color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = option.color;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: option.gradient,
                          color: option.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.blue, size: 24)
                            : null,
                      ),
                      SizedBox(height: 6),
                      Text(
                        option.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _saveNote,
      child: Icon(Icons.check_rounded),
      backgroundColor: Colors.blue,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class ColorOption {
  final String name;
  final Color color;
  final Gradient? gradient;
  final int? value;

  ColorOption({
    required this.name,
    required this.color,
    this.gradient,
    this.value,
  });
}
