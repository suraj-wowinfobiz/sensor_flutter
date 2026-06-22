import 'api_client.dart';

class DeviceApi {
  // Endpoints aligned with API_DOCUMENTATION.json (device-service).
  static const String _devicesBase = '/api/v1/device/devices';

  static Future<List<Map<String, dynamic>>> getAllDevices() async {
    final response = await ApiClient.get('/api/v1/device/getall/');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<List<Map<String, dynamic>>> getDevicesBySite(
    String siteId,
  ) async {
    final response =
        await ApiClient.get('/api/v1/device/sites/$siteId/devices');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<Map<String, dynamic>> getDeviceById(String deviceId) async {
    final response = await ApiClient.get('$_devicesBase/$deviceId');
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> createDevice({
    String? deviceId,
    required String organizationId,
    required String siteId,
    required String zoneId,
    required String serialNumber,
    required String firmwareVersion,
    required String macAddress,
    required String ipAddress,
    required int numberOfChannels,
    required String webHookUrl,
    required double lat,
    required double log,
    required String lastHeartBeat,
    required String status,
  }) async {
    final trimmedDeviceId = deviceId?.trim() ?? '';
    final response = await ApiClient.post(
      _devicesBase,
      data: {
        'deviceId': trimmedDeviceId,
        'organizationId': organizationId,
        'siteId': siteId,
        'zoneId': zoneId,
        'serialNumber': serialNumber,
        'firmwareVersion': firmwareVersion,
        'macAddress': macAddress,
        'ipAddress': ipAddress,
        'numberOfChannels': numberOfChannels,
        'webHookUrl': webHookUrl,
        'lat': lat,
        'log': log,
        'lastHeartBeat': lastHeartBeat,
        'status': status,
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateDevice({
    required String deviceId,
    required String organizationId,
    required String siteId,
    required String zoneId,
    required String serialNumber,
    required String firmwareVersion,
    required String macAddress,
    required String ipAddress,
    required int numberOfChannels,
    required String webHookUrl,
    required double lat,
    required double log,
    required String lastHeartBeat,
    required String status,
  }) async {
    final response = await ApiClient.put(
      '$_devicesBase/$deviceId',
      data: {
        'deviceId': deviceId,
        'organizationId': organizationId,
        'siteId': siteId,
        'zoneId': zoneId,
        'serialNumber': serialNumber,
        'firmwareVersion': firmwareVersion,
        'macAddress': macAddress,
        'ipAddress': ipAddress,
        'numberOfChannels': numberOfChannels,
        'webHookUrl': webHookUrl,
        'lat': lat,
        'log': log,
        'lastHeartBeat': lastHeartBeat,
        'status': status,
      },
    );
    return _asMap(response.body);
  }

  static Future<void> deleteDevice(String deviceId) async {
    await ApiClient.delete('$_devicesBase/$deviceId');
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body == null) return const {};
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
