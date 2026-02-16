import 'package:equatable/equatable.dart';

class AlertModel extends Equatable {
  final String id;
  final String sensorId;
  final String sensorParameterId;
  final String alertLevel;
  final String message;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;

  const AlertModel({
    required this.id,
    required this.sensorId,
    required this.sensorParameterId,
    required this.alertLevel,
    required this.message,
    required this.triggeredAt,
    this.resolvedAt,
  });

  bool get isResolved => resolvedAt != null;

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      sensorId: json['sensor_id'] as String,
      sensorParameterId: json['sensor_parameter_id'] as String,
      alertLevel: json['alert_level'] as String,
      message: json['message'] as String,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sensor_id': sensorId,
        'sensor_parameter_id': sensorParameterId,
        'alert_level': alertLevel,
        'message': message,
        'triggered_at': triggeredAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  AlertModel copyWith({
    DateTime? resolvedAt,
    String? message,
    String? alertLevel,
  }) {
    return AlertModel(
      id: id,
      sensorId: sensorId,
      sensorParameterId: sensorParameterId,
      alertLevel: alertLevel ?? this.alertLevel,
      message: message ?? this.message,
      triggeredAt: triggeredAt,
      resolvedAt: resolvedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sensorId,
        sensorParameterId,
        alertLevel,
        message,
        triggeredAt,
        resolvedAt
      ];
}
