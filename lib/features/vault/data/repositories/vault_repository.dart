// lib/features/vault/data/repositories/vault_repository.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/encryption_helper.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/vault_item.dart';
import '../models/vault_item_model.dart';

class VaultRepository {
  final LocalStorageService _storage;
  final EncryptionHelper _encryption;

  static const String vaultBox = 'vault_items'; // Use the typed box
  static const String vaultDirectory = 'vault_files';

  VaultRepository(this._storage) : _encryption = EncryptionHelper();

  Future<List<VaultItem>> getAllItems() async {
    try {
      // Use typed method
      final items = await _storage.getAllTyped<VaultItemModel>(vaultBox);
      return items.map((model) => model.toEntity()).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error loading vault items: $e');
      return [];
    }
  }

  Future<VaultItem?> getItemById(String id) async {
    try {
      final model = await _storage.getTypedById<VaultItemModel>(vaultBox, id);
      return model?.toEntity();
    } catch (e) {
      print('Error getting vault item: $e');
      return null;
    }
  }

  Future<void> addItem(VaultItem item, File file) async {
    try {
      // Encrypt and save file
      final encryptedPath = await _encryptAndSaveFile(file);

      final encryptedItem = item.copyWith(
        filePath: encryptedPath,
        isEncrypted: true,
      );

      final model = VaultItemModel.fromEntity(encryptedItem);
      await _storage.saveTyped<VaultItemModel>(vaultBox, model);
    } catch (e) {
      print('Error adding vault item: $e');
      rethrow;
    }
  }

  Future<void> updateItem(VaultItem item) async {
    try {
      final model = VaultItemModel.fromEntity(item);
      await _storage.updateTyped<VaultItemModel>(vaultBox, model);
    } catch (e) {
      print('Error updating vault item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      final item = await getItemById(id);
      if (item != null && item.filePath != null) {
        // Delete encrypted file
        final file = File(item.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _storage.deleteTyped(vaultBox, id);
    } catch (e) {
      print('Error deleting vault item: $e');
      rethrow;
    }
  }

  Future<File> getDecryptedFile(VaultItem item) async {
    try {
      if (item.filePath == null) {
        throw Exception('No file path found');
      }

      final encryptedFile = File(item.filePath!);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file not found');
      }

      return await _encryption.decryptFile(encryptedFile);
    } catch (e) {
      print('Error decrypting file: $e');
      rethrow;
    }
  }

  Future<String> _encryptAndSaveFile(File file) async {
    try {
      final encryptedFile = await _encryption.encryptFile(file);

      // Get vault directory
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(path.join(appDir.path, vaultDirectory));

      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      // Save encrypted file with unique name
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}.enc';
      final savedPath = path.join(vaultDir.path, fileName);
      await encryptedFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error encrypting and saving file: $e');
      rethrow;
    }
  }

  Future<int> getTotalSize() async {
    try {
      final items = await getAllItems();
      int totalSize = 0;
      for (final item in items) {
        final fileSize = item.fileSize is Future ? await item.fileSize : item.fileSize;
        totalSize += fileSize ?? 0;
      }
      return totalSize;
    } catch (e) {
      print('Error calculating total size: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getStats() async {
    try {
      final items = await getAllItems();
      final totalItems = items.length;
      final totalSize = items.fold(0, (sum, item) => sum + item.fileSize);
      final images = items.where((i) => i.fileType.startsWith('image')).length;
      final videos = items.where((i) => i.fileType.startsWith('video')).length;
      final documents = items.where(
        (i) => i.fileType == 'application/pdf' || i.fileType == 'document',
      ).length;

      return {
        'totalItems': totalItems,
        'totalSize': totalSize,
        'images': images,
        'videos': videos,
        'documents': documents,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {};
    }
  }
}