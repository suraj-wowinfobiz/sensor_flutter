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

  static Future<List<Map<String, dynamic>>> getAccessList() async {
    final response = await ApiClient.get('/api/v1/access');
    final body = response.body;
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (body is Map) {
      final map = body.cast<String, dynamic>();
      final candidates = [
        map['data'],
        map['items'],
        map['results'],
        map['access'],
        map['accesses'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
      }
    }
    return const [];
  }

  static Future<Map<String, dynamic>> createAccess({
    required String principalType,
    required String principalId,
    required List<Map<String, String>> scopes,
  }) async {
    final normalizedScopes = scopes
        .map((scope) => {
              if ((scope['siteId'] ?? '').trim().isNotEmpty)
                'siteId': scope['siteId']!.trim(),
              if ((scope['zoneId'] ?? '').trim().isNotEmpty)
                'zoneId': scope['zoneId']!.trim(),
            })
        .where((scope) => scope.isNotEmpty)
        .toList();
    final response = await ApiClient.post(
      '/api/v1/access',
      data: {
        'principalType': principalType,
        'principalId': principalId,
        'scopes': normalizedScopes,
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateAccess({
    required String accessId,
    required String principalType,
    required String principalId,
    String? siteId,
    String? zoneId,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/access/$accessId',
      data: {
        'principalType': principalType,
        'principalId': principalId,
        if ((siteId ?? '').trim().isNotEmpty) 'siteId': siteId!.trim(),
        if ((zoneId ?? '').trim().isNotEmpty) 'zoneId': zoneId!.trim(),
      },
    );
    return _asMap(response.body);
  }
}
