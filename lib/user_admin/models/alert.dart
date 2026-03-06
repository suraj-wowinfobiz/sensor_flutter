import 'package:equatable/equatable.dart';

class Alert extends Equatable {
  final String id;
  final String sensorId;
  final String sensorParameterId;
  final String alertLevel;
  final String assignedTo;
  final String status;
  final String message;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  const Alert({
    required this.id,
    required this.sensorId,
    required this.sensorParameterId,
    required this.alertLevel,
    this.assignedTo = '',
    this.status = '',
    required this.message,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  bool get isResolved => resolvedAt != null;

  factory Alert.fromJson(Map<String, dynamic> json) {
    String asString(dynamic value) => value?.toString() ?? '';
    return Alert(
      id: asString(json['id'] ?? json['alertId']),
      sensorId: asString(json['sensorId'] ?? json['sensor_id']),
      sensorParameterId:
          asString(json['sensorParameterId'] ?? json['sensor_parameter_id']),
      alertLevel: asString(json['alertLevel'] ?? json['alert_level']),
      assignedTo: asString(json['assignedTo'] ?? json['assigned_to']),
      status: asString(json['status']),
      message: asString(json['message']),
      triggeredAt: DateTime.tryParse(
            asString(json['triggeredAt'] ?? json['triggered_at']),
          ) ??
          DateTime.now(),
      acknowledgedAt: DateTime.tryParse(
        asString(json['acknowledgedAt'] ?? json['acknowledged_at']),
      ),
      resolvedAt: DateTime.tryParse(
        asString(json['resolvedAt'] ?? json['resolved_at']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'sensor_parameter_id': sensorParameterId,
      'alert_level': alertLevel,
      'assigned_to': assignedTo,
      'status': status,
      'message': message,
      'triggered_at': triggeredAt.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  Alert copyWith({
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? status,
    String? assignedTo,
  }) {
    return Alert(
      id: id,
      sensorId: sensorId,
      sensorParameterId: sensorParameterId,
      alertLevel: alertLevel,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      message: message,
      triggeredAt: triggeredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sensorId,
        sensorParameterId,
        alertLevel,
        assignedTo,
        status,
        message,
        triggeredAt,
        acknowledgedAt,
        resolvedAt,
      ];
}
