import 'api_client.dart';

class SensorApi {
  static Future<List<Map<String, dynamic>>> getSensorsByDevice(
    String deviceId,
  ) async {
    final response = await ApiClient.get('/api/v1/sensors/devices/$deviceId/sensors');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<Map<String, dynamic>> createSensor({
    required String deviceId,
    required String sensorTypeId,
    required String name,
    required String status,
    required String unit,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/sensors/devices/$deviceId/sensors',
      data: {
        'deviceId': deviceId,
        'sensorTypeId': sensorTypeId,
        'name': name,
        'status': status,
        'unit': unit,
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
  }) async {
    final response = await ApiClient.put(
      '/api/v1/sensors/sensors/$sensorId',
      data: {
        'sensorId': sensorId,
        'deviceId': deviceId,
        'sensorTypeId': sensorTypeId,
        'name': name,
        'status': status,
        'unit': unit,
      },
    );
    return _asMap(response.body);
  }

  static Future<void> deleteSensor(String sensorId) async {
    await ApiClient.delete('/api/v1/sensors/sensors/$sensorId');
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
