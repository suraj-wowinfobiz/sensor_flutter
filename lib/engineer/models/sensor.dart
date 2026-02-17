import 'package:equatable/equatable.dart';

class Sensor extends Equatable {
  final String id;
  final String deviceId;
  final String sensorTypeId;
  final String serialNumber;
  final DateTime installedAt;
  final double lastReading;

  const Sensor({
    required this.id,
    required this.deviceId,
    required this.sensorTypeId,
    required this.serialNumber,
    required this.installedAt,
    required this.lastReading,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      sensorTypeId: json['sensor_type_id'] as String,
      serialNumber: json['serial_number'] as String,
      installedAt: DateTime.parse(json['installed_at'] as String),
      lastReading: (json['last_reading'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'sensor_type_id': sensorTypeId,
      'serial_number': serialNumber,
      'installed_at': installedAt.toIso8601String(),
      'last_reading': lastReading,
    };
  }

  Sensor copyWith({
    String? deviceId,
    String? sensorTypeId,
    String? serialNumber,
    double? lastReading,
  }) {
    return Sensor(
      id: id,
      deviceId: deviceId ?? this.deviceId,
      sensorTypeId: sensorTypeId ?? this.sensorTypeId,
      serialNumber: serialNumber ?? this.serialNumber,
      installedAt: installedAt,
      lastReading: lastReading ?? this.lastReading,
    );
  }

  @override
  List<Object?> get props =>
      [id, deviceId, sensorTypeId, serialNumber, installedAt, lastReading];
}
