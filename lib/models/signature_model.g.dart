// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signature_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SignatureModelAdapter extends TypeAdapter<SignatureModel> {
  @override
  final int typeId = 0;

  @override
  SignatureModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SignatureModel(
      id: fields[0] as String,
      name: fields[1] as String,
      style: fields[2] as SignatureStyle,
      createdAt: fields[3] as DateTime,
      isDefault: fields[4] as bool,
      imagePath: fields[5] as String?,
      signatureText: fields[6] as String?,
      fontLabel: fields[7] as String?,
      inkColor: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SignatureModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.style)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isDefault)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.signatureText)
      ..writeByte(7)
      ..write(obj.fontLabel)
      ..writeByte(8)
      ..write(obj.inkColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SignatureStyleAdapter extends TypeAdapter<SignatureStyle> {
  @override
  final int typeId = 2;

  @override
  SignatureStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SignatureStyle.drawn;
      case 1:
        return SignatureStyle.typed;
      case 2:
        return SignatureStyle.uploaded;
      case 3:
        return SignatureStyle.scanned;
      case 4:
        return SignatureStyle.generated;
      default:
        return SignatureStyle.drawn;
    }
  }

  @override
  void write(BinaryWriter writer, SignatureStyle obj) {
    switch (obj) {
      case SignatureStyle.drawn:
        writer.writeByte(0);
        break;
      case SignatureStyle.typed:
        writer.writeByte(1);
        break;
      case SignatureStyle.uploaded:
        writer.writeByte(2);
        break;
      case SignatureStyle.scanned:
        writer.writeByte(3);
        break;
      case SignatureStyle.generated:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
