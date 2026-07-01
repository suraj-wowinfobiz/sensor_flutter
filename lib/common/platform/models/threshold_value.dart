import 'package:equatable/equatable.dart';

class ThresholdValue extends Equatable {
  final String id;
  final String sensorId;
  final String sensorParameterId;
  final String thresholdProfileId;
  final double minThreshold;
  final double maxThreshold;
  final double warningLevel;
  final double criticalLevel;

  const ThresholdValue({
    required this.id,
    this.sensorId = '',
    required this.sensorParameterId,
    required this.thresholdProfileId,
    required this.minThreshold,
    required this.maxThreshold,
    required this.warningLevel,
    required this.criticalLevel,
  });

  factory ThresholdValue.fromJson(Map<String, dynamic> json) {
    String asString(dynamic value) => value?.toString() ?? '';
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    return ThresholdValue(
      id: asString(
          json['thresholdValueId'] ?? json['thresholdId'] ?? json['id']),
      sensorId: asString(json['sensorId'] ?? json['sensor_id']),
      sensorParameterId: asString(json['sensorParameterId'] ??
          json['sensorParamterId'] ??
          json['sensor_parameter_id']),
      thresholdProfileId:
          asString(json['thresholdProfileId'] ?? json['threshold_profile_id']),
      minThreshold:
          asDouble(json['minThresholdValue'] ?? json['min_threshold']),
      maxThreshold:
          asDouble(json['maxThresholdValue'] ?? json['max_threshold']),
      warningLevel: asDouble(json['warningLevel'] ??
          json['warrningLevel'] ??
          json['warning_level']),
      criticalLevel: asDouble(json['criticalLevel'] ?? json['critical_level']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'sensorId': sensorId,
      'sensor_parameter_id': sensorParameterId,
      'threshold_profile_id': thresholdProfileId,
      'min_threshold': minThreshold,
      'max_threshold': maxThreshold,
      'warning_level': warningLevel,
      'critical_level': criticalLevel,
    };
  }

  @override
  List<Object?> get props => [
        id,
        sensorId,
        sensorParameterId,
        thresholdProfileId,
        minThreshold,
        maxThreshold,
        warningLevel,
        criticalLevel,
      ];
}
