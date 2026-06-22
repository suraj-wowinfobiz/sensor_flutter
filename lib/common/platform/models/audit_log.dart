import 'package:equatable/equatable.dart';

class AuditLog extends Equatable {
  final String id;
  final String userId;
  final String action;
  final String resource;
  final DateTime timestamp;
  final String ip;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.resource,
    required this.timestamp,
    required this.ip,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      resource: json['resource'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ip: json['ip'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'resource': resource,
      'timestamp': timestamp.toIso8601String(),
      'ip': ip,
    };
  }

  @override
  List<Object?> get props => [id, userId, action, resource, timestamp, ip];
}
