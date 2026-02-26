import 'dart:convert';
import 'package:http/http.dart' as http;

enum UserRole { USER, VENDOR, VENDOR_ENGINEER, ADMIN, SUPER_ADMIN }

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
    return LoginResponse(
      message: json['message'],
      status: json['status'],
      body: LoginBody.fromJson(json['body']),
    );
  }
}

class LoginBody {
  final int principalId;
  final String principalType;
  final String token;

  LoginBody({
    required this.principalId,
    required this.principalType,
    required this.token,
  });

  factory LoginBody.fromJson(Map<String, dynamic> json) {
    return LoginBody(
      principalId: json['principalId'],
      principalType: json['principalType'],
      token: json['token'],
    );
  }
}

class AuthApi {
  static const String baseUrl = 'http://103.211.202.145:8091';

  static Future<LoginResponse> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
}
