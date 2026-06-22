import 'package:equatable/equatable.dart';

class Zone extends Equatable {
  final String id;
  final String siteId;
  final String name;

  const Zone({
    required this.id,
    required this.siteId,
    required this.name,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String,
      siteId: json['site_id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'name': name,
    };
  }

  Zone copyWith({
    String? siteId,
    String? name,
  }) {
    return Zone(
      id: id,
      siteId: siteId ?? this.siteId,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [id, siteId, name];
}
