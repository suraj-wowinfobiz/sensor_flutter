import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/auth/app_session.dart';
import '../core/api/admin_api_config.dart';

class AnalyticsEvent {
  final String eventType;
  final String sensorId;
  final String readingId;
  final String dataType;
  final double timestamp;
  final double x;

  AnalyticsEvent({
    required this.eventType,
    required this.sensorId,
    required this.readingId,
    required this.dataType,
    required this.timestamp,
    required this.x,
  });

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventType: json['eventType'] ?? 'analytics-live',
      sensorId: json['sensorId'] ?? '',
      readingId: json['readingId'] ?? '',
      dataType: json['dataType'] ?? '',
      timestamp: (json['timestamp'] ?? 0).toDouble(),
      x: (json['x'] ?? 0).toDouble(),
    );
  }
}

class AnalyticsLiveService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AdminApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<AnalyticsEvent>> fetchLiveAnalytics() async {
    try {
      debugPrint('🔵 Fetching live analytics from API...');
      final userId = await AppSession.currentPrincipalId();
      final response = await _dio.get(
        '/api/v1/analytics/events/live',
        queryParameters: userId.isEmpty ? null : {'userId': userId},
      );
      debugPrint('🟢 Response received: ${response.data}');

      if (response.data is List) {
        final List<dynamic> data = response.data as List<dynamic>;
        final events =
            data.map((json) => AnalyticsEvent.fromJson(json)).toList();
        debugPrint('✅ Parsed ${events.length} events');
        return events;
      } else if (response.data is Map) {
        final event = AnalyticsEvent.fromJson(response.data);
        debugPrint('✅ Parsed 1 event');
        return [event];
      }
      return [];
    } catch (e) {
      debugPrint('🔴 Error fetching analytics: $e');
      return [];
    }
  }
}
