// lib/features/vault/presentation/controllers/vault_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/media_service.dart';
import '../../data/repositories/vault_repository.dart';
import '../../domain/entities/vault_item.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class VaultController extends GetxController {
  final VaultRepository _repository;
  final MediaService _mediaService = MediaService();

  final RxList<VaultItem> items = <VaultItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs; // all, images, videos, documents
  final RxMap<String, List<VaultItem>> folders =
      <String, List<VaultItem>>{}.obs;
  final RxString currentFolder = ''.obs;

  VaultController(this._repository);

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      isLoading.value = true;
      items.value = await _repository.getAllItems();
      _organizeByFolders();
    } catch (e) {
      print('Error loading vault items: $e');
      Get.snackbar(
        'Error',
        'Failed to load vault items',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _organizeByFolders() {
    final Map<String, List<VaultItem>> folderMap = {};
    for (final item in items) {
      final folder = item.metadata?['folder'] ?? 'root';
      if (!folderMap.containsKey(folder)) {
        folderMap[folder] = [];
      }
      folderMap[folder]!.add(item);
    }
    folders.value = folderMap;
  }

  // Get file type from path
  String _getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv', 'wmv'].contains(extension)) {
      return 'video';
    } else if (['pdf'].contains(extension)) {
      return 'application/pdf';
    } else if (['doc', 'docx'].contains(extension)) {
      return 'application/msword';
    } else if (['txt'].contains(extension)) {
      return 'text/plain';
    } else {
      return 'document';
    }
  }

  Future<void> addImage() async {
    try {
      final file = await _mediaService.pickImage();
      if (file != null) {
        await _addFile(file, 'image');
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> addVideo() async {
    try {
      final file = await _mediaService.pickVideo();
      if (file != null) {
        await _addFile(file, 'video');
      }
    } catch (e) {
      print('Error picking video: $e');
      Get.snackbar(
        'Error',
        'Failed to pick video',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> addFile() async {
    try {
      final file = await _mediaService.pickFile();
      if (file != null) {
        await _addFile(file, _getFileType(file.path));
      }
    } catch (e) {
      print('Error picking file: $e');
      Get.snackbar('Error', 'Failed to pick file', backgroundColor: Colors.red);
    }
  }

  Future<void> _addFile(File file, String type) async {
    try {
      isLoading.value = true;

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      final item = VaultItem.create(
        name: fileName,
        fileType: type,
        fileSize: fileSize,
        metadata: {
          'folder': currentFolder.value.isEmpty ? 'root' : currentFolder.value,
        },
      );

      await _repository.addItem(item, file);
      await loadItems();

      Get.snackbar(
        'Success',
        'File added to vault',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error adding file: $e');
      Get.snackbar(
        'Error',
        'Failed to add file to vault',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 1. Batch import
  Future<void> batchImport(List<XFile> files) async {
    if (files.isEmpty) return;

    try {
      isLoading.value = true;
      int successCount = 0;
      int failCount = 0;

      for (final xfile in files) {
        try {
          final file = File(xfile.path);
          final fileType = _getFileType(file.path);
          await _addFile(file, fileType);
          successCount++;
        } catch (e) {
          failCount++;
          print('Error importing file: $e');
        }
      }

      await loadItems();

      Get.snackbar(
        'Import Complete',
        '$successCount files imported, $failCount failed',
        backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 2. Create folders in vault
  Future<void> createFolder(String folderName) async {
    if (folderName.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Folder name cannot be empty',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      // Create a special marker item for the folder
      final folderItem = VaultItem.create(
        name: folderName,
        fileType: 'folder',
        fileSize: 0,
        metadata: {'isFolder': true, 'folder': 'root'},
      );

      await _repository.addItem(folderItem, File('')); // Empty file for folder
      await loadItems();

      Get.snackbar(
        'Success',
        'Folder "$folderName" created',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error creating folder: $e');
      Get.snackbar(
        'Error',
        'Failed to create folder',
        backgroundColor: Colors.red,
      );
    }
  }

  // 3. Move files between folders
  Future<void> moveItem(String itemId, String newFolderId) async {
    try {
      final item = await _repository.getItemById(itemId);
      if (item == null) {
        Get.snackbar('Error', 'Item not found', backgroundColor: Colors.red);
        return;
      }

      final updatedItem = item.copyWith(
        metadata: {
          ...?item.metadata,
          'folder': newFolderId == 'root' ? 'root' : newFolderId,
        },
      );

      await _repository.updateItem(updatedItem);
      await loadItems();

      Get.snackbar(
        'Success',
        'Item moved',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      print('Error moving item: $e');
      Get.snackbar('Error', 'Failed to move item', backgroundColor: Colors.red);
    }
  }

  // 4. Share files from vault (with decryption)
  Future<void> shareItem(VaultItem item) async {
    try {
      isLoading.value = true;

      final decryptedFile = await getDecryptedFile(item);
      if (decryptedFile != null && await decryptedFile.exists()) {
        await Share.shareXFiles([
          XFile(decryptedFile.path),
        ], text: 'Sharing ${item.name} from Secure Vault');

        // Update last opened time
        final updatedItem = item.copyWith(lastOpened: DateTime.now());
        await _repository.updateItem(updatedItem);
      } else {
        Get.snackbar(
          'Error',
          'Unable to share file',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('Error sharing item: $e');
      Get.snackbar(
        'Error',
        'Failed to share file',
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 5. Secure note taking inside vault
  Future<void> createSecureNote(String title, String content) async {
    if (title.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Title cannot be empty',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Create a temporary file with the note content
      final tempDir = await Directory.systemTemp.createTemp('vault_note_');
      final noteFile = File('${tempDir.path}/$title.txt');
      await noteFile.writeAsString(content);

      final fileSize = await noteFile.length();

      final noteItem = VaultItem.create(
        name: '$title.txt',
        fileType: 'text/plain',
        fileSize: fileSize,
        metadata: {
          'isNote': true,
          'noteTitle': title,
          'noteContent': content,
          'folder': currentFolder.value.isEmpty ? 'notes' : currentFolder.value,
        },
      );

      await _repository.addItem(noteItem, noteFile);
      await loadItems();

      // Clean up temp file
      await noteFile.delete();
      await tempDir.delete();

      Get.snackbar(
        'Success',
        'Secure note created',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error creating secure note: $e');
      Get.snackbar(
        'Error',
        'Failed to create secure note',
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Navigate to folder
  void navigateToFolder(String folderName) {
    currentFolder.value = folderName;
    loadItems();
  }

  // Go back to root
  void goToRoot() {
    currentFolder.value = '';
    loadItems();
  }

  Future<void> deleteItem(VaultItem item) async {
    try {
      isLoading.value = true;
      await _repository.deleteItem(item.id);
      await loadItems();

      Get.snackbar(
        'Deleted',
        '${item.name} removed from vault',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error deleting item: $e');
      Get.snackbar(
        'Error',
        'Failed to delete item',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<File?> getDecryptedFile(VaultItem item) async {
    try {
      return await _repository.getDecryptedFile(item);
    } catch (e) {
      print('Error getting decrypted file: $e');
      return null;
    }
  }

  List<VaultItem> getFilteredItems() {
    var filtered = items.where((item) {
      // Filter by folder
      final itemFolder = item.metadata?['folder'] ?? 'root';
      final targetFolder = currentFolder.value.isEmpty
          ? 'root'
          : currentFolder.value;
      if (itemFolder != targetFolder) return false;

      // Filter by search query
      if (searchQuery.value.isNotEmpty) {
        return item.name.toLowerCase().contains(
          searchQuery.value.toLowerCase(),
        );
      }
      return true;
    }).toList();

    // Apply type filter (skip for folders)
    if (selectedFilter.value != 'all') {
      filtered = filtered.where((item) {
        // Don't filter folders
        if (item.fileType == 'folder') return true;

        switch (selectedFilter.value) {
          case 'images':
            return item.fileType == 'image';
          case 'videos':
            return item.fileType == 'video';
          case 'documents':
            return item.fileType == 'document' ||
                item.fileType == 'application/pdf' ||
                item.fileType == 'text/plain';
          default:
            return true;
        }
      }).toList();
    }

    // Sort: folders first, then by date
    filtered.sort((a, b) {
      if (a.fileType == 'folder' && b.fileType != 'folder') return -1;
      if (a.fileType != 'folder' && b.fileType == 'folder') return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  List<VaultItem> getFolders() {
    return items.where((item) => item.fileType == 'folder').toList();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<Map<String, int>> getStats() async {
    return await _repository.getStats();
  }

  Future<int> getTotalSize() async {
    return await _repository.getTotalSize();
  }

  void logout() {
    Get.find<AuthController>().logoutFromVault();
  }
}
