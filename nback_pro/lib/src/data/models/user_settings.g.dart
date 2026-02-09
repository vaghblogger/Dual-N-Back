// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 0;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      selectedThemeId: fields[0] as int,
      isAutoN: fields[1] as bool,
      manualN: fields[2] as int,
      continuousFeedback: fields[3] as bool,
      focusMusicEnabled: fields[4] as bool,
      reminderTime: fields[5] as String?,
      speedMultiplier: fields[6] as double,
      showGrid: (fields[7] as bool?) ?? false,
      tapSoundEnabled: (fields[8] as bool?) ?? false,
      positionLeftAudioRight: (fields[9] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.selectedThemeId)
      ..writeByte(1)
      ..write(obj.isAutoN)
      ..writeByte(2)
      ..write(obj.manualN)
      ..writeByte(3)
      ..write(obj.continuousFeedback)
      ..writeByte(4)
      ..write(obj.focusMusicEnabled)
      ..writeByte(5)
      ..write(obj.reminderTime)
      ..writeByte(6)
      ..write(obj.speedMultiplier)
      ..writeByte(7)
      ..write(obj.showGrid)
      ..writeByte(8)
      ..write(obj.tapSoundEnabled)
      ..writeByte(9)
      ..write(obj.positionLeftAudioRight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
