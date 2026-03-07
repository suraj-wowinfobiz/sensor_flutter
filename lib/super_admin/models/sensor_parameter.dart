import 'package:equatable/equatable.dart';

class SensorParameter extends Equatable {
  final String id;
  final String sensorTypeId;
  final String name;
  final String unit;
  final double minValue;
  final double maxValue;

  const SensorParameter({
    required this.id,
    required this.sensorTypeId,
    required this.name,
    required this.unit,
    required this.minValue,
    required this.maxValue,
  });

  factory SensorParameter.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    return SensorParameter(
      id: (json['sensorParameterId'] ?? json['id'] ?? '').toString(),
      sensorTypeId:
          (json['sensorTypeId'] ?? json['sensor_type_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      minValue: asDouble(json['minValue'] ?? json['min_value']),
      maxValue: asDouble(json['maxValue'] ?? json['max_value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensor_type_id': sensorTypeId,
      'name': name,
      'unit': unit,
      'min_value': minValue,
      'max_value': maxValue,
    };
  }

  @override
  List<Object?> get props => [id, sensorTypeId, name, unit, minValue, maxValue];
}
