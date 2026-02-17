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
    return SensorParameter(
      id: json['id'] as String,
      sensorTypeId: json['sensor_type_id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      minValue: (json['min_value'] as num).toDouble(),
      maxValue: (json['max_value'] as num).toDouble(),
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
