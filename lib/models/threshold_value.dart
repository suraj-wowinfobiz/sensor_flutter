import 'package:equatable/equatable.dart';

class ThresholdValue extends Equatable {
  final String id;
  final String sensorParameterId;
  final String thresholdProfileId;
  final double minThreshold;
  final double maxThreshold;
  final double warningLevel;
  final double criticalLevel;

  const ThresholdValue({
    required this.id,
    required this.sensorParameterId,
    required this.thresholdProfileId,
    required this.minThreshold,
    required this.maxThreshold,
    required this.warningLevel,
    required this.criticalLevel,
  });

  factory ThresholdValue.fromJson(Map<String, dynamic> json) {
    return ThresholdValue(
      id: json['id'] as String,
      sensorParameterId: json['sensor_parameter_id'] as String,
      thresholdProfileId: json['threshold_profile_id'] as String,
      minThreshold: (json['min_threshold'] as num).toDouble(),
      maxThreshold: (json['max_threshold'] as num).toDouble(),
      warningLevel: (json['warning_level'] as num).toDouble(),
      criticalLevel: (json['critical_level'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
        sensorParameterId,
        thresholdProfileId,
        minThreshold,
        maxThreshold,
        warningLevel,
        criticalLevel,
      ];
}
