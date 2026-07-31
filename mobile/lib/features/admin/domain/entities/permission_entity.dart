// lib/features/admin/domain/entities/permission_entity.dart
class PermissionEntity {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isGranted;

  const PermissionEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.isGranted = false,
  });

  PermissionEntity copyWith({bool? isGranted}) {
    return PermissionEntity(
      id: id,
      name: name,
      description: description,
      category: category,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}

// lib/features/admin/domain/entities/role_entity.dart
class RoleEntity {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final bool isSystem;
  final int userCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoleEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    this.isSystem = false,
    this.userCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEditable => !isSystem;
}
