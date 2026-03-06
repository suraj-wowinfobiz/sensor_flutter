import '../../super_admin/core/api/auth_api.dart';

class AnalyticsLoginApi {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      role: 'analytics',
    );
    return AuthApi.login(request);
  }
}
