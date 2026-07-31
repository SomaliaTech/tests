// lib/features/admin/presentation/bloc/admin_role/admin_role_event.dart
import 'package:equatable/equatable.dart';

abstract class AdminRoleEvent extends Equatable {
  const AdminRoleEvent();
  @override
  List<Object?> get props => [];
}

class FetchAllRolesEvent extends AdminRoleEvent {
  const FetchAllRolesEvent(); // ✅ Add const constructor
}

class FetchRoleByIdEvent extends AdminRoleEvent {
  final String roleId;
  const FetchRoleByIdEvent(this.roleId);
  @override
  List<Object?> get props => [roleId];
}

class CreateRoleEvent extends AdminRoleEvent {
  final Map<String, dynamic> roleData;
  const CreateRoleEvent(this.roleData);
  @override
  List<Object?> get props => [roleData];
}

class UpdateRoleEvent extends AdminRoleEvent {
  final String roleId;
  final Map<String, dynamic> updateData;
  const UpdateRoleEvent(this.roleId, this.updateData);
  @override
  List<Object?> get props => [roleId, updateData];
}

class DeleteRoleEvent extends AdminRoleEvent {
  final String roleId;
  const DeleteRoleEvent(this.roleId);
  @override
  List<Object?> get props => [roleId];
}

class AssignRoleToUserEvent extends AdminRoleEvent {
  final String userId;
  final String roleId;
  const AssignRoleToUserEvent(this.userId, this.roleId);
  @override
  List<Object?> get props => [userId, roleId];
}

class RemoveRoleFromUserEvent extends AdminRoleEvent {
  final String userId;
  final String roleId;
  const RemoveRoleFromUserEvent(this.userId, this.roleId);
  @override
  List<Object?> get props => [userId, roleId];
}
