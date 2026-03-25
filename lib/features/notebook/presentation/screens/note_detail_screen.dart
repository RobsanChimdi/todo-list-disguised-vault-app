import 'package:flutter/material.dart';
import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';
import 'add_edit_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteController _controller;
  bool _isFavorite = false;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    _controller = NoteController();
    _isFavorite = widget.note.isFavorite ?? false;
    _isArchived = widget.note.isArchived ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
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
      title: Text(
        _formatDate(widget.note.createdAt),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.grey[600],
        ),
      ),
      actions: [
        // Favorite Button
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
              widget.note.isFavorite = _isFavorite;
              _controller.updateNote(widget.note);
            });
            _showSnackBar(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            );
          },
        ),
        // Archive Button
        IconButton(
          icon: Icon(
            _isArchived ? Icons.unarchive : Icons.archive,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _isArchived = !_isArchived;
              widget.note.isArchived = _isArchived;
              _controller.updateNote(widget.note);
            });
            _showSnackBar(_isArchived ? 'Note archived' : 'Note unarchived');
            if (_isArchived) {
              Future.delayed(Duration(seconds: 1), () {
                Navigator.pop(context);
              });
            }
          },
        ),
        // More Options
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _editNote();
                break;
              case 'share':
                _shareNote();
                break;
              case 'delete':
                _showDeleteConfirmationDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Text(
            widget.note.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          // Metadata Section
          _buildMetadataSection(),
          SizedBox(height: 24),

          // Content Section
          _buildContentSection(),
          SizedBox(height: 32),

          // Tags Section (if any)
          if (widget.note.tags != null && widget.note.tags!.isNotEmpty)
            _buildTagsSection(),

          // Last Edited Info
          if (widget.note.lastEdited != null)
            Padding(
              padding: EdgeInsets.only(top: 32),
              child: Divider(color: Colors.grey[300]),
            ),
          if (widget.note.lastEdited != null)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Last edited: ${_formatFullDate(widget.note.lastEdited!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          _buildMetadataItem(
            icon: Icons.calendar_today,
            label: _formatDate(widget.note.createdAt),
          ),
          SizedBox(width: 24),
          _buildMetadataItem(
            icon: Icons.access_time,
            label: _formatTime(widget.note.createdAt),
          ),
          SizedBox(width: 24),
          if (widget.note.wordCount != null)
            _buildMetadataItem(
              icon: Icons.text_fields,
              label: '${widget.note.wordCount} words',
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildContentSection() {
    if (widget.note.content == null || widget.note.content!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No content',
            style: TextStyle(
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4),
      child: Text(
        widget.note.content!,
        style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
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
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.note.tags!.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _editNote,
      icon: Icon(Icons.edit),
      label: Text('Edit Note'),
      elevation: 2,
    );
  }

  Color _getBackgroundColor() {
    // You can add different background colors based on note type
    if (widget.note.backgroundColor != null) {
      return Color(widget.note.backgroundColor!);
    }
    return Colors.grey[50]!;
  }

  Future<void> _editNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: widget.note)),
    );
    if (result != null) {
      setState(() {
        widget.note.title = result.title;
        widget.note.content = result.content;
        widget.note.lastEdited = DateTime.now();
        if (result.tags != null) widget.note.tags = result.tags;
      });
      _showSnackBar('Note updated successfully');
    }
  }

  void _shareNote() {
    // Implement share functionality
    // You can use the share package or create a custom share dialog
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Note',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copy to clipboard'),
                onTap: () {
                  // Copy to clipboard
                  Navigator.pop(context);
                  _showSnackBar('Copied to clipboard');
                },
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text('Send via email'),
                onTap: () {
                  Navigator.pop(context);
                  // Open email intent
                },
              ),
              ListTile(
                leading: Icon(Icons.message),
                title: Text('Send via message'),
                onTap: () {
                  Navigator.pop(context);
                  // Open message intent
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete "${widget.note.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.deleteNoteById(widget.note.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
              _showSnackBar('Note deleted');
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
