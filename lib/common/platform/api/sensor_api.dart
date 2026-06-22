import 'api_client.dart';

class SensorApi {
  // Endpoints aligned with API_DOCUMENTATION.json (device-service).
  static const String _sensorsBase = '/api/v1/sensors/sensors';

  static Future<List<Map<String, dynamic>>> getAllSensors() async {
    final response = await ApiClient.get('/api/v1/sensors/get-all');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<List<Map<String, dynamic>>> getSensorsByDevice(
    String deviceId,
  ) async {
    final response =
        await ApiClient.get('/api/v1/sensors/devices/$deviceId/sensors');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<Map<String, dynamic>> getSensorById(String sensorId) async {
    final response = await ApiClient.get('$_sensorsBase/$sensorId');
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> createSensor({
    required String deviceId,
    required String sensorTypeId,
    required String name,
    required String status,
    required String unit,
    String? sensorParameterId,
    String? sensorId,
    String? serialNumber,
    String? macAddress,
    int? channelNumber,
    double? lat,
    double? log,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/sensors/devices/$deviceId/sensors',
      data: {
        if (sensorId != null) 'sensorId': sensorId,
        if (sensorId != null) 'id': sensorId,
        'deviceId': deviceId,
        'device_id': deviceId,
        'sensorTypeId': sensorTypeId,
        'sensor_type_id': sensorTypeId,
        if (sensorParameterId != null) 'sensorParameterId': sensorParameterId,
        if (sensorParameterId != null) 'sensor_parameter_id': sensorParameterId,
        'name': name,
        if (serialNumber != null) 'serialNumber': serialNumber,
        if (serialNumber != null) 'serial_number': serialNumber,
        if (macAddress != null) 'macAddress': macAddress,
        if (macAddress != null) 'mac_address': macAddress,
        if (channelNumber != null) 'channelNumber': channelNumber,
        if (channelNumber != null) 'channel_number': channelNumber,
        if (lat != null) 'lat': lat,
        if (log != null) 'long': log,
        if (log != null) 'log': log,
        'status': status,
        'unit': unit,
      },
      headers: {
        'deviceId': deviceId,
        'device-id': deviceId,
        if (sensorId != null) 'sensor-id': sensorId,
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateSensor({
    required String sensorId,
    required String deviceId,
    required String sensorTypeId,
    required String name,
    required String status,
    required String unit,
    String? sensorParameterId,
    String? serialNumber,
    String? macAddress,
    int? channelNumber,
    double? lat,
    double? log,
  }) async {
    final response = await ApiClient.put(
      '$_sensorsBase/$sensorId',
      data: {
        'deviceId': deviceId,
        'device_id': deviceId,
        'sensorTypeId': sensorTypeId,
        'sensor_type_id': sensorTypeId,
        if (sensorParameterId != null) 'sensorParameterId': sensorParameterId,
        if (sensorParameterId != null) 'sensor_parameter_id': sensorParameterId,
        'name': name,
        if (serialNumber != null) 'serialNumber': serialNumber,
        if (serialNumber != null) 'serial_number': serialNumber,
        if (macAddress != null) 'macAddress': macAddress,
        if (macAddress != null) 'mac_address': macAddress,
        if (channelNumber != null) 'channelNumber': channelNumber,
        if (channelNumber != null) 'channel_number': channelNumber,
        if (lat != null) 'lat': lat,
        if (log != null) 'long': log,
        if (log != null) 'log': log,
        'status': status,
        'unit': unit,
      },
    );
    return _asMap(response.body);
  }

  static Future<void> deleteSensor(String sensorId) async {
    await ApiClient.delete('$_sensorsBase/$sensorId');
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
