// lib/features/vault/presentation/screens/file_viewer_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/vault_item.dart';
import '../../../../core/constants/app_colors.dart';
import 'pdf_viewer_screen.dart'; // ADD THIS IMPORT

class FileViewerScreen extends StatefulWidget {
  const FileViewerScreen({Key? key}) : super(key: key);

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;

  File? _file;
  VaultItem? _item;

  @override
  void initState() {
    super.initState();
    _getArguments();
    _initializeViewer();
  }

  void _getArguments() {
    try {
      final arguments = Get.arguments;
      if (arguments is Map) {
        final filePath = arguments['path'] as String?;
        final itemData = arguments['item'] as VaultItem?;

        if (filePath != null) {
          _file = File(filePath);
        }
        if (itemData != null) {
          _item = itemData;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load file: $e';
      _isLoading = false;
    }
  }

  void _initializeViewer() async {
    if (_item == null || _file == null) {
      _errorMessage = 'File not found';
      _isLoading = false;
      return;
    }

    try {
      // Check if file exists
      if (!await _file!.exists()) {
        _errorMessage = 'File does not exist';
        _isLoading = false;
        return;
      }

      // Initialize video player if it's a video
      if (_item!.fileType == 'video' || _isVideoFile(_item!.name)) {
        _videoController = VideoPlayerController.file(_file!);
        await _videoController!.initialize();
        await _videoController!.setLooping(true);
        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
        });
        _videoController!.play();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading file: $e';
        _isLoading = false;
      });
    }
  }

  bool _isVideoFile(String fileName) {
    final videoExtensions = [
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.wmv',
      '.flv',
      '.webm',
    ];
    return videoExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  bool _isAudioFile(String fileName) {
    final audioExtensions = ['.mp3', '.wav', '.aac', '.m4a', '.flac', '.ogg'];
    return audioExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  bool _isPdfFile(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController!.dispose();
    }
    // Delete temporary decrypted file after a delay
    if (_file != null) {
      Future.delayed(const Duration(minutes: 5), () async {
        if (await _file!.exists()) {
          await _file!.delete();
          print('🗑️ Temporary file deleted: ${_file!.path}');
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_item?.name ?? 'Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_file == null || _item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Unable to load file')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_item!.name),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareFile),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openWithExternalApp,
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(child: _buildViewer()),
      ),
    );
  }

  Future<void> _shareFile() async {
    if (_file == null || !await _file!.exists()) {
      Get.snackbar('Error', 'File not found');
      return;
    }

    try {
      // Create a temporary copy for sharing (in case file gets deleted)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}_${_item!.name}',
      );

      // Copy the file to temp location
      await _file!.copy(tempFile.path);

      // Share the file
      await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: 'Sharing from Secure Vault');

      // Delete temp file after sharing
      Future.delayed(const Duration(seconds: 10), () async {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      });
    } catch (e) {
      print('Share error: $e');
      Get.snackbar('Error', 'Failed to share file: $e');
    }
  }

  Future<void> _openWithExternalApp() async {
    if (_file == null || !await _file!.exists()) {
      Get.snackbar('Error', 'File not found');
      return;
    }

    try {
      final result = await OpenFile.open(_file!.path);
      if (result.type != ResultType.done) {
        Get.snackbar('Error', 'No app found to open this file');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to open file');
    }
  }

  Widget _buildViewer() {
    final extension = _item!.name.split('.').last.toLowerCase();
    final isImage =
        _item!.fileType == 'image' ||
        [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
          'heic',
        ].contains(extension);

    // Handle Images
    if (isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          _file!,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Failed to load image'),
                ],
              ),
            );
          },
        ),
      );
    }

    // Handle Videos
    if ((_item!.fileType == 'video' || _isVideoFile(_item!.name)) &&
        _videoController != null &&
        _isVideoInitialized) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.primary,
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final newPosition =
                            _videoController!.value.position -
                            const Duration(seconds: 10);
                        _videoController!.seekTo(newPosition);
                      },
                      color: Colors.white,
                    ),
                    IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                      color: Colors.white,
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay_30),
                      onPressed: () {
                        final newPosition =
                            _videoController!.value.position +
                            const Duration(seconds: 10);
                        _videoController!.seekTo(newPosition);
                      },
                      color: Colors.white,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(_videoController!.value.position),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_videoController!.value.duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Handle PDF files - NOW USING THE PDF VIEWER SCREEN
    if (_isPdfFile(_item!.name)) {
      return PdfViewerScreen(filePath: _file!.path, fileName: _item!.name);
    }

    // Handle Audio files
    if (_isAudioFile(_item!.name)) {
      return _buildAudioPlayer();
    }

    // For other file types (documents, etc.)
    return _buildFallbackViewer();
  }

  // REMOVE the old _buildPdfViewer method since we're now using PdfViewerScreen
  // But keep it if you want to use it as fallback

  Widget _buildAudioPlayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[900]!, Colors.grey[800]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.audiotrack, size: 80, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            Text(
              _item!.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Audio File',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              _formatFileSize(_item!.fileSize),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _openWithExternalApp,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play with External App'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(
              _item!.fileType,
              _item!.name.split('.').last.toLowerCase(),
            ),
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Preview Not Available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'File type: ${_item!.fileType}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Name: ${_item!.name}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${_formatFileSize(_item!.fileSize)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openWithExternalApp,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with External App'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType, String extension) {
    if (fileType == 'audio' ||
        ['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg'].contains(extension)) {
      return Icons.audiotrack;
    }
    if (fileType == 'application/pdf' || extension == 'pdf') {
      return Icons.picture_as_pdf;
    }
    if (['doc', 'docx'].contains(extension)) {
      return Icons.description;
    }
    if (['xls', 'xlsx'].contains(extension)) {
      return Icons.table_chart;
    }
    if (['ppt', 'pptx'].contains(extension)) {
      return Icons.slideshow;
    }
    if (['txt', 'md', 'rtf'].contains(extension)) {
      return Icons.text_snippet;
    }
    return Icons.insert_drive_file;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
