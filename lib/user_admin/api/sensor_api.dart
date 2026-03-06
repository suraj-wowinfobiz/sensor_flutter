import 'api_client.dart';

class SensorApi {
  static Future<List<Map<String, dynamic>>> getAllSensors() async {
    final response = await ApiClient.get('/api/v1/sensors/get-all');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
