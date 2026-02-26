import '../super_admin/core/api/auth_api.dart';

class EngineerLoginApi {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      role: 'vendor_engineer',
    );
    return AuthApi.login(request);
  }
}
