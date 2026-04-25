// lib/features/notebook/presentation/screens/note_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isPrinting = false;

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

    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ we need different permissions
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
      // For Android 11+ we also need manage external storage
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
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
            stops: const [0.0, 1.0],
          ),
        ),
      ),
      title: const Text(''),
      centerTitle: false,
      actions: [
        _buildActionButton(
          icon: Icons.share,
          onPressed: _shareNote,
          color: Colors.green,
        ),
        _buildActionButton(
          icon: Icons.print,
          onPressed: _isPrinting ? null : _printNote,
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
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(icon, key: ValueKey(icon), color: color, size: 20),
        ),
        onPressed: onPressed,
        tooltip: _getTooltip(icon),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                const SizedBox(height: 12),
                _buildDateInfo(),
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

  Widget _buildDateInfo() {
    final hasBothDates = _currentNote.lastEdited != _currentNote.createdAt;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          icon: Icons.calendar_today,
          label: 'Created: ${_formatShortDate(_currentNote.createdAt)}',
          color: Colors.grey[700]!,
        ),
        if (hasBothDates)
          _buildInfoChip(
            icon: Icons.edit_calendar,
            label: 'Edited: ${_formatShortDate(_currentNote.lastEdited)}',
            color: Colors.grey[600]!,
          ),
      ],
    );
  }

  Widget _buildInfoChip({
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetadataChip(icon: Icons.text_fields, label: _getWordCount()),
        _buildMetadataChip(icon: Icons.abc, label: _getCharCount()),
        if (_currentNote.content.isNotEmpty)
          _buildMetadataChip(icon: Icons.timer, label: _getReadTime()),
      ],
    );
  }

  Widget _buildMetadataChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
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
        padding: const EdgeInsets.all(40),
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
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.edit_note, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No content yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap edit to add content',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
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
            const SizedBox(width: 8),
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
                (tag) => Chip(
                  label: Text(
                    '#$tag',
                    style: const TextStyle(
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
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _showFAB ? 1.0 : 0.0,
      child: FloatingActionButton.extended(
        onPressed: _editNote,
        icon: const Icon(Icons.edit_rounded),
        label: const Text(
          'Edit Note',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: const Color(0xFF6366F1),
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

      if (_currentNote.isArchived) {
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
    if (_isPrinting) return;

    HapticFeedback.mediumImpact();
    setState(() => _isPrinting = true);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing PDF...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    try {
      // Generate PDF using the pdf package
      final pdf = pw.Document();

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => [
            // Title
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _currentNote.title,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Metadata
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Created: ${_formatDateTime(_currentNote.createdAt)}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Last Updated: ${_formatDateTime(_currentNote.lastEdited)}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Word Count: ${_getWordCount()}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Reading Time: ${_getReadTime()}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Content
                pw.Text(
                  _currentNote.content.isEmpty
                      ? 'No content'
                      : _currentNote.content,
                  style: const pw.TextStyle(fontSize: 12, height: 1.5),
                ),

                // Tags
                if (_currentNote.tags.isNotEmpty) ...[
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Tags',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentNote.tags
                        .map(
                          (tag) => pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue100,
                              borderRadius: pw.BorderRadius.circular(20),
                            ),
                            child: pw.Text(
                              '#$tag',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.blue800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                // Footer
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Printed from Note App • ${DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      // Get PDF bytes
      final pdfBytes = await pdf.save();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Save PDF with user selected location
      final fileName =
          'Note_${_currentNote.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Let user choose where to save
      String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: fileName,
        bytes: pdfBytes,
      );

      if (savedPath != null) {
        _showSnackBar('PDF saved successfully!');

        // Show options after saving
        if (mounted) {
          await _showPrintOptions(File(savedPath), pdfBytes);
        }
      } else {
        _showSnackBar('Save cancelled');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Error preparing PDF: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _showPrintOptions(File file, Uint8List pdfData) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Print Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.print, size: 28, color: Colors.purple),
              title: const Text('Print Now'),
              subtitle: const Text('Send to printer'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.sharePdf(
                  bytes: pdfData,
                  filename: file.path.split('/').last,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, size: 28, color: Colors.green),
              title: const Text('Share PDF'),
              subtitle: const Text('Share via email, WhatsApp, etc.'),
              onTap: () async {
                Navigator.pop(context);
                await Share.shareXFiles([
                  XFile(file.path),
                ], subject: 'Note PDF');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.folder_open,
                size: 28,
                color: Colors.blue,
              ),
              title: const Text('Open File Location'),
              subtitle: const Text('View in file manager'),
              onTap: () async {
                Navigator.pop(context);
                await _openFileLocation(file.path);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openFileLocation(String path) async {
    try {
      // Show the file location using platform channels or just inform user
      _showSnackBar('File saved at: $path');

      // For Android, you can try to open the folder
      if (Platform.isAndroid) {
        // You might want to use android_intent_plus package to open file manager
        _showSnackBar('You can find the file in your Downloads folder');
      }
    } catch (e) {
      _showSnackBar('File saved successfully');
    }
  }

  Future<void> _editNote() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditNoteScreen(note: _currentNote),
        settings: const RouteSettings(name: '/edit-note'),
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
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
