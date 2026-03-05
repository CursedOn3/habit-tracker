// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      type: fields[3] as HabitType,
      goalPeriod: fields[4] as GoalPeriod,
      goalValue: fields[5] as double,
      goalUnit: fields[6] as String,
      trackDays: (fields[7] as List).cast<int>(),
      startTime: fields[8] as DateTime?,
      endTime: fields[9] as DateTime?,
      reminderTime: fields[10] as DateTime?,
      reminderEnabled: fields[11] as bool,
      locationEnabled: fields[12] as bool,
      locationLat: fields[13] as double?,
      locationLng: fields[14] as double?,
      locationName: fields[15] as String?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      colorIndex: fields[18] as int,
      isArchived: fields[19] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.goalPeriod)
      ..writeByte(5)
      ..write(obj.goalValue)
      ..writeByte(6)
      ..write(obj.goalUnit)
      ..writeByte(7)
      ..write(obj.trackDays)
      ..writeByte(8)
      ..write(obj.startTime)
      ..writeByte(9)
      ..write(obj.endTime)
      ..writeByte(10)
      ..write(obj.reminderTime)
      ..writeByte(11)
      ..write(obj.reminderEnabled)
      ..writeByte(12)
      ..write(obj.locationEnabled)
      ..writeByte(13)
      ..write(obj.locationLat)
      ..writeByte(14)
      ..write(obj.locationLng)
      ..writeByte(15)
      ..write(obj.locationName)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.colorIndex)
      ..writeByte(19)
      ..write(obj.isArchived);
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

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 1;

  @override
  HabitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return HabitType.readBook;
      case 1: return HabitType.exercise;
      case 2: return HabitType.run;
      case 3: return HabitType.sleep;
      case 4: return HabitType.custom;
      default: return HabitType.custom;
    }
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    switch (obj) {
      case HabitType.readBook: writer.writeByte(0); break;
      case HabitType.exercise: writer.writeByte(1); break;
      case HabitType.run: writer.writeByte(2); break;
      case HabitType.sleep: writer.writeByte(3); break;
      case HabitType.custom: writer.writeByte(4); break;
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
  final int typeId = 2;

  @override
  GoalPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return GoalPeriod.daily;
      case 1: return GoalPeriod.weekly;
      case 2: return GoalPeriod.monthly;
      default: return GoalPeriod.daily;
    }
  }

  @override
  void write(BinaryWriter writer, GoalPeriod obj) {
    switch (obj) {
      case GoalPeriod.daily: writer.writeByte(0); break;
      case GoalPeriod.weekly: writer.writeByte(1); break;
      case GoalPeriod.monthly: writer.writeByte(2); break;
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

class HabitCompletionAdapter extends TypeAdapter<HabitCompletion> {
  @override
  final int typeId = 3;

  @override
  HabitCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitCompletion(
      id: fields[0] as String,
      habitId: fields[1] as String,
      userId: fields[2] as String,
      date: fields[3] as DateTime,
      value: fields[4] as double,
      note: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HabitCompletion obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.value)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
