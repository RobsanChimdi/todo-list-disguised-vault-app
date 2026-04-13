// lib/core/services/encryption_helper.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  // Secure storage for keys (never hardcode in production!)
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();
  static const String _keyStorageKey = 'vault_master_key';
  static const String _ivStorageKey = 'vault_iv_key';

  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;
  bool _isInitialized = false;

  EncryptionHelper() {
    _initEncryption();
  }

  /// Initialize encryption with secure keys
  Future<void> _initEncryption() async {
    if (_isInitialized) return;

    try {
      // Try to get existing keys
      String? keyBase64 = await _secureStorage.read(key: _keyStorageKey);
      String? ivBase64 = await _secureStorage.read(key: _ivStorageKey);

      if (keyBase64 == null || ivBase64 == null) {
        // Generate new secure keys
        final keyBytes = _generateSecureKey(32); // 256 bits for AES-256
        final ivBytes = _generateSecureKey(16); // 128 bits for AES-CBC

        keyBase64 = base64Encode(keyBytes);
        ivBase64 = base64Encode(ivBytes);

        // Store securely
        await _secureStorage.write(key: _keyStorageKey, value: keyBase64);
        await _secureStorage.write(key: _ivStorageKey, value: ivBase64);
      }

      // Initialize encryption
      _key = encrypt.Key.fromBase64(keyBase64);
      _iv = encrypt.IV.fromBase64(ivBase64);
      _encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );
      _isInitialized = true;

      print('✅ Encryption helper initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize encryption: $e');
      rethrow;
    }
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateSecureKey(int length) {
    final random = _getSecureRandom();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Get secure random generator
  Random _getSecureRandom() {
    if (kIsWeb) {
      // Web fallback - still reasonably random
      return Random.secure();
    } else {
      // Native platforms
      return Random.secure();
    }
  }

  /// Ensure encryption is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initEncryption();
    }
  }

  /// Encrypt file directly to path (optimized for all file sizes)
  Future<void> encryptFileToPath(File inputFile, String outputPath) async {
    await _ensureInitialized();

    try {
      final fileSize = await inputFile.length();

      // Use chunked encryption for files > 10MB
      if (fileSize > 10 * 1024 * 1024) {
        await _encryptFileChunked(inputFile, outputPath);
      } else {
        await _encryptFileDirect(inputFile, outputPath);
      }
    } catch (e) {
      print('❌ Error encrypting file to path: $e');
      rethrow;
    }
  }

  /// Direct encryption for smaller files
  Future<void> _encryptFileDirect(File inputFile, String outputPath) async {
    final fileBytes = await inputFile.readAsBytes();
    final encrypted = _encrypter.encryptBytes(fileBytes, iv: _iv);

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(encrypted.bytes);
  }

  /// Chunked encryption for large files (memory efficient)
  Future<void> _encryptFileChunked(File inputFile, String outputPath) async {
    const chunkSize = 64 * 1024; // 64KB chunks
    final inputStream = inputFile.openRead();
    final outputFile = File(outputPath);
    final outputSink = outputFile.openWrite();

    try {
      await for (final chunk in inputStream) {
        final encrypted = _encrypter.encryptBytes(chunk, iv: _iv);
        outputSink.add(encrypted.bytes);
      }
      await outputSink.flush();
    } catch (e) {
      await outputSink.close();
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      rethrow;
    } finally {
      await outputSink.close();
    }
  }

  /// Decrypt file to path
  Future<File> decryptFileToPath(File encryptedFile, String outputPath) async {
    await _ensureInitialized();

    try {
      final fileSize = await encryptedFile.length();

      // Use chunked decryption for files > 10MB
      if (fileSize > 10 * 1024 * 1024) {
        await _decryptFileChunked(encryptedFile, outputPath);
      } else {
        await _decryptFileDirect(encryptedFile, outputPath);
      }

      return File(outputPath);
    } catch (e) {
      print('❌ Error decrypting file to path: $e');
      rethrow;
    }
  }

  /// Direct decryption for smaller files
  Future<void> _decryptFileDirect(File encryptedFile, String outputPath) async {
    final encryptedBytes = await encryptedFile.readAsBytes();
    final decrypted = _encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: _iv,
    );

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(decrypted);
  }

  /// Chunked decryption for large files
  Future<void> _decryptFileChunked(
    File encryptedFile,
    String outputPath,
  ) async {
    const chunkSize = 64 * 1024; // 64KB chunks
    final encryptedBytes = await encryptedFile.readAsBytes();
    final outputFile = File(outputPath);
    final outputSink = outputFile.openWrite();

    try {
      for (int i = 0; i < encryptedBytes.length; i += chunkSize) {
        final end = (i + chunkSize) < encryptedBytes.length
            ? i + chunkSize
            : encryptedBytes.length;
        final chunk = encryptedBytes.sublist(i, end);
        final decrypted = _encrypter.decryptBytes(
          encrypt.Encrypted(chunk),
          iv: _iv,
        );
        outputSink.add(decrypted);
      }
      await outputSink.flush();
    } catch (e) {
      await outputSink.close();
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      rethrow;
    } finally {
      await outputSink.close();
    }
  }

  /// Legacy method: Encrypt file and return File object
  Future<File> encryptFile(File inputFile) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/encrypted_${DateTime.now().millisecondsSinceEpoch}.enc';
    await encryptFileToPath(inputFile, outputPath);
    return File(outputPath);
  }

  /// Legacy method: Decrypt file and return File object
  Future<File> decryptFile(File encryptedFile) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/decrypted_${DateTime.now().millisecondsSinceEpoch}.tmp';
    return await decryptFileToPath(encryptedFile, outputPath);
  }

  /// Generate a hash of file content for duplicate detection
  Future<String> hashFile(File file) async {
    await _ensureInitialized();

    try {
      // Read first 1MB for hash (fast and efficient)
      final bytes = await file.readAsBytes();
      final sampleSize = bytes.length < 1024 * 1024
          ? bytes.length
          : 1024 * 1024;
      final sample = bytes.sublist(0, sampleSize);
      final hash = _encrypter.encryptBytes(sample, iv: _iv);
      return hash.base64.substring(0, 32);
    } catch (e) {
      print('❌ Error hashing file: $e');
      return '';
    }
  }

  /// Encrypt a string
  String encryptString(String plainText) {
    _ensureInitialized();
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt a string
  String decryptString(String encryptedText) {
    _ensureInitialized();
    try {
      final decrypted = _encrypter.decrypt(
        encrypt.Encrypted.fromBase64(encryptedText),
        iv: _iv,
      );
      return decrypted;
    } catch (e) {
      print('❌ Error decrypting string: $e');
      return '';
    }
  }

  /// Encrypt bytes
  Uint8List encryptBytes(Uint8List bytes) {
    _ensureInitialized();
    final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
    return encrypted.bytes;
  }

  /// Decrypt bytes
  Uint8List decryptBytes(Uint8List encryptedBytes) {
    _ensureInitialized();
    final decrypted = _encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: _iv,
    );
    return Uint8List.fromList(decrypted);
  }

  /// Verify encryption is working correctly
  Future<bool> testEncryption() async {
    try {
      await _ensureInitialized();
      const testString = 'VaultEncryptionTest2024!';
      final encrypted = encryptString(testString);
      final decrypted = decryptString(encrypted);
      return testString == decrypted;
    } catch (e) {
      print('❌ Encryption test failed: $e');
      return false;
    }
  }

  /// Clear all encryption keys (use with caution!)
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
    _isInitialized = false;
    print('⚠️ Encryption keys cleared');
  }
}
