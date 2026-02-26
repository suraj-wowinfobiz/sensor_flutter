import 'api_client.dart';

class DeviceApi {
  static Future<List<Map<String, dynamic>>> getDevicesBySite(String siteId) async {
    final response = await ApiClient.get('/api/v1/device/sites/$siteId/devices');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<Map<String, dynamic>> createDevice({
    required String siteId,
    required String serialNumber,
    required String firmwareVersion,
    required String status,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/device/devices',
      data: {
        'siteId': siteId,
        'serialNumber': serialNumber,
        'firmwareVersion': firmwareVersion,
        'status': status,
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateDevice({
    required String deviceId,
    required String siteId,
    required String serialNumber,
    required String firmwareVersion,
    required String status,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/device/devices/$deviceId',
      data: {
        'id': deviceId,
        'siteId': siteId,
        'serialNumber': serialNumber,
        'firmwareVersion': firmwareVersion,
        'status': status,
      },
    );
    return _asMap(response.body);
  }

  static Future<void> deleteDevice(String deviceId) async {
    await ApiClient.delete('/api/v1/device/devices/$deviceId');
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
