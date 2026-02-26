import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsLiveEvent {
  final String eventType;
  final String sensorId;
  final String readingId;
  final String dataType;
  final String timestamp;
  final double x;

  AnalyticsLiveEvent({
    required this.eventType,
    required this.sensorId,
    required this.readingId,
    required this.dataType,
    required this.timestamp,
    required this.x,
  });

  factory AnalyticsLiveEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsLiveEvent(
      eventType: json['eventType'] ?? '',
      sensorId: json['sensorId'] ?? '',
      readingId: json['readingId'] ?? '',
      dataType: json['dataType'] ?? '',
      timestamp: json['timestamp'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
    );
  }
}

class AnalyticsLiveApi {
  static const String baseUrl = 'http://103.211.202.145:8091';
  static const String endpoint = '/api/v1/analytics/events/live';

  static Stream<AnalyticsLiveEvent> connectToLiveStream() async* {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse('$baseUrl$endpoint'));
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
}
