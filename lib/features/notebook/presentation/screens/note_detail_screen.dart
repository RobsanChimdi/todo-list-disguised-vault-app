// lib/features/notebook/presentation/screens/note_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';
import 'add_edit_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late NoteController _controller;
  late Note _currentNote;
  bool _isUpdating = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showFAB = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _controller = Get.find<NoteController>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final currentPosition = _scrollController.position.pixels;
    final shouldShowFAB =
        currentPosition < _lastScrollPosition || currentPosition < 100;

    if (shouldShowFAB != _showFAB) {
      setState(() {
        _showFAB = shouldShowFAB;
      });
    }
    _lastScrollPosition = currentPosition;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Color(_currentNote.backgroundColor),
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
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
              Color(_currentNote.backgroundColor).withOpacity(0.95),
              Color(_currentNote.backgroundColor).withOpacity(0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
      ),
      title: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[700]),
            SizedBox(width: 6),
            Text(
              _formatDate(_currentNote.createdAt),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            if (_currentNote.updatedAt != _currentNote.createdAt) ...[
              SizedBox(width: 12),
              Icon(Icons.edit_calendar, size: 14, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                _formatDate(_currentNote.updatedAt),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        _buildActionButton(
          icon: Icons.share,
          onPressed: _shareNote,
          color: Colors.green,
        ),
        _buildActionButton(
          icon: Icons.print,
          onPressed: _printNote,
          color: Colors.purple,
        ),
        _buildActionButton(
          icon: _currentNote.isFavorite
              ? Icons.favorite
              : Icons.favorite_border,
          onPressed: _isUpdating ? null : _toggleFavorite,
          color: _currentNote.isFavorite ? Colors.red : Colors.grey,
        ),
        _buildActionButton(
          icon: _currentNote.isArchived ? Icons.unarchive : Icons.archive,
          onPressed: _isUpdating ? null : _toggleArchive,
          color: Colors.grey,
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: Icon(icon, key: ValueKey(icon), color: color),
        ),
        onPressed: onPressed,
        tooltip: _getTooltip(icon),
      ),
    );
  }

  String _getTooltip(IconData icon) {
    switch (icon) {
      case Icons.share:
        return 'Share Note';
      case Icons.print:
        return 'Print Note';
      case Icons.favorite:
      case Icons.favorite_border:
        return _currentNote.isFavorite
            ? 'Remove from Favorites'
            : 'Add to Favorites';
      case Icons.archive:
      case Icons.unarchive:
        return _currentNote.isArchived ? 'Unarchive' : 'Archive';
      default:
        return '';
    }
  }

  Widget _buildBody() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'note_title_${_currentNote.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      _currentNote.title,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetadataSection(),
                const SizedBox(height: 24),
                _buildContentSection(),
                if (_currentNote.tags.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildTagsSection(),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildMetadataChip(icon: Icons.text_fields, label: _getWordCount()),
          SizedBox(width: 12),
          _buildMetadataChip(icon: Icons.abc, label: _getCharCount()),
          if (_currentNote.content.isNotEmpty) ...[
            SizedBox(width: 12),
            _buildMetadataChip(icon: Icons.timer, label: _getReadTime()),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _getWordCount() {
    final words = _currentNote.content.trim().split(RegExp(r'\s+'));
    return '${words.length} ${words.length == 1 ? 'word' : 'words'}';
  }

  String _getCharCount() {
    return '${_currentNote.content.length} chars';
  }

  String _getReadTime() {
    final words = _currentNote.content.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  Widget _buildContentSection() {
    final content = _currentNote.content;
    if (content.trim().isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.edit_note, size: 48, color: Colors.grey[400]),
              ),
              SizedBox(height: 16),
              Text(
                'No content yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap edit to add content',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4),
      child: SelectableText(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.8,
          color: Colors.black87,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, size: 20, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _currentNote.tags
              .map(
                (tag) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Chip(
                    label: Text(
                      '#$tag',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                    elevation: 0,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _showFAB ? 1.0 : 0.0,
      child: FloatingActionButton.extended(
        onPressed: _editNote,
        icon: Icon(Icons.edit_rounded),
        label: Text('Edit Note', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    HapticFeedback.lightImpact();
    try {
      final updated = _currentNote.copyWith(
        isFavorite: !_currentNote.isFavorite,
      );
      await _controller.updateNote(updated);
      setState(() => _currentNote = updated);
      _showSnackBar(
        _currentNote.isFavorite
            ? 'Added to favorites'
            : 'Removed from favorites',
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
      final updated = _currentNote.copyWith(
        isArchived: !_currentNote.isArchived,
      );
      await _controller.updateNote(updated);
      setState(() => _currentNote = updated);
      _showSnackBar(
        _currentNote.isArchived ? 'Note archived' : 'Note unarchived',
      );

      // Optional: Navigate back if archived
      if (_currentNote.isArchived) {
        Future.delayed(Duration(milliseconds: 500), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _shareNote() async {
    HapticFeedback.mediumImpact();
    final String shareText = _generateShareText();
    await Share.share(shareText, subject: _currentNote.title);
  }

  String _generateShareText() {
    final buffer = StringBuffer();
    buffer.writeln(_currentNote.title);
    buffer.writeln('─' * 40);
    buffer.writeln(_currentNote.content);
    buffer.writeln();
    buffer.writeln('─' * 40);
    buffer.writeln('Tags: ${_currentNote.tags.map((t) => '#$t').join(', ')}');
    buffer.writeln('Created: ${_formatDateTime(_currentNote.createdAt)}');
    return buffer.toString();
  }

  Future<void> _printNote() async {
    HapticFeedback.mediumImpact();
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final html = _generatePrintHtml();
          return await Printing.convertHtmlToPdf(html: html, format: format);
        },
        name: 'Note - ${_currentNote.title}',
      );
      _showSnackBar('Print dialog opened');
    } catch (e) {
      _showSnackBar('Error preparing print: $e');
    }
  }

  String _generatePrintHtml() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>${_currentNote.title}</title>
        <style>
          body {
            font-family: 'Helvetica', Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
            color: #333;
          }
          .container {
            max-width: 800px;
            margin: 0 auto;
          }
          h1 {
            font-size: 28px;
            color: #1a1a1a;
            margin-bottom: 10px;
            border-bottom: 2px solid #e0e0e0;
            padding-bottom: 10px;
          }
          .metadata {
            color: #666;
            font-size: 12px;
            margin-bottom: 20px;
            padding: 10px;
            background-color: #f5f5f5;
            border-radius: 5px;
          }
          .content {
            font-size: 14px;
            margin: 20px 0;
            white-space: pre-wrap;
          }
          .tags {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
          }
          .tag {
            display: inline-block;
            background-color: #e3f2fd;
            color: #1976d2;
            padding: 4px 12px;
            margin: 4px;
            border-radius: 20px;
            font-size: 12px;
          }
          .footer {
            margin-top: 40px;
            text-align: center;
            font-size: 10px;
            color: #999;
            border-top: 1px solid #e0e0e0;
            padding-top: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>${_escapeHtml(_currentNote.title)}</h1>
          <div class="metadata">
            <strong>Created:</strong> ${_formatDateTime(_currentNote.createdAt)}<br>
            <strong>Last Updated:</strong> ${_formatDateTime(_currentNote.updatedAt)}<br>
            <strong>Word Count:</strong> ${_getWordCount()}<br>
            <strong>Reading Time:</strong> ${_getReadTime()}
          </div>
          <div class="content">
            ${_escapeHtml(_currentNote.content).replaceAll('\n', '<br>')}
          </div>
          ${_currentNote.tags.isNotEmpty ? '''
          <div class="tags">
            <strong>Tags:</strong><br>
            ${_currentNote.tags.map((tag) => '<span class="tag">#$tag</span>').join('')}
          </div>
          ''' : ''}
          <div class="footer">
            Printed from Note App • ${DateTime.now().toString().split('.')[0]}
          </div>
        </div>
      </body>
      </html>
    ''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  Future<void> _editNote() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditNoteScreen(note: _currentNote),
        settings: RouteSettings(name: '/edit-note'),
      ),
    );
    if (result != null && mounted) {
      setState(() => _currentNote = result);
      _showSnackBar('Note updated successfully');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
