// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionResultAdapter extends TypeAdapter<SessionResult> {
  @override
  final int typeId = 1;

  @override
  SessionResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionResult(
      date: fields[0] as DateTime,
      nLevel: fields[1] as int,
      accuracy: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SessionResult obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.nLevel)
      ..writeByte(2)
      ..write(obj.accuracy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
