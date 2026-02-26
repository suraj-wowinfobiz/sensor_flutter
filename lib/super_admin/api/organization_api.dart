import 'dart:convert';
import 'package:http/http.dart' as http;

class OrganizationApi {
  static const String baseUrl = 'http://103.211.202.145:8091';

  static Future<OrganizationResponse> createOrganization({
    required String name,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/org/organization'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return OrganizationResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create organization: ${response.body}');
    }
  }
}

class OrganizationResponse {
  final OrganizationBody body;
  final String message;
  final bool status;

  OrganizationResponse({
    required this.body,
    required this.message,
    required this.status,
  });

  factory OrganizationResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationResponse(
      body: OrganizationBody.fromJson(json['body']),
      message: json['message'],
      status: json['status'],
    );
  }
}

class OrganizationBody {
  final String organizationId;
  final String name;
  final String email;
  final String status;
  final String createdAt;
  final dynamic sites;

  OrganizationBody({
    required this.organizationId,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
    this.sites,
  });

  factory OrganizationBody.fromJson(Map<String, dynamic> json) {
    return OrganizationBody(
      organizationId: json['organizationId'],
      name: json['name'],
      email: json['email'],
      status: json['status'],
      createdAt: json['createdAt'],
      sites: json['sites'],
    );
  }
}
