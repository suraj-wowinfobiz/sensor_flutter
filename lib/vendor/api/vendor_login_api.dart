import '../../super_admin/core/api/auth_api.dart';

class VendorLoginApi {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      role: 'vendor',
    );
    return AuthApi.login(request);
  }
}
