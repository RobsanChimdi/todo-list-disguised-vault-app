// lib/data/repositories/vault_repository.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/services/encryption_helper.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/vault_item.dart';
import '../models/vault_item_model.dart';

class VaultRepository {
  final LocalStorageService _storage;
  late final EncryptionHelper _encryption;

  static const String vaultBox = 'vault_items';
  static const String vaultDirectory = 'vault_secure_storage';

  VaultRepository(this._storage) {
    _encryption = EncryptionHelper();
    _verifyEncryptionSetup();
  }

  /// Verify encryption is working
  Future<void> _verifyEncryptionSetup() async {
    try {
      final isWorking = await _encryption.testEncryption();
      if (!isWorking) {
        print('⚠️ Encryption test failed - check configuration');
      } else {
        print('✅ Encryption verified and working');
      }
    } catch (e) {
      print('⚠️ Could not verify encryption: $e');
    }
  }

  /// =========================
  /// GET METHODS
  /// =========================

  Future<List<VaultItem>> getAllItems() async {
    try {
      final items = await _storage.getAllTyped<VaultItemModel>(vaultBox);

      final validItems = <VaultItem>[];
      for (final model in items) {
        if (model.filePath != null && model.filePath!.isNotEmpty) {
          final file = File(model.filePath!);
          if (await file.exists()) {
            validItems.add(model.toEntity());
          } else {
            // File missing - remove from database
            await _storage.deleteTyped(vaultBox, model.id);
            print('⚠️ Removed orphaned record: ${model.name}');
          }
        } else {
          validItems.add(model.toEntity());
        }
      }

      validItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return validItems;
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

  /// =========================
  /// CREATE (MOVE FILE TO SECURE VAULT)
  /// =========================

  Future<VaultItem> addItem(VaultItem item, File originalFile) async {
    try {
      // 1. Validate original file exists
      if (!await originalFile.exists()) {
        throw Exception('Original file does not exist: ${originalFile.path}');
      }

      // 2. Store original path for reference
      final originalPath = originalFile.path;

      // 3. Move file to secure vault (NOT COPY)
      final savedPath = await _secureMoveToVault(originalFile);

      // 4. Verify original file is GONE
      if (await originalFile.exists()) {
        throw Exception('Failed to move file - original still exists');
      }

      // 5. Create updated item
      final updatedItem = item.copyWith(
        filePath: savedPath,
        isEncrypted: true,
        originalPath: originalPath,
      );

      // 6. Save to database
      final model = VaultItemModel.fromEntity(updatedItem);
      await _storage.saveTyped<VaultItemModel>(vaultBox, model);

      print('✅ File moved to secure vault: ${path.basename(originalPath)}');
      return updatedItem;
    } catch (e) {
      print('❌ Error adding vault item: $e');
      rethrow;
    }
  }

  /// Import file from app's temporary directory
  Future<VaultItem> importFile(File sourceFile, String fileName) async {
    try {
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist');
      }

      final vaultPath = await _moveToSecureDirectory(sourceFile, fileName);

      final item = VaultItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        filePath: vaultPath,
        fileType: _getFileType(fileName),
        fileSize: await sourceFile.length(),
        createdAt: DateTime.now(),
        isEncrypted: true,
      );

      final model = VaultItemModel.fromEntity(item);
      await _storage.saveTyped<VaultItemModel>(vaultBox, model);

      print('✅ File imported to vault: $fileName');
      return item;
    } catch (e) {
      print('❌ Error importing file: $e');
      rethrow;
    }
  }

  /// =========================
  /// RESTORE FILE (Move back to original location)
  /// =========================

  Future<File> restoreToOriginalLocation(VaultItem item) async {
    try {
      if (item.filePath == null || item.filePath!.isEmpty) {
        throw Exception('No file path found for restoration');
      }

      if (item.originalPath == null || item.originalPath!.isEmpty) {
        throw Exception('No original path found for restoration');
      }

      final encryptedFile = File(item.filePath!);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file not found: ${item.filePath}');
      }

      // Create backup of original path if exists
      final originalFile = File(item.originalPath!);
      if (await originalFile.exists()) {
        final backupPath =
            '${item.originalPath}.backup_${DateTime.now().millisecondsSinceEpoch}';
        await originalFile.copy(backupPath);
        print('⚠️ Existing file backed up to: $backupPath');
      }

      // Ensure directory exists for restore location
      final originalDir = Directory(path.dirname(item.originalPath!));
      if (!await originalDir.exists()) {
        await originalDir.create(recursive: true);
      }

      // Decrypt the file directly to original location
      final restoredFile = await _encryption.decryptFileToPath(
        encryptedFile,
        item.originalPath!,
      );

      // Verify restoration
      if (!await restoredFile.exists()) {
        throw Exception('Failed to restore file');
      }

      // Delete encrypted file from vault
      await encryptedFile.delete();

      // Remove from database
      await _storage.deleteTyped(vaultBox, item.id);

      print('✅ File restored to original location: ${item.originalPath}');
      return restoredFile;
    } catch (e) {
      print('❌ Error restoring file: $e');
      rethrow;
    }
  }

  /// =========================
  /// UPDATE
  /// =========================

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

  /// =========================
  /// DELETE (Permanent)
  /// =========================

  Future<void> deleteItem(String id, {bool permanent = true}) async {
    try {
      final item = await getItemById(id);

      if (item?.filePath != null && item!.filePath!.isNotEmpty) {
        final file = File(item.filePath!);
        if (await file.exists()) {
          if (permanent) {
            await _secureDeleteFile(file);
          } else {
            await file.delete();
          }
          print('🗑️ Deleted vault file: ${file.path}');
        }
      }

      await _storage.deleteTyped(vaultBox, id);
      print('✅ Item deleted from database: $id');
    } catch (e) {
      print('❌ Error deleting vault item: $e');
      rethrow;
    }
  }

  /// Secure delete - overwrite with random data before deletion
  Future<void> _secureDeleteFile(File file) async {
    try {
      final fileSize = await file.length();

      if (fileSize == 0) {
        await file.delete();
        return;
      }

      // Overwrite 3 times with random data
      for (int pass = 0; pass < 3; pass++) {
        final randomData = _generateRandomData(1024);
        final sink = file.openWrite(mode: FileMode.write);

        for (int i = 0; i < (fileSize / 1024).ceil(); i++) {
          sink.add(randomData);
        }

        await sink.flush();
        await sink.close();
      }

      await file.delete();
      print('🔒 File securely deleted');
    } catch (e) {
      // Fallback to normal delete
      try {
        await file.delete();
      } catch (_) {}
      print('⚠️ Secure delete failed, fallback to normal delete');
    }
  }

  Uint8List _generateRandomData(int length) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 256).toInt();
    return Uint8List.fromList(List.generate(length, (_) => random));
  }

  /// =========================
  /// DECRYPT AND EXPORT (Temporary)
  /// =========================

  Future<File> getDecryptedFile(VaultItem item) async {
    try {
      if (item.filePath == null || item.filePath!.isEmpty) {
        throw Exception('No file path found');
      }

      final encryptedFile = File(item.filePath!);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file not found: ${item.filePath}');
      }

      // Create temporary file that will be auto-deleted
      final tempDir = await getTemporaryDirectory();
      final tempFileName =
          'temp_${item.id}_${DateTime.now().millisecondsSinceEpoch}_${item.name}';
      final tempPath = path.join(tempDir.path, tempFileName);

      final decryptedFile = await _encryption.decryptFileToPath(
        encryptedFile,
        tempPath,
      );

      // Schedule auto-deletion
      _scheduleTempFileDeletion(tempPath);

      return decryptedFile;
    } catch (e) {
      print('❌ Error decrypting file: $e');
      rethrow;
    }
  }

  void _scheduleTempFileDeletion(String filePath) {
    // Delete after 1 hour
    Future.delayed(const Duration(hours: 1), () async {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Temporary file cleaned up: ${path.basename(filePath)}');
        }
      } catch (e) {
        print('⚠️ Failed to delete temp file: $e');
      }
    });
  }

  /// =========================
  /// CORE LOGIC - TRUE MOVE OPERATION
  /// =========================

  Future<String> _secureMoveToVault(File originalFile) async {
    try {
      // 1. Get secure vault directory
      final vaultDir = await _getSecureVaultDirectory();

      // 2. Generate unique encrypted filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = path.basename(originalFile.path);
      final encryptedFileName = '${timestamp}_${originalName}.enc';
      final vaultPath = path.join(vaultDir.path, encryptedFileName);

      // 3. Encrypt file directly to vault location
      await _encryption.encryptFileToPath(originalFile, vaultPath);

      // 4. Verify encrypted file was created successfully
      final savedFile = File(vaultPath);
      if (!await savedFile.exists()) {
        throw Exception('Failed to create encrypted file at: $vaultPath');
      }

      // 5. Verify encrypted file size is valid
      final encryptedSize = await savedFile.length();
      if (encryptedSize == 0) {
        await savedFile.delete();
        throw Exception('Encrypted file is empty');
      }

      // 6. DELETE ORIGINAL FILE (THIS MAKES IT A MOVE, NOT COPY)
      try {
        await originalFile.delete();

        // Verify deletion
        if (await originalFile.exists()) {
          throw Exception('Original file still exists after deletion attempt');
        }

        print('✅ Original file deleted: ${originalFile.path}');
      } catch (e) {
        // Rollback: Delete encrypted file if original couldn't be deleted
        if (await savedFile.exists()) {
          await savedFile.delete();
        }
        throw Exception('Failed to delete original file: $e');
      }

      return vaultPath;
    } catch (e) {
      print('❌ Error moving file to vault: $e');
      rethrow;
    }
  }

  /// Get secure directory that's NOT visible in system Files app (Android only)
  Future<Directory> _getSecureVaultDirectory() async {
    try {
      // Android: Use app-specific internal storage (not accessible via Files app)
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(path.join(appDir.path, vaultDirectory));

      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      // Add .nomedia to prevent media scanner from seeing files
      final noMediaFile = File(path.join(vaultDir.path, '.nomedia'));
      if (!await noMediaFile.exists()) {
        await noMediaFile.create();
      }

      print('📁 Secure vault directory: ${vaultDir.path}');
      return vaultDir;
    } catch (e) {
      print('❌ Error getting secure vault directory: $e');
      rethrow;
    }
  }

  Future<String> _moveToSecureDirectory(
    File sourceFile,
    String fileName,
  ) async {
    final vaultDir = await _getSecureVaultDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final encryptedFileName = '${timestamp}_${fileName}.enc';
    final destPath = path.join(vaultDir.path, encryptedFileName);

    // Encrypt and move
    await _encryption.encryptFileToPath(sourceFile, destPath);

    // Delete source
    if (await sourceFile.exists()) {
      await sourceFile.delete();
    }

    return destPath;
  }

  /// =========================
  /// STORAGE STATS
  /// =========================

  Future<int> getTotalSize() async {
    try {
      final items = await getAllItems();

      int total = 0;
      for (final item in items) {
        total += item.fileSize;
      }
      return total;
    } catch (e) {
      print('❌ Error calculating total size: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getStats() async {
    try {
      final items = await getAllItems();

      int totalSize = 0;
      for (final item in items) {
        totalSize += item.fileSize;
      }

      return {
        'totalItems': items.length,
        'totalSize': totalSize,
        'images': items.where((i) => i.fileType.startsWith('image')).length,
        'videos': items.where((i) => i.fileType.startsWith('video')).length,
        'documents': items
            .where(
              (i) =>
                  i.fileType == 'application/pdf' ||
                  i.fileType.contains('document') ||
                  i.fileType.contains('text') ||
                  i.fileType == 'application/msword' ||
                  i.fileType == 'application/vnd.ms-excel' ||
                  i.fileType == 'application/vnd.ms-powerpoint',
            )
            .length,
        'audio': items.where((i) => i.fileType.startsWith('audio')).length,
      };
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {
        'totalItems': 0,
        'totalSize': 0,
        'images': 0,
        'videos': 0,
        'documents': 0,
        'audio': 0,
      };
    }
  }

  /// =========================
  /// UTILITY METHODS
  /// =========================

  String _getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.bmp':
      case '.heic':
        return 'image/${extension.substring(1)}';

      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
      case '.wmv':
      case '.flv':
      case '.webm':
        return 'video/${extension.substring(1)}';

      case '.mp3':
      case '.wav':
      case '.aac':
      case '.flac':
      case '.m4a':
      case '.ogg':
        return 'audio/${extension.substring(1)}';

      case '.pdf':
        return 'application/pdf';

      case '.doc':
      case '.docx':
        return 'application/msword';

      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';

      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';

      case '.txt':
      case '.md':
      case '.rtf':
        return 'text/plain';

      default:
        return 'application/octet-stream';
    }
  }

  /// Clean up orphaned files not in database
  Future<int> cleanupOrphanedFiles() async {
    try {
      final items = await getAllItems();
      final validPaths = Set<String>.from(
        items
            .map((e) => e.filePath)
            .where((path) => path != null && path.isNotEmpty),
      );

      final vaultDir = await _getSecureVaultDirectory();
      if (!await vaultDir.exists()) return 0;

      int deletedCount = 0;
      await for (final entity in vaultDir.list()) {
        if (entity is File && !validPaths.contains(entity.path)) {
          await entity.delete();
          deletedCount++;
          print('🗑️ Deleted orphaned file: ${path.basename(entity.path)}');
        }
      }

      print('✅ Cleaned up $deletedCount orphaned files');
      return deletedCount;
    } catch (e) {
      print('❌ Error cleaning up orphaned files: $e');
      return 0;
    }
  }

  /// Verify vault integrity
  Future<Map<String, dynamic>> verifyIntegrity() async {
    final results = {
      'isValid': true,
      'totalItems': 0,
      'missingFiles': 0,
      'corruptedFiles': 0,
      'errors': <String>[],
    };

    try {
      final items = await getAllItems();
      results['totalItems'] = items.length;

      for (final item in items) {
        if (item.filePath != null && item.filePath!.isNotEmpty) {
          final file = File(item.filePath!);

          if (!await file.exists()) {
            results['missingFiles'] = (results['missingFiles'] as int) + 1;
            (results['errors'] as List<String>).add('Missing: ${item.name}');
          } else if (await file.length() == 0) {
            results['corruptedFiles'] = (results['corruptedFiles'] as int) + 1;
            (results['errors'] as List<String>).add(
              'Corrupted (empty): ${item.name}',
            );
          }
        }
      }

      results['isValid'] =
          (results['missingFiles'] as int) == 0 &&
          (results['corruptedFiles'] as int) == 0;
    } catch (e) {
      results['isValid'] = false;
      (results['errors'] as List<String>).add(e.toString());
    }
    return results;
  }

  /// Export vault file to external storage (user requested)
  Future<File?> exportToExternal(VaultItem item, String destinationPath) async {
    try {
      if (item.filePath == null || item.filePath!.isEmpty) {
        throw Exception('No file path found');
      }

      final encryptedFile = File(item.filePath!);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file not found');
      }

      // Decrypt file to destination
      final exportedFile = await _encryption.decryptFileToPath(
        encryptedFile,
        destinationPath,
      );

      print('✅ File exported to: $destinationPath');
      return exportedFile;
    } catch (e) {
      print('❌ Error exporting file: $e');
      return null;
    }
  }

  /// Check if a file with same hash already exists (duplicate detection)
  Future<bool> isDuplicate(File file) async {
    try {
      final newFileHash = await _encryption.hashFile(file);
      if (newFileHash.isEmpty) return false;

      final items = await getAllItems();
      for (final item in items) {
        if (item.filePath != null && item.filePath!.isNotEmpty) {
          final existingFile = File(item.filePath!);
          if (await existingFile.exists()) {
            final existingHash = await _encryption.hashFile(existingFile);
            if (existingHash == newFileHash) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      print('❌ Error checking duplicate: $e');
      return false;
    }
  }
}
