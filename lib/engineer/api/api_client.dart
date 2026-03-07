import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engineer_api_config.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = EngineerApiConfig.baseUrl;
  static const String _tokenKey = 'engineer_auth_token';
  static const Duration _requestDeadline = Duration(seconds: 30);

  static Dio? _dio;
  static String? _token;
  static bool _tokenLoaded = false;

  static Dio get _client {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    return _dio!;
  }

  static Future<void> setAuthToken(String token) async {
    _token = token.trim();
    _tokenLoaded = true;
    _applyAuthorizationHeader();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
  }

  static Future<void> clearAuthToken() async {
    _token = null;
    _tokenLoaded = true;
    _applyAuthorizationHeader();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> _ensureTokenLoaded() async {
    if (_tokenLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _tokenLoaded = true;
    _applyAuthorizationHeader();
  }

  static void _applyAuthorizationHeader() {
    final token = _token?.trim();
    if (token == null || token.isEmpty) {
      _client.options.headers.remove('Authorization');
      return;
    }
    _client.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<ApiEnvelope> get(String path) async {
    await _ensureTokenLoaded();
    final response = await _client.get(path).timeout(_requestDeadline);
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> post(String path,
      {Map<String, dynamic>? data}) async {
    await _ensureTokenLoaded();
    final response =
        await _client.post(path, data: data).timeout(_requestDeadline);
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> put(String path,
      {Map<String, dynamic>? data}) async {
    await _ensureTokenLoaded();
    final response =
        await _client.put(path, data: data).timeout(_requestDeadline);
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> delete(String path) async {
    await _ensureTokenLoaded();
    final response = await _client.delete(path).timeout(_requestDeadline);
    return ApiEnvelope.fromResponse(response.data);
  }
}

class ApiEnvelope {
  final String message;
  final bool status;
  final dynamic body;

  const ApiEnvelope({required this.message, required this.status, this.body});

  factory ApiEnvelope.fromResponse(dynamic json) {
    if (json == null) {
      return const ApiEnvelope(message: 'Empty response', status: false);
    }

    if (json is List) {
      return ApiEnvelope(message: 'OK', status: true, body: json);
    }

    if (json is Map<String, dynamic>) {
      final rawStatus = json['status'];
      final status = rawStatus is bool
          ? rawStatus
          : rawStatus?.toString().toUpperCase() == 'SUCCESS';
      return ApiEnvelope(
        message: (json['message'] ?? '').toString(),
        status: status,
        body: json.containsKey('body') ? json['body'] : json,
      );
    }

    if (json is Map) {
      final mapped = json.cast<String, dynamic>();
      final rawStatus = mapped['status'];
      final status = rawStatus is bool
          ? rawStatus
          : rawStatus?.toString().toUpperCase() == 'SUCCESS';
      return ApiEnvelope(
        message: (mapped['message'] ?? '').toString(),
        status: status,
        body: mapped.containsKey('body') ? mapped['body'] : mapped,
      );
    }

    return ApiEnvelope(message: json.toString(), status: true, body: json);
  }
}
