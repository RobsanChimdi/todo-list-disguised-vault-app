// lib/features/vault/presentation/screens/file_viewer_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';
import '../../domain/entities/vault_item.dart';
import '../../../../core/constants/app_colors.dart';

class FileViewerScreen extends StatefulWidget {
  const FileViewerScreen({Key? key}) : super(key: key);

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  File? _file;
  VaultItem? _item;

  @override
  void initState() {
    super.initState();
    _getArguments();
    _initializeViewer();
  }

  void _getArguments() {
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
  }

  void _initializeViewer() {
    if (_item != null && _item!.fileType == 'video' && _file != null) {
      _videoController = VideoPlayerController.file(_file!);
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
    if (_item != null && _item!.fileType == 'video') {
      _videoController.dispose();
    }
    // Delete temporary decrypted file after a delay
    if (_file != null) {
      Future.delayed(const Duration(seconds: 5), () {
        _file?.delete();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(child: _buildViewer()),
      ),
    );
  }

  Future<void> _shareFile() async {
    Get.snackbar('Share', 'Sharing files coming soon');
  }

  Widget _buildViewer() {
    final extension = _item!.name.split('.').last.toLowerCase();

    if (_item!.fileType == 'image' ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(_file!, fit: BoxFit.contain, width: double.infinity),
      );
    }

    if (_item!.fileType == 'video') {
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
            'File type: ${_item!.fileType}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              OpenFile.open(_file!.path);
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
