import 'api_client.dart';

class ThresholdsApi {
  static Future<List<Map<String, dynamic>>> getThresholds() async {
    final response = await ApiClient.get('/api/v1/thresholds');
    return _asListMap(response.body);
  }

  static Future<List<Map<String, dynamic>>> getProfiles() async {
    final response = await ApiClient.get('/api/v1/thresholds/profiles');
    return _asListMap(response.body);
  }

  static Future<Map<String, dynamic>> createProfile({
    required String name,
    required String description,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/thresholds/profiles',
      data: {'name': name, 'description': description},
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> createThreshold({
    required double minThresholdValue,
    required String sensorParameterId,
    required String thresholdProfileId,
    required double maxThresholdValue,
    required double warningLevel,
    required double criticalLevel,
    double? warrningLevel,
    String? sensorParamterId,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/thresholds',
      data: {
        'minThresholdValue': minThresholdValue,
        'sensorParameterId': sensorParameterId,
        'thresholdProfileId': thresholdProfileId,
        'maxThresholdValue': maxThresholdValue,
        'warningLevel': warningLevel,
        'criticalLevel': criticalLevel,
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String name,
    required String description,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/thresholds/profiles/$id',
      data: {'name': name, 'description': description},
    );
    return _asMap(response.body);
  }

  static Future<void> deleteProfile(String id) async {
    await ApiClient.delete('/api/v1/thresholds/profiles/$id');
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
        map['profiles'],
        map['thresholdProfiles'],
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
