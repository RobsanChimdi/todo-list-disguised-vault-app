// lib/core/services/encryption_helper.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static const String _keyString = 'your-32-character-secret-key-here!!!';
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  EncryptionHelper() {
    _key = encrypt.Key.fromUtf8(_keyString.padRight(32, '0').substring(0, 32));
    _iv = encrypt.IV.fromUtf8('16byteivstring!!');
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  /// Encrypt a file
  Future<File> encryptFile(File inputFile) async {
    try {
      final fileBytes = await inputFile.readAsBytes();
      final encrypted = _encrypter.encryptBytes(fileBytes, iv: _iv);

      final tempDir = await getTemporaryDirectory();
      final outputFile = File(
        '${tempDir.path}/encrypted_${DateTime.now().millisecondsSinceEpoch}.enc',
      );
      await outputFile.writeAsBytes(encrypted.bytes);

      return outputFile;
    } catch (e) {
      print('Error encrypting file: $e');
      rethrow;
    }
  }

  /// Decrypt a file
  Future<File> decryptFile(File encryptedFile) async {
    try {
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decrypted = _encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes),
        iv: _iv,
      );

      final tempDir = await getTemporaryDirectory();
      final outputFile = File(
        '${tempDir.path}/decrypted_${DateTime.now().millisecondsSinceEpoch}.tmp',
      );
      await outputFile.writeAsBytes(decrypted);

      return outputFile;
    } catch (e) {
      print('Error decrypting file: $e');
      rethrow;
    }
  }

  /// Encrypt a string
  String encryptString(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt a string
  String decryptString(String encryptedText) {
    final decrypted = _encrypter.decrypt(
      encrypt.Encrypted.fromBase64(encryptedText),
      iv: _iv,
    );
    return decrypted;
  }

  /// Encrypt bytes
  Uint8List encryptBytes(Uint8List bytes) {
    final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
    return encrypted.bytes;
  }

  /// Decrypt bytes
  Uint8List decryptBytes(Uint8List encryptedBytes) {
    final decrypted = _encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: _iv,
    );
    return Uint8List.fromList(decrypted);
  }
}
