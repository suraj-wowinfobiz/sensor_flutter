import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_api_config.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = UserApiConfig.baseUrl;
  static const String _tokenKey = 'user_auth_token';

  static Dio? _dio;
  static String? _token;

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
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearAuthToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<String?> _resolveToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_tokenKey);
    if (stored != null && stored.isNotEmpty) {
      _token = stored;
      return stored;
    }
    return null;
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _resolveToken();
    if (token == null || token.isEmpty) {
      return {'Content-Type': 'application/json'};
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiEnvelope> get(String path) async {
    final response =
        await _client.get(path, options: Options(headers: await _headers()));
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> post(String path,
      {Map<String, dynamic>? data}) async {
    final response = await _client.post(
      path,
      data: data,
      options: Options(headers: await _headers()),
    );
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> put(String path,
      {Map<String, dynamic>? data}) async {
    final response = await _client.put(
      path,
      data: data,
      options: Options(headers: await _headers()),
    );
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> delete(String path) async {
    final response =
        await _client.delete(path, options: Options(headers: await _headers()));
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
