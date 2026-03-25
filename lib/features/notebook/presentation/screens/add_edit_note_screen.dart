import 'package:flutter/material.dart';
import '../../data/models/note_model.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note; // Optional note for editing mode

  const AddEditNoteScreen({Key? key, this.note}) : super(key: key);

  @override
  _AddEditNoteScreenState createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  Color _selectedColor = Colors.white;
  bool _isFavorite = false;
  bool _isEditing = false;

  // Color options for note background
  final List<ColorOption> _colorOptions = [
    ColorOption(name: 'Default', color: Colors.white, value: null),
    ColorOption(name: 'Yellow', color: Color(0xFFFFF9C4), value: 0xFFFFF9C4),
    ColorOption(name: 'Blue', color: Color(0xFFE3F2FD), value: 0xFFE3F2FD),
    ColorOption(name: 'Green', color: Color(0xFFE8F5E9), value: 0xFFE8F5E9),
    ColorOption(name: 'Pink', color: Color(0xFFFCE4EC), value: 0xFFFCE4EC),
    ColorOption(name: 'Purple', color: Color(0xFFF3E5F5), value: 0xFFF3E5F5),
    ColorOption(name: 'Orange', color: Color(0xFFFFF3E0), value: 0xFFFFF3E0),
  ];

  int _wordCount = 0;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;

    if (_isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content ?? '';
      _tags = widget.note!.tags ?? [];
      _isFavorite = widget.note!.isFavorite;

      // Find and set the background color
      if (widget.note!.backgroundColor != null) {
        final colorOption = _colorOptions.firstWhere(
          (option) => option.value == widget.note!.backgroundColor,
          orElse: () => _colorOptions.first,
        );
        _selectedColor = colorOption.color;
      }
    }

    // Add listeners for word count
    _contentController.addListener(_updateWordCount);
    _updateWordCount();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _contentController.text;
    if (text.isEmpty) {
      _wordCount = 0;
    } else {
      _wordCount = text.trim().split(RegExp(r'\s+')).length;
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
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveNote() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a title');
      return;
    }

    final now = DateTime.now();
    Note note;

    if (_isEditing) {
      // Update existing note
      note = widget.note!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.isEmpty
            ? null
            : _contentController.text,
        lastEdited: now,
        isFavorite: _isFavorite,
        tags: _tags.isEmpty ? null : _tags,
        wordCount: _wordCount,
        backgroundColor: _getSelectedColorValue(),
      );
    } else {
      // Create new note
      note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.isEmpty
            ? null
            : _contentController.text,
        createdAt: now,
        lastEdited: now,
        isFavorite: _isFavorite,
        tags: _tags.isEmpty ? null : _tags,
        wordCount: _wordCount,
        backgroundColor: _getSelectedColorValue(),
      );
    }

    setState(() {
      _isSaved = true;
    });

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
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  void _showDiscardDialog() {
    if (_titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _tags.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Discard Changes?'),
          content: Text(
            'You have unsaved changes. Do you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
              },
              child: Text('Discard', style: TextStyle(color: Colors.red)),
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
    return WillPopScope(
      onWillPop: () async {
        _showDiscardDialog();
        return false;
      },
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
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      leading: IconButton(
        icon: Icon(Icons.close),
        onPressed: _showDiscardDialog,
      ),
      actions: [
        // Favorite button
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
        ),
        // Save button
        TextButton(
          onPressed: _saveNote,
          child: Text(
            'Save',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Title',
              hintStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            maxLines: null,
          ),

          // Word count and metadata
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.text_fields, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  '$_wordCount words',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 16),
                if (_tags.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        '${_tags.length} tags',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          Divider(color: Colors.grey[300]),
          SizedBox(height: 16),

          // Content field
          TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Start writing...',
              hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            maxLines: null,
          ),

          SizedBox(height: 24),

          // Tags section
          _buildTagsSection(),
          SizedBox(height: 24),

          // Color section
          _buildColorSection(),
          SizedBox(height: 24),

          // Additional info for editing mode
          if (_isEditing && widget.note!.createdAt != null)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Created: ${_formatDate(widget.note!.createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map(
              (tag) => Chip(
                label: Text('#$tag'),
                onDeleted: () => _removeTag(tag),
                deleteIcon: Icon(Icons.close, size: 16),
                backgroundColor: Colors.blue.withOpacity(0.1),
                labelStyle: TextStyle(color: Colors.blue[700]),
              ),
            ),
            Container(
              width: 120,
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add tag...',
                  hintStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: _addTag,
                  ),
                ),
                onSubmitted: (_) => _addTag(),
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
          'Background Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((option) {
            final isSelected = _selectedColor == option.color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = option.color;
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
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
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.blue, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _saveNote,
      child: Icon(Icons.check),
      backgroundColor: Colors.blue,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Color option model
class ColorOption {
  final String name;
  final Color color;
  final int? value;

  ColorOption({required this.name, required this.color, this.value});
}
