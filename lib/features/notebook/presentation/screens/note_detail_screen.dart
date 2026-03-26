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
  late Note _currentNote; // Track current note state
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _controller = NoteController();
    _currentNote = widget.note; // Store as mutable state
  }

  @override
  void dispose() {
    _controller.dispose(); // Assuming you add dispose to controller
    super.dispose();
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
        _formatDate(_currentNote.createdAt),
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
            _currentNote.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _currentNote.isFavorite ? Colors.red : Colors.grey[600],
          ),
          onPressed: _toggleFavorite,
          tooltip: _currentNote.isFavorite
              ? 'Remove from favorites'
              : 'Add to favorites',
        ),
        // Archive Button
        IconButton(
          icon: Icon(
            _currentNote.isArchived ? Icons.unarchive : Icons.archive,
            color: Colors.grey[600],
          ),
          onPressed: _toggleArchive,
          tooltip: _currentNote.isArchived ? 'Unarchive' : 'Archive',
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
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Text(
            _currentNote.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Metadata Section
          _buildMetadataSection(),
          const SizedBox(height: 24),

          // Content Section
          _buildContentSection(),
          const SizedBox(height: 32),

          // Tags Section (if any)
          if (_currentNote.tags.isNotEmpty) _buildTagsSection(),

          // Last Edited Info
          const Divider(color: Colors.grey, height: 48),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Last edited: ${_formatFullDate(_currentNote.lastEdited)}',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          _buildMetadataItem(
            icon: Icons.calendar_today,
            label: _formatDate(_currentNote.createdAt),
          ),
          const SizedBox(width: 24),
          _buildMetadataItem(
            icon: Icons.access_time,
            label: _formatTime(_currentNote.createdAt),
          ),
          const SizedBox(width: 24),
          _buildMetadataItem(
            icon: Icons.text_fields,
            label: '${_currentNote.wordCount} words',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildContentSection() {
    if (_currentNote.content == null || _currentNote.content!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No content',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      child: Text(
        _currentNote.content!,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentNote.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      icon: const Icon(Icons.edit),
      label: const Text('Edit Note'),
      elevation: 2,
    );
  }

  Color _getBackgroundColor() {
    return Color(_currentNote.backgroundColor);
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedNote = _currentNote.copyWith(
        isFavorite: !_currentNote.isFavorite,
      );

      await _controller.updateNote(updatedNote);

      setState(() {
        _currentNote = updatedNote;
      });

      _showSnackBar(
        updatedNote.isFavorite
            ? 'Added to favorites'
            : 'Removed from favorites',
      );
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _toggleArchive() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedNote = _currentNote.copyWith(
        isArchived: !_currentNote.isArchived,
      );

      await _controller.updateNote(updatedNote);

      setState(() {
        _currentNote = updatedNote;
      });

      _showSnackBar(
        updatedNote.isArchived ? 'Note archived' : 'Note unarchived',
      );

      if (updatedNote.isArchived) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _editNote() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: _currentNote)),
    );

    if (result != null && mounted) {
      setState(() {
        _currentNote = result;
      });
      _showSnackBar('Note updated successfully');
    }
  }

  void _shareNote() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Note',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy to clipboard'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement copy to clipboard
                  _showSnackBar('Copied to clipboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Send via email'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement email sharing
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Send via message'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement message sharing
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
        title: const Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete "${_currentNote.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _controller.deleteNoteById(_currentNote.id);
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  _showSnackBar('Note deleted');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  _showSnackBar('Error deleting note');
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
