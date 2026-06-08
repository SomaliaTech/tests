import '../../domain/entities/category.dart';

class CategoryModel {
  const CategoryModel._();

  static Category fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
    );
  }

  static Map<String, dynamic> toJson(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'slug': category.slug,
      'description': category.description,
      'parentId': category.parentId,
    };
  }
}
