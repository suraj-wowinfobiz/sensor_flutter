import 'api_client.dart';

class SensorParameterApi {
  static const String _basePath = '/api/v1/sensor-parameter';

  static Future<List<Map<String, dynamic>>> getAllSensorParameters() async {
    final response = await ApiClient.get('$_basePath/get-all');
    return _asListMap(response.body);
  }

  static Future<Map<String, dynamic>> createSensorParameter({
    required String sensorTypeId,
    required String name,
    required String unit,
    required double minValue,
    required double maxValue,
  }) async {
    final response = await ApiClient.post(
      '$_basePath/sensor-types/$sensorTypeId/parameters',
      data: {
        'name': name,
        'unit': unit,
        'minValue': minValue,
        'maxValue': maxValue,
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateSensorParameter({
    required String sensorTypeId,
    required String sensorParameterId,
    required String name,
    required String unit,
    required double minValue,
    required double maxValue,
  }) async {
    final response = await ApiClient.put(
      '$_basePath/sensor-types/$sensorTypeId/parameters',
      data: {
        'sensorParameterId': sensorParameterId,
        'name': name,
        'unit': unit,
        'minValue': minValue,
        'maxValue': maxValue,
      },
    );
    return _asMap(response.body);
  }

  static Future<List<Map<String, dynamic>>> getParametersBySensorType(
    String sensorTypeId,
  ) async {
    final normalized = sensorTypeId.trim();
    if (normalized.isEmpty) return const [];
    final response =
        await ApiClient.get('$_basePath/sensor-types/$normalized/parameters');
    return _asListMap(response.body);
  }

  static List<Map<String, dynamic>> _asListMap(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (body is Map) {
      final map = body.cast<String, dynamic>();
      final candidates = [
        map['data'],
        map['items'],
        map['results'],
        map['parameters'],
        map['sensorParameters'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
      }
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
