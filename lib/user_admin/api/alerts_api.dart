import '../models/alert.dart';
import 'api_client.dart';

class AlertsApi {
  static Future<List<Alert>> getAlerts({
    String? status,
    String? level,
    String? sensorId,
    String? assignedTo,
    String? from,
    String? to,
  }) async {
    final response = await ApiClient.get(
      '/api/v1/alerts',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (level != null && level.isNotEmpty) 'level': level,
        if (sensorId != null && sensorId.isNotEmpty) 'sensorId': sensorId,
        if (assignedTo != null && assignedTo.isNotEmpty)
          'assignedTo': assignedTo,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    final data = response.body;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Alert.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> resolveAlert(String alertId) async {
    await ApiClient.post('/api/v1/alerts/$alertId/resolve');
  }

  static Future<void> createAlert({
    required String sensorId,
    required String sensorParameterId,
    required String alertLevel,
    required String message,
    required String assignedTo,
  }) async {
    await ApiClient.post(
      '/api/v1/alerts',
      data: {
        'sensorId': sensorId.trim(),
        'sensorParameterId': sensorParameterId.trim(),
        'alertLevel': alertLevel.trim(),
        'message': message.trim(),
        'assignedTo': assignedTo.trim(),
      },
    );
  }

  static Future<void> updateAlert({
    required String id,
    required String sensorId,
    required String sensorParameterId,
    required String alertLevel,
    required String message,
    required String assignedTo,
  }) async {
    await ApiClient.put(
      '/api/v1/alerts/$id',
      data: {
        'sensorId': sensorId.trim(),
        'sensorParameterId': sensorParameterId.trim(),
        'alertLevel': alertLevel.trim(),
        'message': message.trim(),
        'assignedTo': assignedTo.trim(),
      },
    );
  }

  static Future<void> deleteAlert(String id) async {
    await ApiClient.delete('/api/v1/alerts/$id');
  }
}
