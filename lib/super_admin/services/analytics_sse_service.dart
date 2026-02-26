import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AnalyticsSseService {
  static const String baseUrl = 'http://103.211.202.145:8091';
  
  final StreamController<Map<String, dynamic>> _controller = StreamController<Map<String, dynamic>>.broadcast();
  http.Client? _client;
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    debugPrint('🔌 Connecting to SSE endpoint...');
    _client = http.Client();
    
    try {
      final request = http.Request('GET', Uri.parse('$baseUrl/api/v1/analytics/events/live'));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      
      final response = await _client!.send(request);
      
      if (response.statusCode == 200) {
        _isConnected = true;
        debugPrint('✅ SSE Connected');
        
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (line.trim().isEmpty || line.startsWith(':')) return;
            
            try {
              if (line.startsWith('data: ')) {
                final jsonStr = line.substring(6);
                final data = jsonDecode(jsonStr);
                debugPrint('📨 SSE Event: $data');
                _controller.add(data);
              } else {
                final data = jsonDecode(line);
                debugPrint('📨 SSE Event: $data');
                _controller.add(data);
              }
            } catch (e) {
              debugPrint('⚠️ Parse error: $e, line: $line');
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
    _client?.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
