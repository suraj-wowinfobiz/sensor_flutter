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
        .map((e) => _mapAlert(Map<String, dynamic>.from(e)))
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

  static Alert _mapAlert(Map<String, dynamic> json) {
    return Alert(
      id: (json['id'] ?? json['alertId'] ?? '').toString(),
      sensorId: (json['sensorId'] ?? json['sensor_id'] ?? '').toString(),
      sensorParameterId:
          (json['sensorParameterId'] ?? json['sensor_parameter_id'] ?? '')
              .toString(),
      alertLevel: (json['alertLevel'] ?? json['alert_level'] ?? '').toString(),
      assignedTo: (json['assignedTo'] ?? json['assigned_to'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      triggeredAt: DateTime.tryParse(
            (json['triggeredAt'] ?? json['triggered_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      acknowledgedAt: DateTime.tryParse(
        (json['acknowledgedAt'] ?? json['acknowledged_at'] ?? '').toString(),
      ),
      resolvedAt: DateTime.tryParse(
        (json['resolvedAt'] ?? json['resolved_at'] ?? '').toString(),
      ),
    );
  }
}
