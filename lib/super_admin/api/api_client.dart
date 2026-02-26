import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = 'http://103.211.202.145:8091';
  static const String _tokenStorageKey = 'super_admin_auth_token';
  static String? _authToken;
  static bool _tokenLoaded = false;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  static Future<void> _ensureTokenLoaded() async {
    if (_tokenLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenStorageKey);
    _tokenLoaded = true;
    _applyAuthorizationHeader();
  }

  static void _applyAuthorizationHeader() {
    final token = _authToken?.trim();
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<void> setAuthToken(String token) async {
    _authToken = token.trim();
    _tokenLoaded = true;
    _applyAuthorizationHeader();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, _authToken!);
  }

  static Future<void> clearAuthToken() async {
    _authToken = null;
    _tokenLoaded = true;
    _applyAuthorizationHeader();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
  }

  static Future<ApiEnvelope> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureTokenLoaded();
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureTokenLoaded();
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureTokenLoaded();
    final response = await _dio.put<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureTokenLoaded();
    final response = await _dio.delete<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return ApiEnvelope.fromResponse(response.data);
  }
}

class ApiEnvelope {
  final String? message;
  final dynamic status;
  final dynamic body;

  const ApiEnvelope({required this.message, required this.status, this.body});

  bool get isSuccess {
    if (status is bool) return status as bool;
    if (status is String) return (status as String).toUpperCase() == 'SUCCESS';
    return false;
  }

  factory ApiEnvelope.fromResponse(dynamic json) {
    if (json == null) {
      return const ApiEnvelope(message: 'Empty response', status: false);
    }
    if (json is Map<String, dynamic>) {
      if (json.containsKey('message') ||
          json.containsKey('status') ||
          json.containsKey('body')) {
        return ApiEnvelope(
          message: json['message']?.toString(),
          status: json['status'],
          body: json['body'],
        );
      }
      return ApiEnvelope(message: 'OK', status: true, body: json);
    }
    if (json is Map) {
      final mapped = json.cast<String, dynamic>();
      if (mapped.containsKey('message') ||
          mapped.containsKey('status') ||
          mapped.containsKey('body')) {
        return ApiEnvelope(
          message: mapped['message']?.toString(),
          status: mapped['status'],
          body: mapped['body'],
        );
      }
      return ApiEnvelope(message: 'OK', status: true, body: mapped);
    }
    if (json is List) {
      return ApiEnvelope(message: 'OK', status: true, body: json);
    }
    return ApiEnvelope(message: json.toString(), status: true, body: json);
  }
}
