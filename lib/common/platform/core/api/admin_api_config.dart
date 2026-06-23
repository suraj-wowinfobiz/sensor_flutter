import '../../../../core/config/app_api_endpoints.dart';

class AdminApiConfig {
  AdminApiConfig._();

  static String get baseUrl => AppApiEndpoints.adminBaseUrl;
  static String get apiV1Base => '${AppApiEndpoints.adminBaseUrl}/api/v1';
}
