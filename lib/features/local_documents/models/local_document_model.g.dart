// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalDocumentModelAdapter extends TypeAdapter<LocalDocumentModel> {
  @override
  final int typeId = 3;

  @override
  LocalDocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalDocumentModel(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      fileName: fields[3] as String,
      fileType: fields[4] as String,
      createdAt: fields[5] as DateTime,
      content: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalDocumentModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.fileName)
      ..writeByte(4)
      ..write(obj.fileType)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
