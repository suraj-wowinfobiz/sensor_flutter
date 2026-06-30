import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class UsersApi {
  static Future<String> currentBackendRole() => _currentBackendRole();

  static Future<String> currentPrincipalId() => _currentPrincipalId();

  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final currentPrincipalId = await _currentPrincipalId();
    final response = userId.trim() == currentPrincipalId
        ? await ApiClient.get('/api/v1/auth/me')
        : await ApiClient.get('/api/v1/users/$userId');
    return _asMap(response.body);
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await ApiClient.get('/api/v1/users/get-all');
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
        map['users'],
        map['items'],
        map['results'],
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

  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String role,
    required String organizationId,
    required String password,
    int? maxUsersAllowed,
  }) async {
    final normalizedRole = _normalizeRole(role);
    final currentBackendRole = await _currentBackendRole();

    if (currentBackendRole == 'vendor' && normalizedRole == 'vendor_engineer') {
      final response = await ApiClient.post(
        '/api/v1/vendors-engineer/engineers',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'organizationId': _organizationIdValue(organizationId),
        },
      );
      return _asMap(response.body);
    }

    final response = await ApiClient.post(
      '/api/v1/admins/users',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (maxUsersAllowed != null) 'maxUsersAllowed': maxUsersAllowed,
        'organizationId': _organizationIdValue(organizationId),
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String name,
    required String email,
    required String organizationId,
    required String password,
    int? maxUsersAllowed,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/super-admins/admins',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (maxUsersAllowed != null) 'maxUsersAllowed': maxUsersAllowed,
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
    int? maxUsersAllowed,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/vendors',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (maxUsersAllowed != null) 'maxUsersAllowed': maxUsersAllowed,
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
    String? password,
  }) async {
    final normalizedRole = _normalizeRole(role);
    final response = await ApiClient.put(
      _updatePathForRole(normalizedRole, id),
      data: {
        'name': name,
        'email': email,
        if (password != null && password.trim().isNotEmpty)
          'password': password.trim(),
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    String? password,
    required String organizationId,
    required int maxUsersAllowed,
    required bool active,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/auth/me',
      data: {
        'name': name,
        'email': email,
        if (password != null && password.trim().isNotEmpty)
          'password': password.trim(),
        'organizationId': organizationId.trim(),
        'maxUsersAllowed': maxUsersAllowed,
        'active': active,
      },
    );
    return _asMap(response.body);
  }

  static Future<List<String>> getUserSensorAccess(String userId) async {
    final response = await ApiClient.get('/api/v1/users/$userId/sensor-access');
    return _extractSensorIds(response.body);
  }

  static Future<List<String>> getMySensorAccess() async {
    final response = await ApiClient.get('/api/v1/auth/me/sensor-access');
    return _extractSensorIds(response.body);
  }

  static Future<Map<String, dynamic>> updateUserSensorAccess({
    required String userId,
    required List<String> sensorIds,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/users/$userId/sensor-access',
      data: {
        'sensorIds': sensorIds
            .map((sensorId) => sensorId.trim())
            .where((sensorId) => sensorId.isNotEmpty)
            .toList(),
      },
    );
    return _asMap(response.body);
  }

  static Future<void> deleteUser(String id, {String? role}) async {
    await ApiClient.delete(
      _deletePathForRole(_normalizeRole(role ?? ''), id),
    );
  }

  static Future<Map<String, dynamic>> assignAccess({
    required String principalType,
    required String principalId,
    String? siteId,
    String? zoneId,
  }) async {
    final normalizedSiteId = (siteId ?? '').trim();
    final normalizedZoneId = (zoneId ?? '').trim();
    if (normalizedSiteId.isEmpty == normalizedZoneId.isEmpty) {
      throw ArgumentError('Provide exactly one of siteId or zoneId');
    }
    final response = await ApiClient.post(
      '/api/v1/access',
      data: {
        'principalType': principalType,
        'principalId': principalId,
        'scopes': [
          {
            if (normalizedSiteId.isNotEmpty) 'siteId': normalizedSiteId,
            if (normalizedZoneId.isNotEmpty) 'zoneId': normalizedZoneId,
          }
        ],
      },
    );
    return _asMap(response.body);
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
              if ((scope['organizationId'] ?? '').trim().isNotEmpty)
                'organizationId': scope['organizationId']!.trim(),
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
    String? organizationId,
    String? siteId,
    String? zoneId,
  }) async {
    final response = await ApiClient.put(
      '/api/v1/access/$accessId',
      data: {
        'principalType': principalType,
        'principalId': principalId,
        if ((organizationId ?? '').trim().isNotEmpty)
          'organizationId': organizationId!.trim(),
        if ((siteId ?? '').trim().isNotEmpty) 'siteId': siteId!.trim(),
        if ((zoneId ?? '').trim().isNotEmpty) 'zoneId': zoneId!.trim(),
      },
    );
    return _asMap(response.body);
  }

  static Future<Map<String, dynamic>> revokeAccess({
    required String principalType,
    required String principalId,
    String? siteId,
    String? zoneId,
  }) async {
    // Revoke endpoint is not available in the current access API contract.
    // Keep signature for backward compatibility with callers.
    return const {};
  }

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return const {};
  }

  static List<String> _extractSensorIds(dynamic body) {
    final map = _asMap(body);
    final rawSensorIds = map['sensorIds'];
    if (rawSensorIds is! List) return const [];
    return rawSensorIds
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'engineer') return 'vendor_engineer';
    return normalized;
  }

  static String _updatePathForRole(String role, String id) {
    switch (role) {
      case 'admin':
        return '/api/v1/super-admins/admins/$id';
      case 'vendor':
        return '/api/v1/vendors/$id';
      case 'vendor_engineer':
        return '/api/v1/vendors-engineer/engineers/$id';
      default:
        return '/api/v1/users/$id';
    }
  }

  static String _deletePathForRole(String role, String id) {
    switch (role) {
      case 'admin':
        return '/api/v1/super-admins/admins/$id';
      case 'vendor':
        return '/api/v1/vendors/$id';
      case 'vendor_engineer':
        return '/api/v1/vendors-engineer/engineers/$id';
      default:
        return '/api/v1/users/$id';
    }
  }

  static Future<String> _currentBackendRole() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionRole = (prefs.getString('app_session_role') ?? '').trim();
    switch (sessionRole) {
      case 'admin':
        return 'super_admin';
      case 'user_admin':
        return 'admin';
      case 'engineer':
        return 'vendor_engineer';
      default:
        return sessionRole;
    }
  }

  static Future<String> _currentPrincipalId() async {
    final prefs = await SharedPreferences.getInstance();
    final backendRole = await _currentBackendRole();
    switch (backendRole) {
      case 'super_admin':
        return (prefs.getString('admin_principal_id') ??
                prefs.getString('super_admin_principal_id') ??
                '')
            .trim();
      case 'admin':
        return (prefs.getString('user_admin_principal_id') ??
                prefs.getString('admin_principal_id') ??
                '')
            .trim();
      case 'vendor':
        return (prefs.getString('vendor_principal_id') ?? '').trim();
      case 'vendor_engineer':
        return (prefs.getString('engineer_principal_id') ?? '').trim();
      case 'user':
        return (prefs.getString('user_principal_id') ?? '').trim();
      default:
        return '';
    }
  }

  static dynamic _organizationIdValue(String organizationId) {
    // Return as string - API expects UUID
    return organizationId.trim();
  }
}
