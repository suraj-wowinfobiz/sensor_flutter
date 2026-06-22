import 'api_client.dart';

class ReportsApi {
  static Future<List<Map<String, dynamic>>> getReports() async {
    final response = await ApiClient.get('/api/v1/reports');
    return _asListMap(response.body);
  }

  static Future<Map<String, dynamic>> getReportById(String id) async {
    final response = await ApiClient.get('/api/v1/reports/$id');
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> generateReport(
    Map<String, dynamic> payload,
  ) async {
    final response =
        await ApiClient.post('/api/v1/reports/generate', data: payload);
    return _asMap(response.body);
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
