import 'api_client.dart';

class SensorTypeApi {
  static const String _sensorTypesPath = '/api/v1/sensor-type/sensor-types';

  static Future<List<Map<String, dynamic>>> getAllSensorTypes() async {
    final response = await ApiClient.get(_sensorTypesPath);
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<Map<String, dynamic>> createSensorType({
    required String name,
    required String category,
    String? description,
  }) async {
    final response = await ApiClient.post(
      _sensorTypesPath,
      data: {
        'name': name,
        'category': category,
        'description': description ?? '',
      },
    );
    final body = response.body;
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
