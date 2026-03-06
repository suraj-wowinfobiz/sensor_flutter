import 'api_client.dart';

class UsersApi {
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await ApiClient.get('/api/v1/users/$userId');
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateUserById({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String organizationId,
    required int maxUsersAllowed,
    required bool active,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/users/$userId',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'organizationId': organizationId,
        'maxUsersAllowed': maxUsersAllowed,
        'active': active,
      },
    );
    return _asMap(response.body);
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }
}
