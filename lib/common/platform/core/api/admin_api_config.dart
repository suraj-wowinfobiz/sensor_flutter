import '../../../../core/config/app_api_endpoints.dart';

class AdminApiConfig {
  AdminApiConfig._();

  static const String baseUrl = AppApiEndpoints.adminBaseUrl;
  static const String apiV1Base = '$baseUrl/api/v1';
}
