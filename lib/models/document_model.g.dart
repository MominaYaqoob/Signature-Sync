// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 1;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentModel(
      id: fields[0] as String,
      title: fields[1] as String,
      status: fields[2] as DocumentStatus,
      updatedAt: fields[3] as DateTime,
      pageCount: fields[4] as int,
      signerName: fields[5] as String?,
      fileType: fields[6] as DocumentFileType,
      filePath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.pageCount)
      ..writeByte(5)
      ..write(obj.signerName)
      ..writeByte(6)
      ..write(obj.fileType)
      ..writeByte(7)
      ..write(obj.filePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DocumentStatusAdapter extends TypeAdapter<DocumentStatus> {
  @override
  final int typeId = 3;

  @override
  DocumentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DocumentStatus.draft;
      case 1:
        return DocumentStatus.pending;
      case 2:
        return DocumentStatus.signed;
      case 3:
        return DocumentStatus.expired;
      default:
        return DocumentStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, DocumentStatus obj) {
    switch (obj) {
      case DocumentStatus.draft:
        writer.writeByte(0);
        break;
      case DocumentStatus.pending:
        writer.writeByte(1);
        break;
      case DocumentStatus.signed:
        writer.writeByte(2);
        break;
      case DocumentStatus.expired:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DocumentFileTypeAdapter extends TypeAdapter<DocumentFileType> {
  @override
  final int typeId = 4;

  @override
  DocumentFileType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DocumentFileType.pdf;
      case 1:
        return DocumentFileType.image;
      default:
        return DocumentFileType.pdf;
    }
  }

  @override
  void write(BinaryWriter writer, DocumentFileType obj) {
    switch (obj) {
      case DocumentFileType.pdf:
        writer.writeByte(0);
        break;
      case DocumentFileType.image:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFileTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
