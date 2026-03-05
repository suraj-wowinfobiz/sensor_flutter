import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final String id;
  final String siteId;
  final String zoneId;
  final String deviceCode;
  final String status;
  final DateTime installedAt;
  final String serialNumber;
  final String firmwareVersion;
  final String macAddress;
  final String ipAddress;
  final int numberOfChannels;
  final String webHookUrl;
  final double lat;
  final double log;
  final String lastHeartBeat;

  const Device({
    required this.id,
    required this.siteId,
    required this.zoneId,
    required this.deviceCode,
    required this.status,
    required this.installedAt,
    this.serialNumber = '',
    this.firmwareVersion = '',
    this.macAddress = '',
    this.ipAddress = '',
    this.numberOfChannels = 0,
    this.webHookUrl = '',
    this.lat = 0.0,
    this.log = 0.0,
    this.lastHeartBeat = '',
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      siteId: json['site_id'] as String,
      zoneId: json['zone_id'] as String,
      deviceCode: json['device_code'] as String,
      status: json['status'] as String,
      installedAt: DateTime.parse(json['installed_at'] as String),
      serialNumber: json['serial_number']?.toString() ?? '',
      firmwareVersion: json['firmware_version']?.toString() ?? '',
      macAddress: json['mac_address']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString() ?? '',
      numberOfChannels: int.tryParse(json['number_of_channels']?.toString() ?? '0') ?? 0,
      webHookUrl: json['web_hook_url']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      log: double.tryParse(json['log']?.toString() ?? '0') ?? 0.0,
      lastHeartBeat: json['last_heart_beat']?.toString() ?? '',
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
      'serial_number': serialNumber,
      'firmware_version': firmwareVersion,
      'mac_address': macAddress,
      'ip_address': ipAddress,
      'number_of_channels': numberOfChannels,
      'web_hook_url': webHookUrl,
      'lat': lat,
      'log': log,
      'last_heart_beat': lastHeartBeat,
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
      serialNumber: serialNumber,
      firmwareVersion: firmwareVersion,
      macAddress: macAddress,
      ipAddress: ipAddress,
      numberOfChannels: numberOfChannels,
      webHookUrl: webHookUrl,
      lat: lat,
      log: log,
      lastHeartBeat: lastHeartBeat,
    );
  }

  @override
  List<Object?> get props => [
        id,
        siteId,
        zoneId,
        deviceCode,
        status,
        installedAt,
        serialNumber,
        firmwareVersion,
        macAddress,
        ipAddress,
        numberOfChannels,
        webHookUrl,
        lat,
        log,
        lastHeartBeat,
      ];
}
