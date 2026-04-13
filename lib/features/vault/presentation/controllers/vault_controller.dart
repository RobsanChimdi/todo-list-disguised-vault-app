import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

import '../../../../core/services/media_service.dart';
import '../../data/repositories/vault_repository.dart';
import '../../domain/entities/vault_item.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class VaultController extends GetxController {
  final VaultRepository _repository;
  final MediaService _mediaService = MediaService();

  final RxList<VaultItem> items = <VaultItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString currentFolder = ''.obs;

  VaultController(this._repository);

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  @override
  void onClose() {
    // Clean up any pending operations
    super.onClose();
  }

  /// ================= LOAD =================

  Future<void> loadItems() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      final data = await _repository.getAllItems();
      items.assignAll(data);
      print('✅ Loaded ${data.length} items from vault');
    } catch (e) {
      debugPrint('Load error: $e');
      Get.snackbar(
        'Error',
        'Failed to load vault items',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh items (manual refresh)
  Future<void> refreshItems() async {
    await loadItems();
  }

  /// ================= FILE TYPE DETECTION =================

  String _getFileTypeFromPath(String filePath) {
    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceFirst('.', '');

    // Images
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'bmp',
    ].contains(extension)) {
      return 'image/$extension';
    }

    // Videos
    if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'wmv',
      'flv',
      'webm',
    ].contains(extension)) {
      return 'video/$extension';
    }

    // Audio
    if (['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg'].contains(extension)) {
      return 'audio/$extension';
    }

    // Documents
    if (extension == 'pdf') return 'application/pdf';
    if (['doc', 'docx'].contains(extension)) return 'application/msword';
    if (['xls', 'xlsx'].contains(extension)) return 'application/vnd.ms-excel';
    if (['ppt', 'pptx'].contains(extension))
      return 'application/vnd.ms-powerpoint';
    if (['txt', 'md', 'rtf'].contains(extension)) return 'text/plain';

    // Default
    return 'application/octet-stream';
  }

  String _getSimpleFileType(String mimeType) {
    if (mimeType.startsWith('image')) return 'image';
    if (mimeType.startsWith('video')) return 'video';
    if (mimeType.startsWith('audio')) return 'audio';
    if (mimeType == 'application/pdf') return 'application/pdf';
    if (mimeType.contains('document') || mimeType.contains('text'))
      return 'document';
    return 'document';
  }

  /// ================= ADD FILE =================

  Future<void> addFile() async {
    try {
      final file = await _mediaService.pickFile();
      if (file != null) {
        await _addFile(file);
      }
    } catch (e) {
      debugPrint('Pick file error: $e');
      Get.snackbar('Error', 'Failed to pick file');
    }
  }

  Future<void> addImage() async {
    try {
      final file = await _mediaService.pickImage();
      if (file != null) {
        await _addFile(file);
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> addVideo() async {
    try {
      final file = await _mediaService.pickVideo();
      if (file != null) {
        await _addFile(file);
      }
    } catch (e) {
      debugPrint('Pick video error: $e');
      Get.snackbar('Error', 'Failed to pick video');
    }
  }

  Future<void> addFileToVault(File file, String mimeType) async {
    await _addFile(file);
  }

  Future<void> _addFile(File file) async {
    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    try {
      isProcessing.value = true;
      isLoading.value = true;

      // Get file info
      final fileName = path.basename(file.path);
      final fileSize = await file.length();
      final mimeType = _getFileTypeFromPath(file.path);
      final simpleType = _getSimpleFileType(mimeType);

      // Create vault item
      final item = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        filePath: null, // Will be set by repository
        fileType: simpleType,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        lastOpened: null,
        isEncrypted: true,
        thumbnailPath: null,
        metadata: {
          'folder': currentFolder.value.isEmpty ? 'root' : currentFolder.value,
          'originalMimeType': mimeType,
          'originalPath': file.path,
        },
      );

      // Move file to vault (THIS DELETES THE ORIGINAL)
      final savedItem = await _repository.addItem(item, file);

      // ✅ Insert at beginning of list
      items.insert(0, savedItem);

      Get.snackbar(
        'Success',
        'File moved to vault: $fileName',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Add file error: $e');
      Get.snackbar(
        'Error',
        'Failed to add file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
      isProcessing.value = false;
    }
  }

  /// ================= BATCH IMPORT =================

  Future<void> batchImport(List<XFile> files) async {
    if (files.isEmpty) return;

    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    int success = 0;
    int fail = 0;
    final List<VaultItem> importedItems = [];

    try {
      isProcessing.value = true;
      isLoading.value = true;

      for (final xFile in files) {
        try {
          final file = File(xFile.path);
          final fileName = path.basename(file.path);
          final fileSize = await file.length();
          final mimeType = _getFileTypeFromPath(file.path);
          final simpleType = _getSimpleFileType(mimeType);

          final item = VaultItem(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                success.toString(),
            name: fileName,
            filePath: null,
            fileType: simpleType,
            fileSize: fileSize,
            createdAt: DateTime.now(),
            lastOpened: null,
            isEncrypted: true,
            thumbnailPath: null,
            metadata: {
              'folder': currentFolder.value.isEmpty
                  ? 'root'
                  : currentFolder.value,
              'originalMimeType': mimeType,
            },
          );

          final savedItem = await _repository.addItem(item, file);
          importedItems.add(savedItem);
          success++;

          // Small delay to prevent UI freeze
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          fail++;
          debugPrint('Batch import error for ${xFile.name}: $e');
        }
      }

      // Add all successfully imported items to the list
      if (importedItems.isNotEmpty) {
        items.insertAll(0, importedItems);
      }

      Get.snackbar(
        'Import Complete',
        '$success success, $fail failed',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Batch import error: $e');
      Get.snackbar('Error', 'Batch import failed');
    } finally {
      isLoading.value = false;
      isProcessing.value = false;
    }
  }

  /// ================= FOLDER OPERATIONS =================

  Future<void> createFolder(String folderName) async {
    if (folderName.trim().isEmpty) {
      Get.snackbar('Error', 'Folder name required');
      return;
    }

    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    try {
      isProcessing.value = true;

      final folderItem = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: folderName.trim(),
        filePath: null,
        fileType: 'folder',
        fileSize: 0,
        createdAt: DateTime.now(),
        lastOpened: null,
        isEncrypted: false,
        thumbnailPath: null,
        metadata: {
          'folder': currentFolder.value.isEmpty ? 'root' : currentFolder.value,
        },
      );

      await _repository.updateItem(folderItem);

      // Insert at beginning
      items.insert(0, folderItem);

      Get.snackbar(
        'Success',
        'Folder created: $folderName',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Create folder error: $e');
      Get.snackbar('Error', 'Failed to create folder');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> moveItem(String id, String newFolder) async {
    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    try {
      isProcessing.value = true;

      final item = await _repository.getItemById(id);
      if (item == null) {
        throw Exception('Item not found');
      }

      final updated = item.copyWith(
        metadata: {...?item.metadata, 'folder': newFolder},
      );

      await _repository.updateItem(updated);

      final index = items.indexWhere((e) => e.id == id);
      if (index != -1) {
        items[index] = updated;
      }

      Get.snackbar(
        'Success',
        'Item moved to ${newFolder == 'root' ? 'Root' : newFolder}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Move item error: $e');
      Get.snackbar('Error', 'Failed to move item');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> deleteFolder(String folderId) async {
    final item = items.firstWhereOrNull((e) => e.id == folderId);
    if (item == null || item.fileType != 'folder') return;

    // Get all items in this folder
    final folderName = item.name;
    final itemsInFolder = items
        .where((e) => e.metadata?['folder'] == folderName)
        .toList();

    if (itemsInFolder.isNotEmpty) {
      final shouldDelete = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Folder'),
          content: Text(
            'Folder "$folderName" contains ${itemsInFolder.length} items. Delete them too?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete All'),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      // Delete all items in folder
      for (final itemInFolder in itemsInFolder) {
        await deleteItem(itemInFolder);
      }
    }

    // Delete the folder itself
    await deleteItem(item);
  }

  /// ================= DELETE =================

  Future<void> deleteItem(VaultItem item) async {
    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    // Confirm deletion
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isProcessing.value = true;

      await _repository.deleteItem(item.id, permanent: true);

      items.removeWhere((e) => e.id == item.id);

      Get.snackbar(
        'Deleted',
        item.name,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      debugPrint('Delete error: $e');
      Get.snackbar('Error', 'Failed to delete item');
    } finally {
      isProcessing.value = false;
    }
  }

  /// ================= SHARE =================

  Future<void> shareItem(VaultItem item) async {
    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    File? tempFile;

    try {
      isProcessing.value = true;

      // Update last opened time
      await _repository.updateItem(item.copyWith(lastOpened: DateTime.now()));

      // Get decrypted temporary file
      tempFile = await _repository.getDecryptedFile(item);

      if (!await tempFile.exists()) {
        throw Exception('File missing');
      }

      // Share the file
      await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: 'Sharing from Vault');

      Get.snackbar(
        'Success',
        'File shared successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Share error: $e');
      Get.snackbar('Error', 'Failed to share file: ${e.toString()}');
    } finally {
      isProcessing.value = false;
      // Clean up temp file
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('Failed to delete temp file: $e');
        }
      }
    }
  }

  /// ================= RESTORE =================

  Future<void> restoreItem(VaultItem item) async {
    if (item.originalPath == null) {
      Get.snackbar('Error', 'Original path not found');
      return;
    }

    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    // Confirm restoration
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Restore File'),
        content: Text(
          'Restore "${item.name}" to original location?\n\n${item.originalPath}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isProcessing.value = true;

      await _repository.restoreToOriginalLocation(item);

      // Remove from list
      items.removeWhere((e) => e.id == item.id);

      Get.snackbar(
        'Success',
        'File restored to original location',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Restore error: $e');
      Get.snackbar('Error', 'Failed to restore file: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  /// ================= FILTERED ITEMS =================

  List<VaultItem> getFilteredItems() {
    final folderPath = currentFolder.value.isEmpty
        ? 'root'
        : currentFolder.value;

    var filtered = items.where((item) {
      final itemFolder = item.metadata?['folder'] ?? 'root';

      // Filter by folder
      if (itemFolder != folderPath) return false;

      // Filter by search query
      if (searchQuery.value.isNotEmpty) {
        return item.name.toLowerCase().contains(
          searchQuery.value.toLowerCase(),
        );
      }

      return true;
    }).toList();

    // Filter by type
    if (selectedFilter.value != 'all') {
      filtered = filtered.where((item) {
        // Always show folders
        if (item.fileType == 'folder') return true;

        switch (selectedFilter.value) {
          case 'images':
            return item.fileType == 'image';
          case 'videos':
            return item.fileType == 'video';
          case 'audio':
            return item.fileType == 'audio';
          case 'documents':
            return item.fileType == 'application/pdf' ||
                item.fileType == 'document' ||
                item.fileType.contains('text');
          default:
            return true;
        }
      }).toList();
    }

    // Sort: folders first, then by date
    filtered.sort((a, b) {
      // Folders first
      if (a.fileType == 'folder' && b.fileType != 'folder') return -1;
      if (a.fileType != 'folder' && b.fileType == 'folder') return 1;
      // Then by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  /// Get items count by type
  Map<String, int> getItemsCount() {
    final folders = items.where((i) => i.fileType == 'folder').length;
    final images = items.where((i) => i.fileType == 'image').length;
    final videos = items.where((i) => i.fileType == 'video').length;
    final documents = items
        .where(
          (i) =>
              i.fileType == 'application/pdf' ||
              i.fileType == 'document' ||
              i.fileType.contains('text'),
        )
        .length;

    return {
      'total': items.length,
      'folders': folders,
      'images': images,
      'videos': videos,
      'documents': documents,
    };
  }

  /// ================= NAVIGATION =================

  void navigateToFolder(String folderName) {
    currentFolder.value = folderName;
  }

  void goToRoot() {
    currentFolder.value = '';
  }

  void navigateBack() {
    if (currentFolder.value.isNotEmpty) {
      // Navigate to parent folder
      final parent = currentFolder.value.split('/').last;
      currentFolder.value = parent == currentFolder.value ? '' : parent;
    }
  }

  /// ================= STATS =================

  Future<Map<String, int>> getStats() async {
    return await _repository.getStats();
  }

  Future<int> getTotalSize() async {
    return await _repository.getTotalSize();
  }

  Future<String> getFormattedTotalSize() async {
    final size = await getTotalSize();
    return _formatFileSize(size);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> cleanupOrphanedFiles() async {
    if (isProcessing.value) {
      Get.snackbar('Please wait', 'Previous operation still in progress');
      return;
    }

    try {
      isProcessing.value = true;

      final deletedCount = await _repository.cleanupOrphanedFiles();

      if (deletedCount > 0) {
        Get.snackbar(
          'Cleanup Complete',
          'Removed $deletedCount orphaned files',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar('Cleanup', 'No orphaned files found');
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
      Get.snackbar('Error', 'Cleanup failed');
    } finally {
      isProcessing.value = false;
    }
  }

  void logout() {
    Get.find<AuthController>().logoutFromVault();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  /// Get decrypted file for viewing
  Future<File?> getDecryptedFile(VaultItem item) async {
    try {
      return await _repository.getDecryptedFile(item);
    } catch (e) {
      debugPrint('Get decrypted file error: $e');
      Get.snackbar('Error', 'Failed to open file');
      return null;
    }
  }

  /// Create secure note
  Future<void> createSecureNote(String title, String content) async {
    try {
      // Create a temporary text file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$title.txt');
      await tempFile.writeAsString(content);

      // Add to vault
      await _addFile(tempFile);

      // Clean up temp file
      await tempFile.delete();
    } catch (e) {
      debugPrint('Create note error: $e');
      Get.snackbar('Error', 'Failed to create secure note');
    }
  }
}
