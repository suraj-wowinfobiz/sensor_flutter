import 'package:equatable/equatable.dart';

class Organization extends Equatable {
  final String id;
  final String name;
  final String email;
  final String status;
  final String ownerUserId;
  final DateTime createdAt;

  const Organization({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.ownerUserId,
    required this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      ownerUserId: json['owner_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'status': status,
      'owner_user_id': ownerUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Organization copyWith({
    String? name,
    String? email,
    String? status,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      ownerUserId: ownerUserId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, status, ownerUserId, createdAt];
}
