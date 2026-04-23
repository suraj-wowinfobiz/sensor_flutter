class AppApiEndpoints {
  AppApiEndpoints._();

  static const String adminBaseUrl = String.fromEnvironment(
    'ADMIN_API_BASE_URL',
    defaultValue: 'http://103.211.202.145:8091',
  );

  static const String userBaseUrl = String.fromEnvironment(
    'USER_API_BASE_URL',
    defaultValue: 'http://103.211.202.145:8091',
  );

  static const String userAdminBaseUrl = String.fromEnvironment(
    'USER_ADMIN_API_BASE_URL',
    defaultValue: 'http://103.211.202.145:8091',
  );

  static const String engineerBaseUrl = String.fromEnvironment(
    'ENGINEER_API_BASE_URL',
    defaultValue: 'http://103.211.202.145:8091',
  );

  static const String vendorBaseUrl = String.fromEnvironment(
    'VENDOR_API_BASE_URL',
    defaultValue: 'http://103.211.202.145:8091',
  );
}
