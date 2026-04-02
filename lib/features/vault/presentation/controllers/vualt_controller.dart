// lib/features/vault/presentation/controllers/vault_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/media_service.dart';
import '../../data/repositories/vault_repository.dart';
import '../../domain/entities/vault_item.dart';

class VaultController extends GetxController {
  final VaultRepository _repository;
  final MediaService _mediaService = MediaService();

  final RxList<VaultItem> items = <VaultItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs; // all, images, videos, documents

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

  Future<void> addImage() async {
    try {
      final file = await _mediaService.pickImage();
      if (file != null) {
        await _addFile(file, 'image');
      }
    } catch (e) {
      print('Error picking image: $e');
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
    }
  }

  Future<void> addFile() async {
    try {
      final file = await _mediaService.pickFile();
      if (file != null) {
        await _addFile(file, 'document');
      }
    } catch (e) {
      print('Error picking file: $e');
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
      );

      await _repository.addItem(item, file);
      await loadItems();

      Get.snackbar(
        'Success',
        'File added to vault',
        backgroundColor: Colors.green,
        colorText: Colors.white,
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
      if (searchQuery.value.isNotEmpty) {
        return item.name.toLowerCase().contains(
          searchQuery.value.toLowerCase(),
        );
      }
      return true;
    }).toList();

    // Apply type filter
    if (selectedFilter.value != 'all') {
      filtered = filtered.where((item) {
        switch (selectedFilter.value) {
          case 'images':
            return item.fileType == 'image';
          case 'videos':
            return item.fileType == 'video';
          case 'documents':
            return item.fileType == 'document';
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
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
