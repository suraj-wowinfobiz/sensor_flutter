import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/admin_api_config.dart';

class LiveReading {
  final String readingId;
  final String sensorId;
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;

  LiveReading({
    required this.readingId,
    required this.sensorId,
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });

  factory LiveReading.fromJson(Map<String, dynamic> json) {
    final params = json['parameters'] as Map<String, dynamic>;
    return LiveReading(
      readingId: json['readingId'] as String,
      sensorId: json['sensorId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      x: double.parse(params['x'].toString()),
      y: double.parse(params['y'].toString()),
      z: double.parse(params['z'].toString()),
    );
  }
}

class LiveReadingsService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AdminApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<LiveReading>> fetchLiveReadings() async {
    try {
      debugPrint('🔵 Fetching live readings from API...');
      final response = await _dio.get('/api/v1/ingestion/readings/live');
      debugPrint('🟢 Response received: ${response.data}');
      final List<dynamic> data = response.data as List<dynamic>;
      final readings = data.map((json) => LiveReading.fromJson(json)).toList();
      debugPrint('✅ Parsed ${readings.length} readings');
      return readings;
    } catch (e) {
      debugPrint('🔴 Error fetching readings: $e');
      return [];
    }
  }
}
