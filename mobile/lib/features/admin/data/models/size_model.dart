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
}
