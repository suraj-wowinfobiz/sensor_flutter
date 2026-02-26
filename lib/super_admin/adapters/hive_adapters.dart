import 'package:hive/hive.dart';

import '../models/alert.dart';
import '../models/sensor.dart';

class SensorAdapter extends TypeAdapter<Sensor> {
  @override
  final int typeId = 0;

  @override
  Sensor read(BinaryReader reader) {
    return Sensor(
      id: reader.readString(),
      deviceId: reader.readString(),
      sensorTypeId: reader.readString(),
      serialNumber: reader.readString(),
      installedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      lastReading: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Sensor obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.deviceId)
      ..writeString(obj.sensorTypeId)
      ..writeString(obj.serialNumber)
      ..writeInt(obj.installedAt.millisecondsSinceEpoch)
      ..writeDouble(obj.lastReading);
  }
}

class AlertAdapter extends TypeAdapter<Alert> {
  @override
  final int typeId = 1;

  @override
  Alert read(BinaryReader reader) {
    final hasResolved = reader.readBool();
    return Alert(
      id: reader.readString(),
      sensorId: reader.readString(),
      sensorParameterId: reader.readString(),
      alertLevel: reader.readString(),
      message: reader.readString(),
      triggeredAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      resolvedAt: hasResolved
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Alert obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.sensorId)
      ..writeString(obj.sensorParameterId)
      ..writeString(obj.alertLevel)
      ..writeString(obj.message)
      ..writeInt(obj.triggeredAt.millisecondsSinceEpoch)
      ..writeBool(obj.resolvedAt != null);

    if (obj.resolvedAt != null) {
      writer.writeInt(obj.resolvedAt!.millisecondsSinceEpoch);
    }
  }
}
