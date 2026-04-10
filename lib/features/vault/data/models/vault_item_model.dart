// lib/features/vault/data/models/vault_item_model.dart (add adapter)

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

// Add this adapter class at the end of the file
class VaultItemModelAdapter extends TypeAdapter<VaultItemModel> {
  @override
  final int typeId = 1;

  @override
  VaultItemModel read(BinaryReader reader) {
    return VaultItemModel(
      id: reader.readString(),
      name: reader.readString(),
      filePath: reader.readString(),
      fileType: reader.readString(),
      fileSize: reader.readInt(),
      createdAt: DateTime.parse(reader.readString()),
      lastOpened: reader.readBool()
          ? DateTime.parse(reader.readString())
          : null,
      isEncrypted: reader.readBool(),
      thumbnailPath: reader.readString(),
      metadata: reader.read() as Map<String, dynamic>?,
    );
  }

  @override
  void write(BinaryWriter writer, VaultItemModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.filePath ?? '');
    writer.writeString(obj.fileType);
    writer.writeInt(obj.fileSize);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeBool(obj.lastOpened != null);
    if (obj.lastOpened != null) {
      writer.writeString(obj.lastOpened!.toIso8601String());
    }
    writer.writeBool(obj.isEncrypted);
    writer.writeString(obj.thumbnailPath ?? '');
    writer.write(obj.metadata);
  }
}
