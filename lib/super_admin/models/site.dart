import 'package:equatable/equatable.dart';

class Site extends Equatable {
  final String id;
  final String organizationId;
  final String name;
  final String location;
  final DateTime createdAt;

  const Site({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.location,
    required this.createdAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Site copyWith({
    String? name,
    String? location,
    String? organizationId,
  }) {
    return Site(
      id: id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      location: location ?? this.location,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, organizationId, name, location, createdAt];
}
