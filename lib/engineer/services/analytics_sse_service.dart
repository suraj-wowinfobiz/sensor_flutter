import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

class AnalyticsSseService {
  static const String _tokenStorageKey = 'engineer_auth_token';

  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  http.Client? _client;
  StreamSubscription<String>? _streamSubscription;
  bool _isConnected = false;

  Stream<dynamic> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  void _tryEmitBufferedJson(StringBuffer buffer) {
    if (buffer.isEmpty) return;
    final raw = buffer.toString();
    try {
      _controller.add(jsonDecode(raw));
      buffer.clear();
    } catch (_) {
      // Keep buffering until a complete JSON payload is available.
    }
  }

  Future<void> connect() async {
    if (_isConnected) return;

    debugPrint('🔌 Connecting to SSE endpoint...');
    _client = http.Client();

    try {
      final request = http.Request(
        'GET',
        Uri.parse('${ApiClient.baseUrl}/api/v1/analytics/events/live'),
      );
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenStorageKey)?.trim();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        _isConnected = true;
        debugPrint('✅ SSE Connected');

        final dataBuffer = StringBuffer();
        _streamSubscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) {
              _tryEmitBufferedJson(dataBuffer);
              return;
            }
            if (trimmed.startsWith(':')) return;
            if (trimmed.startsWith('data:')) {
              final payload = trimmed.substring(5).trimLeft();
              if (payload.isNotEmpty) {
                if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
                dataBuffer.write(payload);
                _tryEmitBufferedJson(dataBuffer);
              }
              return;
            }
          },
          onError: (error) {
            debugPrint('❌ SSE Error: $error');
            _isConnected = false;
          },
          onDone: () {
            debugPrint('🔌 SSE Disconnected');
            _isConnected = false;
          },
        );
      } else {
        debugPrint('❌ SSE Connection failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ SSE Connection error: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _client?.close();
    _client = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
