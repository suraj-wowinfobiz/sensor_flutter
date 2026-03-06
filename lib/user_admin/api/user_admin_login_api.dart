import 'auth_api.dart';
import 'user_admin_api_config.dart';

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
    return AuthApi.login(
      request,
      baseUrl: UserAdminApiConfig.baseUrl,
    );
  }
}
