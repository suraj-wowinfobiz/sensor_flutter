import 'api_client.dart';

class DashboardApi {
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiClient.get('/api/v1/dashboard/stats');
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> getOverview() async {
    final response = await ApiClient.get('/api/v1/dashboard/overview');
    return _asMap(response.body);
  }

  static Future<List<Map<String, dynamic>>> getRecentAlerts() async {
    final response = await ApiClient.get('/api/v1/dashboard/recent-alerts');
    return _asListMap(response.body);
  }

  static Future<Map<String, dynamic>> getQuickStats() async {
    final response = await ApiClient.get('/api/v1/dashboard/quick-stats');
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
