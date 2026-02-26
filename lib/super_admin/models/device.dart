import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final String id;
  final String siteId;
  final String zoneId;
  final String deviceCode;
  final String status;
  final DateTime installedAt;

  const Device({
    required this.id,
    required this.siteId,
    required this.zoneId,
    required this.deviceCode,
    required this.status,
    required this.installedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      siteId: json['site_id'] as String,
      zoneId: json['zone_id'] as String,
      deviceCode: json['device_code'] as String,
      status: json['status'] as String,
      installedAt: DateTime.parse(json['installed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'zone_id': zoneId,
      'device_code': deviceCode,
      'status': status,
      'installed_at': installedAt.toIso8601String(),
    };
  }

  Device copyWith({
    String? siteId,
    String? zoneId,
    String? deviceCode,
    String? status,
  }) {
    return Device(
      id: id,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      deviceCode: deviceCode ?? this.deviceCode,
      status: status ?? this.status,
      installedAt: installedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, siteId, zoneId, deviceCode, status, installedAt];
}
