// lib/features/vault/domain/entities/vault_item.dart

class VaultItem {
  final String id;
  final String name;
  final String? filePath;
  final int fileSize;
  final String fileType;
  final DateTime createdAt;
  final bool isEncrypted;
  final String? parentFolder;
  final String? originalPath;

  VaultItem({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.createdAt,
    required this.isEncrypted,
    this.parentFolder,
    this.originalPath,
  });

  VaultItem copyWith({
    String? id,
    String? name,
    String? filePath,
    int? fileSize,
    String? fileType,
    DateTime? createdAt,
    bool? isEncrypted,
    String? parentFolder,
    String? originalPath,
  }) {
    return VaultItem(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      parentFolder: parentFolder ?? this.parentFolder,
      originalPath: originalPath ?? this.originalPath,
    );
  }
}
