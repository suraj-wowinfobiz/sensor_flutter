import 'package:equatable/equatable.dart';

class Sensor extends Equatable {
  final String id;
  final String deviceId;
  final String sensorTypeId;
  final String sensorParameterId;
  final String name;
  final String serialNumber;
  final String deviceName;
  final int channelNumber;
  final String endpointUid;
  final String endpointKey;
  final String ingestionEndpoint;
  final String ingestionLiveEndpoint;
  final String processingLiveEndpoint;
  final String analyticsLiveEndpoint;
  final DateTime installedAt;
  final double lastReading;

  const Sensor({
    required this.id,
    required this.deviceId,
    required this.sensorTypeId,
    this.sensorParameterId = '',
    required this.name,
    required this.serialNumber,
    this.deviceName = '',
    this.channelNumber = 0,
    this.endpointUid = '',
    this.endpointKey = '',
    this.ingestionEndpoint = '',
    this.ingestionLiveEndpoint = '',
    this.processingLiveEndpoint = '',
    this.analyticsLiveEndpoint = '',
    required this.installedAt,
    required this.lastReading,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = json[key];
        final parsed = value?.toString().trim() ?? '';
        if (parsed.isNotEmpty) return parsed;
      }
      return fallback;
    }

    int readInt(List<String> keys, [int fallback = 0]) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        final parsed = int.tryParse(value?.toString() ?? '');
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    double readDouble(List<String> keys, [double fallback = 0]) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toDouble();
        final parsed = double.tryParse(value?.toString() ?? '');
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    final installedAtRaw = readString(
      ['installedAt', 'installed_at', 'createdAt', 'created_at'],
      DateTime.now().toIso8601String(),
    );

    final resolvedName = readString(
      ['name', 'sensorName', 'serialNumber', 'serial_number'],
      'Sensor',
    );

    return Sensor(
      id: readString(['sensorId', 'id']),
      deviceId: readString(['deviceId', 'device_id']),
      sensorTypeId: readString(['sensorTypeId', 'sensor_type_id']),
      sensorParameterId:
          readString(['sensorParameterId', 'sensor_parameter_id']),
      name: resolvedName,
      serialNumber: readString(['serialNumber', 'serial_number'], resolvedName),
      deviceName: readString(['deviceName', 'device_name']),
      channelNumber: readInt(['channelNumber', 'channel_number']),
      endpointUid: readString(['endpointUid', 'endpoint_uid']),
      endpointKey: readString(['endpointKey', 'endpoint_key']),
      ingestionEndpoint:
          readString(['ingestionEndpoint', 'ingestion_endpoint']),
      ingestionLiveEndpoint:
          readString(['ingestionLiveEndpoint', 'ingestion_live_endpoint']),
      processingLiveEndpoint:
          readString(['processingLiveEndpoint', 'processing_live_endpoint']),
      analyticsLiveEndpoint:
          readString(['analyticsLiveEndpoint', 'analytics_live_endpoint']),
      installedAt: DateTime.tryParse(installedAtRaw) ?? DateTime.now(),
      lastReading: readDouble(['lastReading', 'last_reading']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensorId': id,
      'device_id': deviceId,
      'deviceId': deviceId,
      'sensor_type_id': sensorTypeId,
      'sensorTypeId': sensorTypeId,
      'sensor_parameter_id': sensorParameterId,
      'sensorParameterId': sensorParameterId,
      'name': name,
      'serial_number': serialNumber,
      'serialNumber': serialNumber,
      'deviceName': deviceName,
      'channelNumber': channelNumber,
      'endpointUid': endpointUid,
      'endpointKey': endpointKey,
      'ingestionEndpoint': ingestionEndpoint,
      'ingestionLiveEndpoint': ingestionLiveEndpoint,
      'processingLiveEndpoint': processingLiveEndpoint,
      'analyticsLiveEndpoint': analyticsLiveEndpoint,
      'installed_at': installedAt.toIso8601String(),
      'last_reading': lastReading,
    };
  }

  Sensor copyWith({
    String? deviceId,
    String? sensorTypeId,
    String? sensorParameterId,
    String? name,
    String? serialNumber,
    String? deviceName,
    int? channelNumber,
    String? endpointUid,
    String? endpointKey,
    String? ingestionEndpoint,
    String? ingestionLiveEndpoint,
    String? processingLiveEndpoint,
    String? analyticsLiveEndpoint,
    double? lastReading,
  }) {
    return Sensor(
      id: id,
      deviceId: deviceId ?? this.deviceId,
      sensorTypeId: sensorTypeId ?? this.sensorTypeId,
      sensorParameterId: sensorParameterId ?? this.sensorParameterId,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      deviceName: deviceName ?? this.deviceName,
      channelNumber: channelNumber ?? this.channelNumber,
      endpointUid: endpointUid ?? this.endpointUid,
      endpointKey: endpointKey ?? this.endpointKey,
      ingestionEndpoint: ingestionEndpoint ?? this.ingestionEndpoint,
      ingestionLiveEndpoint:
          ingestionLiveEndpoint ?? this.ingestionLiveEndpoint,
      processingLiveEndpoint:
          processingLiveEndpoint ?? this.processingLiveEndpoint,
      analyticsLiveEndpoint:
          analyticsLiveEndpoint ?? this.analyticsLiveEndpoint,
      installedAt: installedAt,
      lastReading: lastReading ?? this.lastReading,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceId,
        sensorTypeId,
        sensorParameterId,
        name,
        serialNumber,
        deviceName,
        channelNumber,
        endpointUid,
        endpointKey,
        ingestionEndpoint,
        ingestionLiveEndpoint,
        processingLiveEndpoint,
        analyticsLiveEndpoint,
        installedAt,
        lastReading,
      ];
}
