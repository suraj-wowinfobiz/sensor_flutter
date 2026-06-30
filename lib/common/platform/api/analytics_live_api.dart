import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/auth/app_session.dart';
import '../core/api/admin_api_config.dart';

class AnalyticsLiveEvent {
  final String eventType;
  final String sensorId;
  final String readingId;
  final String dataType;
  final String timestamp;
  final double x;
  final double y;
  final double z;

  AnalyticsLiveEvent({
    required this.eventType,
    required this.sensorId,
    required this.readingId,
    required this.dataType,
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });

  factory AnalyticsLiveEvent.fromJson(Map<String, dynamic> json) {
    final values = _extractXyz(json);
    return AnalyticsLiveEvent(
      eventType: json['eventType'] ?? '',
      sensorId: json['sensorId'] ?? '',
      readingId: json['readingId'] ?? '',
      dataType: json['dataType'] ?? '',
      timestamp: json['timestamp'] ?? '',
      x: values.$1,
      y: values.$2,
      z: values.$3,
    );
  }

  static (double, double, double) _extractXyz(Map<String, dynamic> json) {
    final x = _toDouble(json['x']);
    final y = _toDouble(json['y']);
    final z = _toDouble(json['z']);
    if (x != null && y != null && z != null) return (x, y, z);

    final rawPayload = json['rawPayload'];
    if (rawPayload is Map) {
      final params = rawPayload['parameters'];
      if (params is Map) {
        final px = _toDouble(params['x']);
        final py = _toDouble(params['y']);
        final pz = _toDouble(params['z']);
        if (px != null && py != null && pz != null) return (px, py, pz);
      }
    }

    final processedPayload = json['processedPayload'];
    if (processedPayload is Map) {
      final rx = _toDouble(processedPayload['rollDegrees']) ??
          _toDouble(processedPayload['x']);
      final ry = _toDouble(processedPayload['pitchDegrees']) ??
          _toDouble(processedPayload['y']);
      final rz = _toDouble(processedPayload['tiltFromVerticalDegrees']) ??
          _toDouble(processedPayload['z']);
      if (rx != null && ry != null && rz != null) return (rx, ry, rz);
    }

    final series = json['series'];
    if (series is List) {
      double? sx;
      double? sy;
      double? sz;
      for (final item in series) {
        if (item is! Map) continue;
        final name = item['name']?.toString().toLowerCase();
        final value = _toDouble(item['value']);
        if (name == null || value == null) continue;
        if (name == 'x' || name.endsWith('.x')) sx = value;
        if (name == 'y' || name.endsWith('.y')) sy = value;
        if (name == 'z' || name.endsWith('.z')) sz = value;
      }
      if (sx != null && sy != null && sz != null) return (sx, sy, sz);
    }

    return (0, 0, 0);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class AnalyticsLiveApi {
  static const String endpoint = '/api/v1/analytics/events/live';

  static Stream<AnalyticsLiveEvent> connectToLiveStream() async* {
    final client = http.Client();
    try {
      final request = http.Request(
        'GET',
        await _buildEndpointUri(),
      );
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request);

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.isEmpty) continue;

          String jsonStr = line;
          if (line.startsWith('data: ')) {
            jsonStr = line.substring(6);
          }

          try {
            final json = jsonDecode(jsonStr);
            if (json['eventType'] == 'analytics-live') {
              yield AnalyticsLiveEvent.fromJson(json);
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  static Future<Uri> _buildEndpointUri() async {
    final uri = Uri.parse('${AdminApiConfig.baseUrl}$endpoint');
    if (uri.queryParameters.containsKey('userId')) {
      return uri;
    }

    final userId = await AppSession.currentPrincipalId();
    if (userId.isEmpty) {
      return uri;
    }

    if (uri.path.contains('{userId}')) {
      return uri.replace(path: uri.path.replaceAll('{userId}', userId));
    }

    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        'userId': userId,
      },
    );
  }
}
