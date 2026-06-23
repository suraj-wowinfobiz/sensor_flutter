import 'package:flutter/foundation.dart';

class AppApiEndpoints {
  AppApiEndpoints._();

  static const String _adminBaseUrlDefine = String.fromEnvironment(
    'ADMIN_API_BASE_URL',
    defaultValue: '',
  );
  static const String _userBaseUrlDefine = String.fromEnvironment(
    'USER_API_BASE_URL',
    defaultValue: '',
  );
  static const String _userAdminBaseUrlDefine = String.fromEnvironment(
    'USER_ADMIN_API_BASE_URL',
    defaultValue: '',
  );
  static const String _engineerBaseUrlDefine = String.fromEnvironment(
    'ENGINEER_API_BASE_URL',
    defaultValue: '',
  );
  static const String _vendorBaseUrlDefine = String.fromEnvironment(
    'VENDOR_API_BASE_URL',
    defaultValue: '',
  );

  static String get adminBaseUrl {
    final value = _adminBaseUrlDefine.trim();
    return value.isEmpty ? _defaultLocalBaseUrl() : value;
  }

  static String get userBaseUrl {
    final value = _userBaseUrlDefine.trim();
    return value.isEmpty ? adminBaseUrl : value;
  }

  static String get userAdminBaseUrl {
    final value = _userAdminBaseUrlDefine.trim();
    return value.isEmpty ? adminBaseUrl : value;
  }

  static String get engineerBaseUrl {
    final value = _engineerBaseUrlDefine.trim();
    return value.isEmpty ? adminBaseUrl : value;
  }

  static String get vendorBaseUrl {
    final value = _vendorBaseUrlDefine.trim();
    return value.isEmpty ? adminBaseUrl : value;
  }

  static String _defaultLocalBaseUrl() {
    if (kIsWeb) {
      final rawHost = Uri.base.host.trim();
      final host = rawHost.isEmpty || rawHost == '0.0.0.0'
          ? 'localhost'
          : rawHost;
      return 'http://$host:8091';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8091';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8091';
    }
  }
}
