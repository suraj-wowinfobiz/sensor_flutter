import '../../super_admin/core/api/auth_api.dart';
import 'user_api_config.dart';

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
    return AuthApi.login(
      request,
      baseUrl: UserApiConfig.baseUrl,
    );
  }
}
