import 'api_client.dart';

class AnalyticsApi {
  static Future<List<Map<String, dynamic>>> getEvents() async {
    final response = await ApiClient.get('/api/v1/analytics/events');
    return _asListMap(response.body);
  }

  static Future<List<Map<String, dynamic>>> getRecentEvents({
    int limit = 50,
  }) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/events/recent',
      queryParameters: {'limit': limit},
    );
    return _asListMap(response.body);
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await ApiClient.get('/api/v1/analytics/dashboard/summary');
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> getOverview() async {
    final response = await ApiClient.get('/api/v1/analytics/overview');
    return _asMap(response.body);
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }

  static List<Map<String, dynamic>> _asListMap(dynamic body) {
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
