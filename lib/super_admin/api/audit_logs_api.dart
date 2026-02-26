import 'api_client.dart';

class AuditLogsApi {
  static Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final response = await ApiClient.get('/api/v1/audit-logs');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
