// lib/features/vault/data/models/vault_item_model_adapter.dart

import 'package:hive/hive.dart';
import 'vault_item_model.dart';

class VaultItemModelAdapter extends TypeAdapter<VaultItemModel> {
  @override
  final int typeId = 1;

  @override
  VaultItemModel read(BinaryReader reader) {
    return VaultItemModel(
      id: reader.readString(),
      name: reader.readString(),
      filePath: reader.readString(),
      fileSize: reader.readInt(),
      fileType: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isEncrypted: reader.readBool(),
      parentFolder: reader.readString(),
      originalPath: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, VaultItemModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.filePath ?? '');
    writer.writeInt(obj.fileSize);
    writer.writeString(obj.fileType);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isEncrypted);
    writer.writeString(obj.parentFolder ?? '');
    writer.writeString(obj.originalPath ?? '');
  }
}
