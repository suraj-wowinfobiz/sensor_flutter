import 'package:equatable/equatable.dart';

class SensorType extends Equatable {
  final String id;
  final String name;
  final String category;
  final String description;

  const SensorType({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
  });

  factory SensorType.fromJson(Map<String, dynamic> json) {
    return SensorType(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, category, description];
}
