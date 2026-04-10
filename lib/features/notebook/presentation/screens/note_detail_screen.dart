// lib/features/notebook/presentation/screens/note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';
import 'add_edit_note_screen.dart';

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
  void initState() {
    super.initState();
    _currentNote = widget.note;
    // Use GetX to find controller instead of Provider
    _controller = Get.find<NoteController>();
  }

  @override
  Widget build(BuildContext context) {
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
          if (_currentNote.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildTagsSection(),
          ],
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

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentNote.tags
              .map(
                (tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.blue[700]),
                ),
              )
              .toList(),
        ),
      ],
    );
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
      if (mounted) setState(() => _isUpdating = false);
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
      if (mounted) setState(() => _isUpdating = false);
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
