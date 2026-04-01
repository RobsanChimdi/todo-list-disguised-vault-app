// lib/features/vault/domain/entities/vault_item.dart

import 'package:equatable/equatable.dart';

class VaultItem extends Equatable {
  final String id;
  final String name;
  final String? filePath;
  final String fileType; // image, video, document, etc.
  final int fileSize;
  final DateTime createdAt;
  final DateTime? lastOpened;
  final bool isEncrypted;
  final String? thumbnailPath;
  final Map<String, dynamic>? metadata;

  const VaultItem({
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

  factory VaultItem.create({
    required String name,
    required String fileType,
    required int fileSize,
    String? filePath,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    return VaultItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      isEncrypted: true,
      thumbnailPath: thumbnailPath,
      metadata: metadata,
    );
  }

  VaultItem copyWith({
    String? name,
    String? filePath,
    String? fileType,
    int? fileSize,
    DateTime? lastOpened,
    bool? isEncrypted,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    return VaultItem(
      id: id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt,
      lastOpened: lastOpened ?? this.lastOpened,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'fileType': fileType,
    'fileSize': fileSize,
    'createdAt': createdAt.toIso8601String(),
    'lastOpened': lastOpened?.toIso8601String(),
    'isEncrypted': isEncrypted,
    'thumbnailPath': thumbnailPath,
    'metadata': metadata,
  };

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String?,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      createdAt: DateTime.parse(json['createdAt']),
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'])
          : null,
      isEncrypted: json['isEncrypted'] ?? true,
      thumbnailPath: json['thumbnailPath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    filePath,
    fileType,
    fileSize,
    createdAt,
    lastOpened,
    isEncrypted,
    thumbnailPath,
    metadata,
  ];
}
