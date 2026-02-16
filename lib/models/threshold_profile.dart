import 'package:equatable/equatable.dart';

class ThresholdProfile extends Equatable {
  final String id;
  final String name;
  final String description;

  const ThresholdProfile({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ThresholdProfile.fromJson(Map<String, dynamic> json) {
    return ThresholdProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  ThresholdProfile copyWith({
    String? name,
    String? description,
  }) {
    return ThresholdProfile(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, name, description];
}
