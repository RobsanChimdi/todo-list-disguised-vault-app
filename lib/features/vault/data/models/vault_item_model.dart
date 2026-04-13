import 'package:hive/hive.dart';
import '../../domain/entities/vault_item.dart';

@HiveType(typeId: 1)
class VaultItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? filePath; // Now points to app's private directory

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

  @HiveField(10) // New field for original path tracking
  final String? originalPath;

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
    this.originalPath,
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
      originalPath: item.originalPath,
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
      originalPath: originalPath,
    );
  }
}

/// ✅ Enhanced Adapter
class VaultItemModelAdapter extends TypeAdapter<VaultItemModel> {
  @override
  final int typeId = 1;

  @override
  VaultItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return VaultItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      filePath: fields[2] as String?,
      fileType: fields[3] as String,
      fileSize: fields[4] as int,
      createdAt: fields[5] as DateTime,
      lastOpened: fields[6] as DateTime?,
      isEncrypted: fields[7] as bool? ?? true,
      thumbnailPath: fields[8] as String?,
      metadata: (fields[9] as Map?)?.cast<String, dynamic>(),
      originalPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VaultItemModel obj) {
    writer
      ..writeByte(11) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.fileType)
      ..writeByte(4)
      ..write(obj.fileSize)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastOpened)
      ..writeByte(7)
      ..write(obj.isEncrypted)
      ..writeByte(8)
      ..write(obj.thumbnailPath)
      ..writeByte(9)
      ..write(obj.metadata)
      ..writeByte(10)
      ..write(obj.originalPath);
  }
}
