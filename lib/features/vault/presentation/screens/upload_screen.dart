// lib/features/vault/presentation/screens/upload_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/vault_controller.dart'; // FIXED: was 'vualt_controller.dart'
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final VaultController _controller = Get.find<VaultController>();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  List<XFile> _selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload to Vault'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        actions: [
          if (_selectedFiles.isNotEmpty)
            TextButton(
              onPressed: _isUploading ? null : _uploadFiles,
              child: Text(
                'Upload (${_selectedFiles.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Upload options section
          _buildUploadOptions(),

          // Selected files list
          if (_selectedFiles.isNotEmpty) _buildSelectedFilesList(),
        ],
      ),
    );
  }

  Widget _buildUploadOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Choose files to upload',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildUploadButton(
                icon: Icons.photo_library,
                label: 'Images',
                color: Colors.blue,
                onTap: () => _pickImages(),
              ),
              _buildUploadButton(
                icon: Icons.videocam,
                label: 'Videos',
                color: Colors.red,
                onTap: () => _pickVideos(),
              ),
              _buildUploadButton(
                icon: Icons.insert_drive_file,
                label: 'Documents',
                color: Colors.green,
                onTap: () => _pickDocuments(),
              ),
              _buildUploadButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.purple,
                onTap: () => _takePhoto(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFilesList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final fileName = file.name;

          return FutureBuilder<int>(
            future: file.length(),
            builder: (context, snapshot) {
              final fileSize = snapshot.hasData
                  ? _formatFileSize(snapshot.data!)
                  : 'Loading...';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _getFileIcon(fileName),
                  title: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(fileSize),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedFiles.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return const Icon(Icons.image, color: Colors.blue, size: 32);
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return const Icon(Icons.videocam, color: Colors.red, size: 32);
    } else if (['pdf'].contains(extension)) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
    } else if (['doc', 'docx'].contains(extension)) {
      return const Icon(Icons.description, color: Colors.blue, size: 32);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images);
        });
        Get.snackbar(
          'Success',
          '${images.length} image(s) selected',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickVideos() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedFiles.add(video);
        });
        Get.snackbar(
          'Success',
          'Video selected',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickDocuments() async {
    try {
      // For documents, use file_picker
      Get.snackbar(
        'Info',
        'Document picker coming soon',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick document',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedFiles.add(photo);
        });
        Get.snackbar(
          'Success',
          'Photo captured',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to take photo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      int successCount = 0;
      int failCount = 0;

      for (final xfile in _selectedFiles) {
        try {
          final file = File(xfile.path);
          final extension = xfile.name.split('.').last.toLowerCase();
          String fileType;

          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
            fileType = 'image';
          } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
            fileType = 'video';
          } else {
            fileType = 'document';
          }

          await _controller.addFileToVault(file, fileType);
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('Error uploading ${xfile.name}: $e');
        }
      }

      Get.snackbar(
        'Upload Complete',
        '$successCount files uploaded, $failCount failed',
        backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      if (successCount > 0) {
        Get.back();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Upload failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
