import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/app_session.dart';
import '../core/api/admin_api_config.dart';

class GenericSseService {
  GenericSseService(
    this.endpointPath, {
    this.emitInterval = const Duration(milliseconds: 120),
  });

  final String endpointPath;
  final Duration emitInterval;
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  http.Client? _client;
  StreamSubscription<String>? _streamSubscription;
  Future<void>? _connectTask;
  bool _isConnected = false;
  Timer? _emitTimer;
  dynamic _pendingEvent;

  Stream<dynamic> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  void _emitPayload(dynamic payload) {
    if (emitInterval <= Duration.zero) {
      _controller.add(payload);
      return;
    }

    _pendingEvent = payload;
    if (_emitTimer != null) return;
    _emitTimer = Timer(emitInterval, () {
      _emitTimer = null;
      final event = _pendingEvent;
      _pendingEvent = null;
      if (event != null && !_controller.isClosed) {
        _controller.add(event);
      }
    });
  }

  void _tryEmitBufferedJson(StringBuffer buffer) {
    if (buffer.isEmpty) return;
    final raw = buffer.toString();
    try {
      _emitPayload(jsonDecode(raw));
      buffer.clear();
    } catch (_) {
      // Keep buffering until complete JSON arrives.
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
    _client = http.Client();
    try {
      final request = http.Request(
        'GET',
        await _buildEndpointUri(),
      );
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _client!.send(request);
      if (response.statusCode != 200) {
        debugPrint('❌ SSE $endpointPath failed: ${response.statusCode}');
        return;
      }

      _isConnected = true;
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
          }
        },
        onError: (error) {
          debugPrint('❌ SSE $endpointPath error: $error');
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (e) {
      debugPrint('❌ SSE $endpointPath connect error: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _emitTimer?.cancel();
    _emitTimer = null;
    _pendingEvent = null;
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
    final uri = Uri.parse('${AdminApiConfig.baseUrl}$endpointPath');
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
