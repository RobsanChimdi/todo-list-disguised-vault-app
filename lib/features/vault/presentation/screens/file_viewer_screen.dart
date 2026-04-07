import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/vault_item.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/constants/app_colors.dart';

class FileViewerScreen extends StatefulWidget {
  final File file;
  final VaultItem item;

  const FileViewerScreen({Key? key, required this.file, required this.item})
    : super(key: key);

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeViewer();
  }

  void _initializeViewer() {
    if (widget.item.fileType == 'video') {
      _videoController = VideoPlayerController.file(widget.file);
      _videoController.initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.play();
      });
    }
  }

  @override
  void dispose() {
    if (widget.item.fileType == 'video') {
      _videoController.dispose();
    }
    // Delete temporary decrypted file after a delay
    Future.delayed(const Duration(seconds: 5), () {
      widget.file.delete();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareFile),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(child: _buildViewer()),
      ),
    );
  }

  Future<void> _shareFile() async {
    // Implement sharing
    Get.snackbar('Share', 'Sharing files coming soon');
  }

  Widget _buildViewer() {
    final extension = widget.item.name.split('.').last.toLowerCase();

    if (widget.item.fileType == 'image' ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          widget.file,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      );
    }

    if (widget.item.fileType == 'video') {
      if (_isVideoInitialized) {
        return Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            ),
            VideoProgressIndicator(
              _videoController,
              allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _videoController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController.value.isPlaying
                          ? _videoController.pause()
                          : _videoController.play();
                    });
                  },
                  color: Colors.white,
                ),
                IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    _videoController.seekTo(Duration.zero);
                  },
                  color: Colors.white,
                ),
              ],
            ),
          ],
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    // For PDFs and other documents, offer to open with external app
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Preview Not Available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'File type: ${widget.item.fileType}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              OpenFile.open(widget.file.path);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with External App'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
