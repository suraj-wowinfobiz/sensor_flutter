import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrgServiceApi {
  static const String baseUrl = 'http://195.250.21.120/api/v1/org';
  static const String _tokenStorageKey = 'super_admin_auth_token';
  static const Duration _requestDeadline = Duration(seconds: 30);

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenStorageKey)?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Organizations
  static Future<ApiResponse> getAllOrganizations() async {
    final res = await _send(http.get(
      Uri.parse('$baseUrl/organization'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> getOrganization(String orgId) async {
    final res = await _send(http.get(
      Uri.parse('$baseUrl/organization/$orgId'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> createOrganization(
      String name, String email) async {
    final res = await _send(http.post(
      Uri.parse('$baseUrl/organization'),
      headers: await _headers(json: true),
      body: jsonEncode({'name': name, 'email': email}),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> updateOrganization(
      String orgId, String name, String email) async {
    final res = await _send(http.put(
      Uri.parse('$baseUrl/organization/$orgId'),
      headers: await _headers(json: true),
      body: jsonEncode({'name': name, 'email': email}),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> deleteOrganization(String orgId) async {
    final res = await _send(http.delete(
      Uri.parse('$baseUrl/organization/$orgId'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> getOrganizationSites(String orgId) async {
    final res = await _send(http.get(
      Uri.parse('$baseUrl/organization/$orgId/sites'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> createSiteForOrganization(
      String orgId, String name, String location) async {
    final res = await _send(http.post(
      Uri.parse('$baseUrl/organization/$orgId/sites'),
      headers: await _headers(json: true),
      body: jsonEncode({'name': name, 'location': location}),
    ));
    return _handleResponse(res);
  }

  // Sites
  static Future<ApiResponse> getAllSites() async {
    final res = await _send(http.get(
      Uri.parse('$baseUrl/site/'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> getSite(String siteId) async {
    final res = await _send(http.get(
      Uri.parse('$baseUrl/site/$siteId'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> createSite(
      String orgId, String name, String location) async {
    final res = await _send(http.post(
      Uri.parse('$baseUrl/site/'),
      headers: await _headers(json: true),
      body: jsonEncode({'orgId': orgId, 'name': name, 'location': location}),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> updateSite(
      String siteId, String name, String location,
      {String? orgId}) async {
    final body = <String, dynamic>{'name': name, 'location': location};
    if (orgId != null) body['orgId'] = orgId;
    final res = await _send(http.put(
      Uri.parse('$baseUrl/site/$siteId'),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> deleteSite(String siteId) async {
    final res = await _send(http.delete(
      Uri.parse('$baseUrl/site/$siteId'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> getSiteZones(String siteId) async {
    final res = await _send(http.get(
      Uri.parse('$baseUrl/site/$siteId/zones'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> createZoneForSite(
      String siteId, String name) async {
    final res = await _send(http.post(
      Uri.parse('$baseUrl/site/$siteId/zones'),
      headers: await _headers(json: true),
      body: jsonEncode({'name': name}),
    ));
    return _handleResponse(res);
  }

  // Zones
  static Future<ApiResponse> getZonesBySite(String siteId) async {
    final uri = Uri.parse('$baseUrl/zone/').replace(
      queryParameters: {'siteId': siteId},
    );
    final res = await _send(http.get(uri, headers: await _headers()));
    return _handleResponse(res);
  }

  static Future<ApiResponse> getZone(String zoneId) async {
    final res = await _send(http.get(
      Uri.parse('$baseUrl/zone/$zoneId'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> createZone(String siteId, String name) async {
    final res = await _send(http.post(
      Uri.parse('$baseUrl/zone/'),
      headers: await _headers(json: true),
      body: jsonEncode({'siteId': siteId, 'name': name}),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> updateZone(String zoneId, String name,
      {String? siteId}) async {
    final body = <String, dynamic>{'name': name};
    if (siteId != null) body['siteId'] = siteId;
    final res = await _send(http.put(
      Uri.parse('$baseUrl/zone/$zoneId'),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    ));
    return _handleResponse(res);
  }

  static Future<ApiResponse> deleteZone(String zoneId) async {
    final res = await _send(http.delete(
      Uri.parse('$baseUrl/zone/$zoneId'),
      headers: await _headers(),
    ));
    return _handleResponse(res);
  }

  static ApiResponse _handleResponse(http.Response res) {
    final parsed = _tryParseMap(res.body);
    final message = parsed?['message']?.toString() ?? 'Request failed';
    final statusField = parsed?['status'];
    final isStatusTrue = statusField == true;
    final isHttpOk = res.statusCode >= 200 && res.statusCode < 300;
    if (isHttpOk && isStatusTrue) {
      return ApiResponse(
        message: message,
        status: true,
        body: parsed?['body'],
      );
    }
    throw ApiException(message);
  }

  static Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(_requestDeadline, onTimeout: () {
        throw TimeoutException('Request timeout');
      });
    } on TimeoutException {
      throw ApiException(
        'Connection timeout. Check if backend is running.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  static Map<String, dynamic>? _tryParseMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return null;
    } catch (_) {
      return null;
    }
  }
}

class ApiResponse {
  final String message;
  final bool status;
  final dynamic body;

  ApiResponse({required this.message, required this.status, this.body});
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
