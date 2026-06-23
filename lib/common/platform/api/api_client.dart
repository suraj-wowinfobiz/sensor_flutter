import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/admin_api_config.dart';

class ApiClient {
  ApiClient._();

  static const String _tokenStorageKey = 'platform_auth_token';
  static const Duration _requestDeadline = Duration(seconds: 30);
  static String? _authToken;
  static bool _tokenLoaded = false;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AdminApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    ),
  );

  static Future<void> _ensureTokenLoaded() async {
    _dio.options.baseUrl = AdminApiConfig.baseUrl;
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
    final response = await _dio
        .get<dynamic>(
          path,
          queryParameters: queryParameters,
        )
        .timeout(_requestDeadline);
    print(
        '🌐 GET $path -> statusCode=${response.statusCode}, data=${response.data}');
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    await _ensureTokenLoaded();
    final response = await _dio
        .post<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: headers != null ? Options(headers: headers) : null,
        )
        .timeout(_requestDeadline);
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureTokenLoaded();
    final response = await _dio
        .put<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
        )
        .timeout(_requestDeadline);
    return ApiEnvelope.fromResponse(response.data);
  }

  static Future<ApiEnvelope> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureTokenLoaded();
    final response = await _dio
        .delete<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
        )
        .timeout(_requestDeadline);
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
      // Only treat as envelope if it has 'body' key (the actual envelope structure)
      if (json.containsKey('body')) {
        return ApiEnvelope(
          message: json['message']?.toString(),
          status: json['status'],
          body: json['body'],
        );
      }
      // Otherwise, the entire response IS the data
      return ApiEnvelope(message: 'OK', status: true, body: json);
    }
    if (json is Map) {
      final mapped = json.cast<String, dynamic>();
      if (mapped.containsKey('body')) {
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
