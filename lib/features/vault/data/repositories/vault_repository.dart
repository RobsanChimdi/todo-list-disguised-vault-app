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
  late final EncryptionHelper _encryption;

  static const String vaultBox = 'vault_items_box';
  static const String vaultDirectory = 'vault_secure_storage';

  VaultRepository(this._storage) {
    _encryption = EncryptionHelper();
  }

  Future<List<VaultItem>> getAllItems() async {
    try {
      final items = await _storage.getAllTyped<VaultItemModel>(vaultBox);
      print('📦 Retrieved ${items.length} items from database');

      return items.map((e) => e.toEntity()).toList();
    } catch (e) {
      print('❌ Error loading vault items: $e');
      return [];
    }
  }

  Future<VaultItem?> getItemById(String id) async {
    try {
      final model = await _storage.getTypedById<VaultItemModel>(vaultBox, id);
      return model?.toEntity();
    } catch (e) {
      print('❌ Error getting vault item: $e');
      return null;
    }
  }

  Future<VaultItem> addItem(VaultItem item, File originalFile) async {
    try {
      String? savedPath;

      // Only encrypt and save if it's not a folder
      if (item.fileType != 'folder' &&
          await originalFile.exists() &&
          originalFile.path.isNotEmpty) {
        savedPath = await _secureMoveToVault(originalFile);
      }

      final updatedItem = item.copyWith(
        filePath: savedPath,
        isEncrypted: item.fileType != 'folder',
      );

      final model = VaultItemModel.fromEntity(updatedItem);
      await _storage.saveTyped<VaultItemModel>(vaultBox, model);

      print('✅ Added item: ${item.name} (${item.fileType})');
      return updatedItem;
    } catch (e) {
      print('❌ Error adding vault item: $e');
      rethrow;
    }
  }

  Future<void> updateItem(VaultItem item) async {
    try {
      final model = VaultItemModel.fromEntity(item);
      await _storage.updateTyped<VaultItemModel>(vaultBox, model);
      print('✅ Item updated: ${item.name}');
    } catch (e) {
      print('❌ Error updating vault item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      final item = await getItemById(id);

      if (item?.filePath != null && item!.filePath!.isNotEmpty) {
        final file = File(item.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await _storage.deleteTyped(vaultBox, id);
      print('✅ Item deleted: $id');
    } catch (e) {
      print('❌ Error deleting vault item: $e');
      rethrow;
    }
  }

  Future<File> getDecryptedFile(VaultItem item) async {
    try {
      if (item.filePath == null || item.filePath!.isEmpty) {
        throw Exception('No file path found');
      }

      final encryptedFile = File(item.filePath!);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file not found');
      }

      return await _encryption.decryptFile(encryptedFile);
    } catch (e) {
      print('❌ Error decrypting file: $e');
      rethrow;
    }
  }

  Future<String> _secureMoveToVault(File originalFile) async {
    try {
      final vaultDir = await _getSecureVaultDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = path.basename(originalFile.path);
      final encryptedFileName = '${timestamp}_${originalName}.enc';
      final vaultPath = path.join(vaultDir.path, encryptedFileName);

      await _encryption.encryptFileToPath(originalFile, vaultPath);

      final savedFile = File(vaultPath);
      if (!await savedFile.exists()) {
        throw Exception('Failed to create encrypted file');
      }

      // Delete original file if it exists and is not a test file
      if (await originalFile.exists() && originalFile.path.isNotEmpty) {
        await originalFile.delete();
      }

      return vaultPath;
    } catch (e) {
      print('❌ Error moving file to vault: $e');
      rethrow;
    }
  }

  Future<Directory> _getSecureVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(path.join(appDir.path, vaultDirectory));

    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    return vaultDir;
  }

  Future<int> getTotalSize() async {
    try {
      final items = await getAllItems();
      int total = 0;
      for (final item in items) {
        total += item.fileSize;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> getStats() async {
    try {
      final items = await getAllItems();
      return {
        'totalItems': items.length,
        'totalSize': items.fold(0, (sum, i) => sum + i.fileSize),
        'images': items.where((i) => i.fileType.startsWith('image')).length,
        'videos': items.where((i) => i.fileType == 'video').length,
        'documents': items
            .where(
              (i) =>
                  i.fileType == 'document' || i.fileType == 'application/pdf',
            )
            .length,
        'audio': items.where((i) => i.fileType == 'audio').length,
      };
    } catch (e) {
      return {};
    }
  }
}
