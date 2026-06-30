import 'package:equatable/equatable.dart';

class SensorParameter extends Equatable {
  final String id;
  final String sensorTypeId;
  final String name;
  final String unit;
  final double minValue;
  final double maxValue;
  final String calculationName;
  final String formulaType;
  final String graphType;
  final String useFor;

  const SensorParameter({
    required this.id,
    required this.sensorTypeId,
    required this.name,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    this.calculationName = '',
    this.formulaType = '',
    this.graphType = 'line',
    this.useFor = 'custom',
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
      calculationName:
          (json['calculationName'] ?? json['calculation_name'] ?? '')
              .toString(),
      formulaType:
          (json['formulaType'] ?? json['formula_type'] ?? '').toString(),
      graphType:
          (json['graphType'] ?? json['graph_type'] ?? 'line').toString(),
      useFor: (json['useFor'] ?? json['use_for'] ?? 'custom').toString(),
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
      'calculation_name': calculationName,
      'formula_type': formulaType,
      'graph_type': graphType,
      'use_for': useFor,
    };
  }

  @override
  List<Object?> get props => [
        id,
        sensorTypeId,
        name,
        unit,
        minValue,
        maxValue,
        calculationName,
        formulaType,
        graphType,
        useFor,
      ];
}
