// lib/features/vault/presentation/controllers/vault_controller.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_first_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/encryption_helper.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/repositories/vault_repository.dart';
import '../../domain/entities/vault_item.dart';
import 'package:share_plus/share_plus.dart';

class VaultController extends GetxController {
  final VaultRepository _repository;
  final EncryptionHelper _encryptionHelper = EncryptionHelper();
  final ImagePicker _imagePicker = ImagePicker();

  // Observable state
  var items = <VaultItem>[].obs;
  var isLoading = false.obs;
  var currentFolder = ''.obs;
  var selectedFilter = 'all'.obs;
  var searchQuery = ''.obs;

  // Predefined folders
  static const List<String> predefinedFolders = [
    'Images',
    'Videos',
    'Documents',
    'Audio',
  ];

  VaultController(this._repository);

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  Future<void> loadItems() async {
    isLoading.value = true;
    try {
      final allItems = await _repository.getAllItems();
      items.value = allItems;
      print('✅ Loaded ${allItems.length} items');

      // Initialize predefined folders after loading
      await _initializePredefinedFolders();
    } catch (e) {
      print('Error loading items: $e');
      Get.snackbar('Error', 'Failed to load vault items');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializePredefinedFolders() async {
    try {
      final existingFolders = items
          .where((item) => item.fileType == 'folder')
          .toList();
      final existingFolderNames = existingFolders.map((f) => f.name).toList();

      print('Existing folders: $existingFolderNames');

      for (final folderName in predefinedFolders) {
        if (!existingFolderNames.contains(folderName)) {
          print('Creating predefined folder: $folderName');
          await createPredefinedFolder(folderName);
        }
      }
    } catch (e) {
      print('Error initializing predefined folders: $e');
    }
  }

  Future<void> createPredefinedFolder(String folderName) async {
    try {
      final folderItem = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: folderName,
        filePath: null,
        fileSize: 0,
        fileType: 'folder',
        createdAt: DateTime.now(),
        isEncrypted: false,
        parentFolder: null,
      );

      await _repository.addItem(folderItem, File(''));
      print('✅ Created predefined folder: $folderName');

      // Refresh items to show the new folder
      final allItems = await _repository.getAllItems();
      items.value = allItems;
    } catch (e) {
      print('Error creating predefined folder $folderName: $e');
    }
  }

  Future<void> refreshItems() async {
    await loadItems();
  }

  List<VaultItem> getFilteredItems() {
    var filtered = items.where((item) {
      // Filter by current folder
      if (currentFolder.value.isNotEmpty) {
        if (item.parentFolder != currentFolder.value) {
          return false;
        }
      } else {
        // In root, only show folders (items without parent folder)
        if (item.parentFolder != null && item.parentFolder!.isNotEmpty) {
          return false;
        }
      }

      // Filter by type
      if (selectedFilter.value != 'all') {
        if (selectedFilter.value == 'images' &&
            !item.fileType.startsWith('image')) {
          return false;
        }
        if (selectedFilter.value == 'videos' && item.fileType != 'video') {
          return false;
        }
        if (selectedFilter.value == 'documents' &&
            ![
              'application/pdf',
              'document',
              'text',
              'note',
            ].contains(item.fileType)) {
          return false;
        }
      }

      // Search filter
      if (searchQuery.value.isNotEmpty) {
        return item.name.toLowerCase().contains(
          searchQuery.value.toLowerCase(),
        );
      }

      return true;
    }).toList();

    // Sort: folders first, then by date
    filtered.sort((a, b) {
      if (a.fileType == 'folder' && b.fileType != 'folder') return -1;
      if (a.fileType != 'folder' && b.fileType == 'folder') return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  Future<void> addImageToFolder(String folderName) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        await _addFileToFolder(File(image.path), folderName, 'image');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  Future<void> captureImageToFolder(String folderName) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        await _addFileToFolder(File(image.path), folderName, 'image');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image: $e');
    }
  }

  Future<void> addVideoToFolder(String folderName) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        await _addFileToFolder(File(video.path), folderName, 'video');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video: $e');
    }
  }

  Future<void> addAudioToFolder(String folderName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _addFileToFolder(
          File(result.files.single.path!),
          folderName,
          'audio',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick audio: $e');
    }
  }

  Future<void> addDocumentToFolder(String folderName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = file.path.split('.').last.toLowerCase();
        String fileType = 'document';

        if (extension == 'pdf') {
          fileType = 'application/pdf';
        } else if (['doc', 'docx'].contains(extension)) {
          fileType = 'application/msword';
        }

        await _addFileToFolder(file, folderName, fileType);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick document: $e');
    }
  }

  Future<void> addNoteToFolder(String folderName) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        title: const Text('Create Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Note title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'Note content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                isLoading.value = true;
                try {
                  final tempDir = await getTemporaryDirectory();
                  final noteFile = File(
                    '${tempDir.path}/${titleController.text.trim()}.txt',
                  );
                  await noteFile.writeAsString(contentController.text);

                  await _addFileToFolder(noteFile, folderName, 'text');

                  if (await noteFile.exists()) {
                    await noteFile.delete();
                  }

                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  Get.snackbar('Success', 'Note created successfully');
                } catch (e) {
                  Get.snackbar('Error', 'Failed to create note: $e');
                } finally {
                  isLoading.value = false;
                }
              } else {
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFileToFolder(
    File file,
    String folderName,
    String fileType,
  ) async {
    isLoading.value = true;
    try {
      final vaultItem = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: file.path.split('/').last,
        filePath: '',
        fileSize: await file.length(),
        fileType: fileType,
        createdAt: DateTime.now(),
        isEncrypted: true,
        parentFolder: folderName,
        originalPath: file.path,
      );

      await _repository.addItem(vaultItem, file);
      await loadItems();

      Get.snackbar(
        'Success',
        'File added to $folderName folder',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to add file: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addFileToVault(File file, String fileType) async {
    try {
      final vaultItem = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: file.path.split('/').last,
        filePath: '',
        fileSize: await file.length(),
        fileType: fileType,
        createdAt: DateTime.now(),
        isEncrypted: true,
        parentFolder: currentFolder.value.isNotEmpty
            ? currentFolder.value
            : null,
        originalPath: file.path,
      );

      await _repository.addItem(vaultItem, file);
      await loadItems();

      Get.snackbar(
        'Success',
        'File added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to add file: $e');
      rethrow;
    }
  }

  Future<void> createCustomFolder(String folderName) async {
    if (predefinedFolders.contains(folderName)) {
      Get.snackbar('Error', 'Folder name already exists');
      return;
    }

    // Check if folder already exists
    final existingFolder = items.any(
      (item) =>
          item.fileType == 'folder' &&
          item.name == folderName &&
          item.parentFolder == currentFolder.value,
    );

    if (existingFolder) {
      Get.snackbar('Error', 'A folder with this name already exists');
      return;
    }

    isLoading.value = true;
    try {
      final folderItem = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: folderName,
        filePath: null,
        fileSize: 0,
        fileType: 'folder',
        createdAt: DateTime.now(),
        isEncrypted: false,
        parentFolder: currentFolder.value.isEmpty ? null : currentFolder.value,
      );

      await _repository.addItem(folderItem, File(''));
      await loadItems();

      Get.snackbar('Success', 'Folder "$folderName" created');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create folder: ${e.toString()}');
      print('Error creating folder: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToFolder(String folderName) {
    currentFolder.value = folderName;
    selectedFilter.value = 'all';
    searchQuery.value = '';
  }

  void goToRoot() {
    currentFolder.value = '';
    selectedFilter.value = 'all';
    searchQuery.value = '';
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> deleteItem(VaultItem item) async {
    try {
      await _repository.deleteItem(item.id);
      await loadItems();
      Get.snackbar('Success', '${item.name} deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e');
    }
  }

  Future<File?> getDecryptedFile(VaultItem item) async {
    try {
      return await _repository.getDecryptedFile(item);
    } catch (e) {
      Get.snackbar('Error', 'Failed to decrypt file: $e');
      return null;
    }
  }

  // Add this method to VaultController class

  Future<void> shareItem(VaultItem item) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final file = await getDecryptedFile(item);

      Get.back(); // Close loading dialog

      if (file != null && await file.exists()) {
        // Create a temporary copy for sharing
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}_${item.name}',
        );

        // Copy the file to temp location
        await file.copy(tempFile.path);

        // Share the file
        await Share.shareXFiles([
          XFile(tempFile.path),
        ], text: 'Sharing from Secure Vault');

        // Delete temp file after sharing
        Future.delayed(const Duration(seconds: 30), () async {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        });
      } else {
        Get.snackbar('Error', 'Failed to share file: File not found');
      }
    } catch (e) {
      Get.back(); // Close loading dialog if still open
      print('Share error: $e');
      Get.snackbar('Error', 'Failed to share file: $e');
    }
  }
  // In vault_controller.dart, update the logout method:

  void logout() async {
    try {
      // Show confirmation dialog first
      final shouldLogout = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Clear any sensitive data
        items.clear();
        currentFolder.value = '';
        selectedFilter.value = 'all';
        searchQuery.value = '';

        // Call auth controller logout
        final authController = Get.find<AuthController>();
        await authController.logout();
      }
    } catch (e) {
      print('Logout error: $e');
      Get.snackbar('Error', 'Failed to logout');
    }
  }
}
