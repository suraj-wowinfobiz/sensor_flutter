import 'package:equatable/equatable.dart';

class Alert extends Equatable {
  final String id;
  final String sensorId;
  final String sensorParameterId;
  final String alertLevel;
  final String message;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;

  const Alert({
    required this.id,
    required this.sensorId,
    required this.sensorParameterId,
    required this.alertLevel,
    required this.message,
    required this.triggeredAt,
    this.resolvedAt,
  });

  bool get isResolved => resolvedAt != null;

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      sensorId: json['sensor_id'] as String,
      sensorParameterId: json['sensor_parameter_id'] as String,
      alertLevel: json['alert_level'] as String,
      message: json['message'] as String,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'sensor_parameter_id': sensorParameterId,
      'alert_level': alertLevel,
      'message': message,
      'triggered_at': triggeredAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  Alert copyWith({DateTime? resolvedAt}) {
    return Alert(
      id: id,
      sensorId: sensorId,
      sensorParameterId: sensorParameterId,
      alertLevel: alertLevel,
      message: message,
      triggeredAt: triggeredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, sensorId, alertLevel, message, triggeredAt, resolvedAt];
}
