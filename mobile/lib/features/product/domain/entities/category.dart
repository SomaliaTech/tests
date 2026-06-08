class Category {
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
}
