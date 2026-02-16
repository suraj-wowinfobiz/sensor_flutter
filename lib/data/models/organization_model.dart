import 'package:equatable/equatable.dart';

class OrganizationModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String status;
  final String ownerUserId;
  final DateTime createdAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.ownerUserId,
    required this.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      ownerUserId: json['owner_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'status': status,
        'owner_user_id': ownerUserId,
        'created_at': createdAt.toIso8601String(),
      };

  OrganizationModel copyWith({
    String? name,
    String? email,
    String? status,
    String? ownerUserId,
  }) {
    return OrganizationModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, status, ownerUserId, createdAt];
}
