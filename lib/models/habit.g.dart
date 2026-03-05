// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 0;

  @override
  HabitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitType.readBook;
      case 1:
        return HabitType.exercise;
      case 2:
        return HabitType.run;
      case 3:
        return HabitType.sleep;
      case 4:
        return HabitType.custom;
      default:
        return HabitType.custom;
    }
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    switch (obj) {
      case HabitType.readBook:
        writer.writeByte(0);
        break;
      case HabitType.exercise:
        writer.writeByte(1);
        break;
      case HabitType.run:
        writer.writeByte(2);
        break;
      case HabitType.sleep:
        writer.writeByte(3);
        break;
      case HabitType.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalPeriodAdapter extends TypeAdapter<GoalPeriod> {
  @override
  final int typeId = 1;

  @override
  GoalPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalPeriod.daily;
      case 1:
        return GoalPeriod.weekly;
      case 2:
        return GoalPeriod.monthly;
      default:
        return GoalPeriod.daily;
    }
  }

  @override
  void write(BinaryWriter writer, GoalPeriod obj) {
    switch (obj) {
      case GoalPeriod.daily:
        writer.writeByte(0);
        break;
      case GoalPeriod.weekly:
        writer.writeByte(1);
        break;
      case GoalPeriod.monthly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitLocationAdapter extends TypeAdapter<HabitLocation> {
  @override
  final int typeId = 2;

  @override
  HabitLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLocation(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      address: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLocation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 3;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as HabitType,
      goalPeriod: fields[3] as GoalPeriod,
      goalValue: fields[4] as double,
      trackDays: (fields[5] as List).cast<int>(),
      startTime: fields[6] as String?,
      endTime: fields[7] as String?,
      reminderTime: fields[8] as String?,
      reminderEnabled: fields[9] as bool,
      locationEnabled: fields[10] as bool,
      location: fields[11] as HabitLocation?,
      completions: (fields[12] as Map?)?.cast<String, double>() ?? {},
      createdAt: fields[13] as DateTime,
      userId: fields[14] as String?,
      colorIndex: fields[15] as int,
      customUnit: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.goalPeriod)
      ..writeByte(4)
      ..write(obj.goalValue)
      ..writeByte(5)
      ..write(obj.trackDays)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.reminderTime)
      ..writeByte(9)
      ..write(obj.reminderEnabled)
      ..writeByte(10)
      ..write(obj.locationEnabled)
      ..writeByte(11)
      ..write(obj.location)
      ..writeByte(12)
      ..write(obj.completions)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.userId)
      ..writeByte(15)
      ..write(obj.colorIndex)
      ..writeByte(16)
      ..write(obj.customUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
