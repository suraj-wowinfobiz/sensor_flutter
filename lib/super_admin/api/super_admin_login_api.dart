import '../core/api/auth_api.dart';

class SuperAdminLoginApi {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      role: 'super_admin',
    );
    return AuthApi.login(request);
  }
}
