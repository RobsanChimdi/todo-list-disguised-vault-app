// lib/features/vault/data/models/vault_item_model.dart

import 'package:hive/hive.dart';
import '../../domain/entities/vault_item.dart';

@HiveType(typeId: 1)
class VaultItemModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? filePath;

  @HiveField(3)
  final int fileSize;

  @HiveField(4)
  final String fileType;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final bool isEncrypted;

  @HiveField(7)
  final String? parentFolder;

  @HiveField(8)
  final String? originalPath;

  VaultItemModel({
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

  factory VaultItemModel.fromEntity(VaultItem entity) {
    return VaultItemModel(
      id: entity.id,
      name: entity.name,
      filePath: entity.filePath,
      fileSize: entity.fileSize,
      fileType: entity.fileType,
      createdAt: entity.createdAt,
      isEncrypted: entity.isEncrypted,
      parentFolder: entity.parentFolder,
      originalPath: entity.originalPath,
    );
  }

  VaultItem toEntity() {
    return VaultItem(
      id: id,
      name: name,
      filePath: filePath,
      fileSize: fileSize,
      fileType: fileType,
      createdAt: createdAt,
      isEncrypted: isEncrypted,
      parentFolder: parentFolder,
      originalPath: originalPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'fileSize': fileSize,
      'fileType': fileType,
      'createdAt': createdAt.toIso8601String(),
      'isEncrypted': isEncrypted,
      'parentFolder': parentFolder,
      'originalPath': originalPath,
    };
  }

  factory VaultItemModel.fromJson(Map<String, dynamic> json) {
    return VaultItemModel(
      id: json['id'],
      name: json['name'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      fileType: json['fileType'],
      createdAt: DateTime.parse(json['createdAt']),
      isEncrypted: json['isEncrypted'],
      parentFolder: json['parentFolder'],
      originalPath: json['originalPath'],
    );
  }
}
