// lib/features/admin/presentation/bloc/admin_role/admin_role_state.dart
import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/permission_entity.dart';

abstract class AdminRoleState extends Equatable {
  const AdminRoleState();
  @override
  List<Object?> get props => [];
}

class AdminRoleInitial extends AdminRoleState {}

class RolesLoading extends AdminRoleState {}

class RolesLoaded extends AdminRoleState {
  final List<RoleEntity> roles;
  const RolesLoaded(this.roles);
  @override
  List<Object?> get props => [roles];
}

class RoleLoaded extends AdminRoleState {
  final RoleEntity role;
  const RoleLoaded(this.role);
  @override
  List<Object?> get props => [role];
}

class RoleOperationSuccess extends AdminRoleState {
  final String message;
  const RoleOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminRoleError extends AdminRoleState {
  final String message;
  const AdminRoleError(this.message);
  @override
  List<Object?> get props => [message];
}
