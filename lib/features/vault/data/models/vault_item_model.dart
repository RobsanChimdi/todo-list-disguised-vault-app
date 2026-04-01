// lib/features/vault/data/models/vault_item_model.dart

import 'package:hive/hive.dart';
import '../../domain/entities/vault_item.dart';

@HiveType(typeId: 1)
class VaultItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? filePath;

  @HiveField(3)
  final String fileType;

  @HiveField(4)
  final int fileSize;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? lastOpened;

  @HiveField(7)
  final bool isEncrypted;

  @HiveField(8)
  final String? thumbnailPath;

  @HiveField(9)
  final Map<String, dynamic>? metadata;

  VaultItemModel({
    required this.id,
    required this.name,
    this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    this.lastOpened,
    this.isEncrypted = true,
    this.thumbnailPath,
    this.metadata,
  });

  factory VaultItemModel.fromEntity(VaultItem item) {
    return VaultItemModel(
      id: item.id,
      name: item.name,
      filePath: item.filePath,
      fileType: item.fileType,
      fileSize: item.fileSize,
      createdAt: item.createdAt,
      lastOpened: item.lastOpened,
      isEncrypted: item.isEncrypted,
      thumbnailPath: item.thumbnailPath,
      metadata: item.metadata,
    );
  }

  VaultItem toEntity() {
    return VaultItem(
      id: id,
      name: name,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      createdAt: createdAt,
      lastOpened: lastOpened,
      isEncrypted: isEncrypted,
      thumbnailPath: thumbnailPath,
      metadata: metadata,
    );
  }
}
