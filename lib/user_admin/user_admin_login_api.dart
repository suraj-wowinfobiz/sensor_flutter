import '../../super_admin/core/api/auth_api.dart';

class UserAdminLoginApi {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      role: 'admin',
    );
    return AuthApi.login(request);
  }
}
