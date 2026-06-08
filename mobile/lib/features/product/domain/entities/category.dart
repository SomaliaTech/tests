import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
  });

  @override
  List<Object?> get props => [id, name, slug, description, parentId];
}
