import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main_page.dart';
import '../../common/platform/api/api_client.dart';

class AppSession {
  AppSession._();

  static const _sessionTokenKey = 'app_session_token';
  static const _sessionUserKey = 'app_session_user';
  static const _sessionRoleKey = 'app_session_role';
  static const _sessionExpiryKey = 'app_session_expiry';

  static const _principalKeys = <String>[
    'user_principal_id',
    'user_admin_principal_id',
    'engineer_principal_id',
    'vendor_principal_id',
    'analytics_principal_id',
    'analytics_role_principal_id',
    'admin_principal_id',
    'super_admin_principal_id',
  ];

  /// Save session data after successful login
  static Future<void> saveSession({
    required String token,
    required String username,
    required String role,
    Duration sessionDuration = const Duration(hours: 24),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime =
        DateTime.now().add(sessionDuration).millisecondsSinceEpoch;

    await prefs.setString(_sessionTokenKey, token);
    await prefs.setString(_sessionUserKey, username);
    await prefs.setString(_sessionRoleKey, role);
    await prefs.setInt(_sessionExpiryKey, expiryTime);
  }

  /// Check if session is valid
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionTokenKey);
    final expiryTime = prefs.getInt(_sessionExpiryKey);

    if (token == null || expiryTime == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return now < expiryTime;
  }

  /// Get current session data
  static Future<Map<String, String?>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_sessionTokenKey),
      'username': prefs.getString(_sessionUserKey),
      'role': prefs.getString(_sessionRoleKey),
    };
  }

  /// Extend session expiry
  static Future<void> extendSession(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(duration).millisecondsSinceEpoch;
    await prefs.setInt(_sessionExpiryKey, expiryTime);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear session keys
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_sessionUserKey);
    await prefs.remove(_sessionRoleKey);
    await prefs.remove(_sessionExpiryKey);

    // Clear principal keys
    for (final key in _principalKeys) {
      await prefs.remove(key);
    }

    await ApiClient.clearAuthToken();
  }

  static Future<void> logoutToLanding(BuildContext context) async {
    await clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainPage()),
      (route) => false,
    );
  }
}
