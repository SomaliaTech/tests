// lib/features/admin/data/models/role_model.dart

import 'package:mobile/features/admin/domain/entities/permission_entity.dart';

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.name,
    required super.description,
    required super.permissions,
    required super.isSystem,
    required super.userCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? json['roleId'] ?? '',
      name: json['name'] ?? json['roleName'] ?? '',
      description: json['description'] ?? json['roleDescription'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      isSystem: json['isSystem'] ?? false,
      userCount: json['userCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
      'isSystem': isSystem,
      'userCount': userCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  RoleEntity toEntity() {
    return RoleEntity(
      id: id,
      name: name,
      description: description,
      permissions: permissions,
      isSystem: isSystem,
      userCount: userCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
