import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'user_admin_api_config.dart';

class LoginRequest {
  final String email;
  final String password;
  final String role;

  LoginRequest({
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
      };
}

class LoginResponse {
  final String message;
  final String status;
  final LoginBody body;

  LoginResponse({
    required this.message,
    required this.status,
    required this.body,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawBody = json['body'];
    final bodyMap = rawBody is Map<String, dynamic>
        ? rawBody
        : (rawBody is Map
            ? rawBody.cast<String, dynamic>()
            : <String, dynamic>{});
    return LoginResponse(
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      body: LoginBody.fromJson(bodyMap),
    );
  }
}

class LoginBody {
  final String principalId;
  final String principalType;
  final String token;

  LoginBody({
    required this.principalId,
    required this.principalType,
    required this.token,
  });

  factory LoginBody.fromJson(Map<String, dynamic> json) {
    return LoginBody(
      principalId: (json['principalId'] ?? '').toString(),
      principalType: (json['principalType'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }
}

class AuthApi {
  static const Duration _requestDeadline = Duration(seconds: 10);

  static Future<LoginResponse> login(
    LoginRequest request, {
    String? baseUrl,
  }) async {
    try {
      final rootUrl = (baseUrl == null || baseUrl.trim().isEmpty)
          ? UserAdminApiConfig.baseUrl
          : baseUrl.trim();
      final response = await http
          .post(
            Uri.parse('$rootUrl/api/v1/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_requestDeadline);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsed = jsonDecode(response.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(parsed);
      }
      throw AuthApiException(
          'Login failed (${response.statusCode}): ${response.body}');
    } on TimeoutException {
      throw AuthApiException(
        'Request timed out. Please check your internet connection and server URL.',
      );
    } on SocketException catch (e) {
      throw AuthApiException(
        'Network connection failed: ${e.message}. If you are on Android, make sure the server allows HTTP traffic.',
      );
    } on http.ClientException catch (e) {
      throw AuthApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Login failed: $e');
    }
  }
}

class AuthApiException implements Exception {
  final String message;
  AuthApiException(this.message);

  @override
  String toString() => message;
}
