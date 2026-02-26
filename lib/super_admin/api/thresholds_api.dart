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
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
