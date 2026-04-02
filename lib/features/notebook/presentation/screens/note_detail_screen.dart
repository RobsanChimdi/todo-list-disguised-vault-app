// lib/features/notebook/presentation/screens/note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';
import 'add_edit_note_screen.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../disguise/services/secret_note_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteController _controller;
  late Note _currentNote;

  bool _isUpdating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = Provider.of<NoteController>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;

    // Check if this is a secret note and handle authentication
    _checkSecretNote();
  }

  void _checkSecretNote() async {
    final isSecret =
        _currentNote.isSecretTrigger ||
        SecretNoteService.isSecretTrigger(_currentNote.title);

    if (isSecret) {
      // Show authentication dialog
      final shouldAuthenticate = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('Locked Note'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SecretNoteService.getWarningMessage(_currentNote.title),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: "${SecretNoteService.getDisguisedTitle(_currentNote.title)}"',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  Navigator.pop(context); // Go back to home
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Unlock'),
              ),
            ],
          );
        },
      );

      if (shouldAuthenticate == true) {
        // Request vault access
        final authController = Get.find<AuthController>();
        await authController.requestVaultAccess();
        // Note: After authentication, the user will be navigated to vault
        // So we don't need to do anything else here
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSecret =
        _currentNote.isSecretTrigger ||
        SecretNoteService.isSecretTrigger(_currentNote.title);

    // Don't show content if it's a secret note (should be handled by authentication)
    if (isSecret) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'This note is locked',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Authentication required to view content',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(_currentNote.backgroundColor),
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
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _currentNote.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _currentNote.isFavorite ? Colors.red : Colors.grey,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: Icon(
            _currentNote.isArchived ? Icons.unarchive : Icons.archive,
            color: Colors.grey,
          ),
          onPressed: _toggleArchive,
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
          Text(
            _currentNote.title,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildContentSection(),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    final content = _currentNote.content;

    if (content.trim().isEmpty) {
      return const Text('No content', style: TextStyle(color: Colors.grey));
    }

    return Text(content, style: const TextStyle(fontSize: 16, height: 1.6));
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _editNote,
      child: const Icon(Icons.edit),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final updated = _currentNote.copyWith(
        isFavorite: !_currentNote.isFavorite,
      );

      await _controller.updateNote(updated);

      setState(() => _currentNote = updated);
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _toggleArchive() async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final updated = _currentNote.copyWith(
        isArchived: !_currentNote.isArchived,
      );

      await _controller.updateNote(updated);

      setState(() => _currentNote = updated);
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _editNote() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: _currentNote)),
    );

    if (result != null && mounted) {
      setState(() => _currentNote = result);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
