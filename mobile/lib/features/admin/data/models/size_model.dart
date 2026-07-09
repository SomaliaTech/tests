import '../../domain/entities/size_entity.dart';

class SizeModel extends SizeEntity {
  const SizeModel({
    required super.id,
    required super.name,
    required super.value,
  });

  factory SizeModel.fromJson(Map<String, dynamic> json) {
    return SizeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      value: json['value'] ?? '',
    );
  }

  // ✅ NEW: Convert to entity
  SizeEntity toEntity() {
    return SizeEntity(id: id, name: name, value: value);
  }
}
