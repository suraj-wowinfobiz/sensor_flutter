import 'api_client.dart';

class UsersApi {
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await ApiClient.get('/api/v1/users');
    final body = response.body;
    if (body is! List) return const [];
    return body.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String role,
    required String organizationId,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/users',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'organizationId': _organizationIdValue(organizationId),
        'role': role,
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String name,
    required String email,
    required String organizationId,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/users',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'organizationId': _organizationIdValue(organizationId),
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> createVendor({
    required String name,
    required String email,
    required String organizationId,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/vendors',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'organizationId': _organizationIdValue(organizationId),
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/users/$id',
      data: {
        'name': name,
        'email': email,
        'role': role,
      },
    );
    return _asMap(response.body);
  }

  static Future<void> deleteUser(String id) async {
    await ApiClient.delete('/api/v1/users/$id');
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }

  static dynamic _organizationIdValue(String organizationId) {
    // Return as string - API expects UUID
    return organizationId.trim();
  }
}
