import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/app_session.dart';
import '../core/api/admin_api_config.dart';

class AnalyticsSseService {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  http.Client? _client;
  StreamSubscription<String>? _streamSubscription;
  Future<void>? _connectTask;
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
    final inFlight = _connectTask;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final task = _connectInternal();
    _connectTask = task;
    try {
      await task;
    } finally {
      if (identical(_connectTask, task)) {
        _connectTask = null;
      }
    }
  }

  Future<void> _connectInternal() async {
    debugPrint('🔌 Connecting to SSE endpoint...');
    _client = http.Client();

    try {
      final request = http.Request(
        'GET',
        await _buildEndpointUri(),
      );
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

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
    _connectTask = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  Future<Uri> _buildEndpointUri() async {
    final uri = Uri.parse('${AdminApiConfig.apiV1Base}/analytics/events/live');
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
