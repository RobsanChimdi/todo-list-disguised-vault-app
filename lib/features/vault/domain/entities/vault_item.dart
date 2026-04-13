import 'package:equatable/equatable.dart';

class VaultItem extends Equatable {
  final String id;
  final String name;
  final String? filePath;
  final String fileType;
  final int fileSize;
  final String? originalPath;
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
    this.originalPath,
    required this.fileSize,
    required this.createdAt,
    this.lastOpened,
    this.isEncrypted = true,
    this.thumbnailPath,
    this.metadata,
  });

  /// ✅ Better unique ID
  factory VaultItem.create({
    required String name,
    required String fileType,
    required int fileSize,
    required originalPath,
    String? filePath,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();

    return VaultItem(
      id: '${now.microsecondsSinceEpoch}_${name.hashCode}',
      name: name,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      originalPath: originalPath,
      createdAt: now,
      isEncrypted: true,
      thumbnailPath: thumbnailPath,
      metadata: metadata != null ? Map.from(metadata) : null,
    );
  }

  /// ✅ Safe immutable copy
  VaultItem copyWith({
    String? name,
    String? filePath,
    String? fileType,
    String? originalPath,
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
      originalPath: originalPath ?? this.originalPath,
      createdAt: createdAt,
      lastOpened: lastOpened ?? this.lastOpened,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata != null
          ? Map.from(metadata)
          : (this.metadata != null ? Map.from(this.metadata!) : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'fileType': fileType,
    'fileSize': fileSize,
    'originalPath': originalPath,
    'createdAt': createdAt.toIso8601String(),
    'lastOpened': lastOpened?.toIso8601String(),
    'isEncrypted': isEncrypted,
    'thumbnailPath': thumbnailPath,
    'metadata': metadata,
  };

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      filePath: json['filePath'],
      fileType: json['fileType'] ?? 'unknown',
      fileSize: json['fileSize'] ?? 0,
      originalPath: json['originalPath'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastOpened: json['lastOpened'] != null
          ? DateTime.tryParse(json['lastOpened'])
          : null,
      isEncrypted: json['isEncrypted'] ?? true,
      thumbnailPath: json['thumbnailPath'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    filePath,
    fileType,
    fileSize,
    originalPath,
    createdAt,
    lastOpened,
    isEncrypted,
    thumbnailPath,
    metadata,
  ];
}
