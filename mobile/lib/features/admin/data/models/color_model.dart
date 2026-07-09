import '../../domain/entities/color_entity.dart';

class ColorModel extends ColorEntity {
  const ColorModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  // ✅ NEW: Convert to entity
  ColorEntity toEntity() {
    return ColorEntity(id: id, name: name, code: code);
  }
}
