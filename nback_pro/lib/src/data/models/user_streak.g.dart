// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_streak.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStreakAdapter extends TypeAdapter<UserStreak> {
  @override
  final int typeId = 2;

  @override
  UserStreak read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStreak(
      currentStreak: fields[0] as int,
      lastCompletedDate: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserStreak obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.lastCompletedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStreakAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
