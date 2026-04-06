// lib/core/services/media_service.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class MediaService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick a single image from gallery or camera
  /// [source] - ImageSource.gallery or ImageSource.camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  /// Pick a video from gallery or camera
  /// [source] - ImageSource.gallery or ImageSource.camera
  Future<File?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Pick any file type (documents, PDFs, etc.)
  /// [allowedExtensions] - e.g., ['pdf', 'doc', 'docx', 'txt']
  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: allowedExtensions == null ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          return File(filePath);
        }
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Pick multiple files
  Future<List<File>> pickMultipleFiles({
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: allowedExtensions == null ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error picking multiple files: $e');
      return [];
    }
  }

  /// Pick a PDF file specifically
  Future<File?> pickPDF() async {
    return await pickFile(allowedExtensions: ['pdf']);
  }

  /// Pick a document (Word, Excel, PowerPoint)
  Future<File?> pickDocument() async {
    return await pickFile(
      allowedExtensions: ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
    );
  }

  /// Pick a text file
  Future<File?> pickTextFile() async {
    return await pickFile(allowedExtensions: ['txt', 'md']);
  }

  /// Pick an audio file
  Future<File?> pickAudio() async {
    return await pickFile(allowedExtensions: ['mp3', 'wav', 'aac', 'm4a']);
  }

  /// Take a photo with camera
  Future<File?> takePhoto() async {
    return await pickImage(source: ImageSource.camera);
  }

  /// Record a video with camera
  Future<File?> recordVideo() async {
    return await pickVideo(source: ImageSource.camera);
  }

  /// Get file information
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final extension = fileName.split('.').last.toLowerCase();

      return {
        'name': fileName,
        'size': fileSize,
        'extension': extension,
        'path': file.path,
        'exists': await file.exists(),
      };
    } catch (e) {
      print('Error getting file info: $e');
      return {};
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file is an image
  bool isImageFile(String filePath) {
    final imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
    ];
    final extension = filePath.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  /// Check if file is a video
  bool isVideoFile(String filePath) {
    final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm'];
    final extension = filePath.split('.').last.toLowerCase();
    return videoExtensions.contains(extension);
  }

  /// Check if file is an audio file
  bool isAudioFile(String filePath) {
    final audioExtensions = ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'];
    final extension = filePath.split('.').last.toLowerCase();
    return audioExtensions.contains(extension);
  }

  /// Check if file is a document
  bool isDocumentFile(String filePath) {
    final documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'md', 'rtf'];
    final extension = filePath.split('.').last.toLowerCase();
    return documentExtensions.contains(extension);
  }

  /// Get icon for file type
  IconData getFileIcon(String filePath) {
    if (isImageFile(filePath)) {
      return Icons.image;
    } else if (isVideoFile(filePath)) {
      return Icons.videocam;
    } else if (isAudioFile(filePath)) {
      return Icons.audiotrack;
    } else if (filePath.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (filePath.endsWith('.doc') || filePath.endsWith('.docx')) {
      return Icons.description;
    } else if (filePath.endsWith('.txt')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  /// Get color for file type
  Color getFileColor(String filePath) {
    if (isImageFile(filePath)) {
      return Colors.blue;
    } else if (isVideoFile(filePath)) {
      return Colors.red;
    } else if (isAudioFile(filePath)) {
      return Colors.purple;
    } else if (filePath.endsWith('.pdf')) {
      return Colors.red.shade700;
    } else if (filePath.endsWith('.doc') || filePath.endsWith('.docx')) {
      return Colors.blue.shade700;
    } else if (filePath.endsWith('.txt')) {
      return Colors.grey;
    } else {
      return Colors.green;
    }
  }

  /// Create a temporary file from bytes
  Future<File> createTempFile(String fileName, List<int> bytes) async {
    final tempDir = await Directory.systemTemp.createTemp('media_');
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Delete temporary file
  Future<void> deleteTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        final dir = file.parent;
        await dir.delete();
      }
    } catch (e) {
      print('Error deleting temp file: $e');
    }
  }
}
