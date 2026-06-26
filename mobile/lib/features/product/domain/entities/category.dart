import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final String? iconUrl; // ✅ NEW

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.iconUrl, // ✅ NEW
  });

  bool get isParent => parentId == null;
  bool get hasIcon => iconUrl != null && iconUrl!.isNotEmpty; // ✅ NEW

  @override
  List<Object?> get props => [id, name, slug, description, parentId, iconUrl];
}
