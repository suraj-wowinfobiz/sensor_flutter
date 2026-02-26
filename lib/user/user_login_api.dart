import '../../super_admin/core/api/auth_api.dart';

class UserLoginApi {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      role: 'user',
    );
    return AuthApi.login(request);
  }
}
