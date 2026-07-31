// lib/features/admin/presentation/bloc/admin_role/admin_role_bloc.dart
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/admin_role_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_state.dart';

class AdminRoleBloc extends Bloc<AdminRoleEvent, AdminRoleState> {
  final AdminRoleRepository repository;

  AdminRoleBloc({required this.repository}) : super(AdminRoleInitial()) {
    on<FetchAllRolesEvent>(_onFetchAllRoles);
    on<FetchRoleByIdEvent>(_onFetchRoleById);
    on<CreateRoleEvent>(_onCreateRole);
    on<UpdateRoleEvent>(_onUpdateRole);
    on<DeleteRoleEvent>(_onDeleteRole);
    on<AssignRoleToUserEvent>(_onAssignRoleToUser);
    on<RemoveRoleFromUserEvent>(_onRemoveRoleFromUser);
  }

  Future<void> _onFetchAllRoles(
    FetchAllRolesEvent event,
    Emitter<AdminRoleState> emit,
  ) async {
    emit(RolesLoading());
    try {
      final roles = await repository.getAllRoles();
      debugPrint('✅ [AdminRoleBloc] Loaded ${roles.length} roles');
      emit(RolesLoaded(roles));
    } catch (e) {
      debugPrint('❌ [AdminRoleBloc] Error fetching roles: $e');
      emit(AdminRoleError(e.toString()));
    }
  }

  Future<void> _onFetchRoleById(
    FetchRoleByIdEvent event,
    Emitter<AdminRoleState> emit,
  ) async {
    emit(RolesLoading());
    try {
      final role = await repository.getRoleById(event.roleId);
      debugPrint('✅ [AdminRoleBloc] Loaded role: ${role.name}');
      emit(RoleLoaded(role));
    } catch (e) {
      debugPrint('❌ [AdminRoleBloc] Error fetching role: $e');
      emit(AdminRoleError(e.toString()));
    }
  }

  Future<void> _onCreateRole(
    CreateRoleEvent event,
    Emitter<AdminRoleState> emit,
  ) async {
    try {
      await repository.createRole(event.roleData);
      debugPrint('✅ [AdminRoleBloc] Role created successfully');
      emit(const RoleOperationSuccess('Role created successfully'));
      add(const FetchAllRolesEvent());
    } catch (e) {
      debugPrint('❌ [AdminRoleBloc] Error creating role: $e');
      emit(AdminRoleError(e.toString()));
    }
  }

  Future<void> _onUpdateRole(
    UpdateRoleEvent event,
    Emitter<AdminRoleState> emit,
  ) async {
    try {
      await repository.updateRole(event.roleId, event.updateData);
      debugPrint('✅ [AdminRoleBloc] Role updated successfully');
      emit(const RoleOperationSuccess('Role updated successfully'));
      add(const FetchAllRolesEvent());
    } catch (e) {
      debugPrint('❌ [AdminRoleBloc] Error updating role: $e');
      emit(AdminRoleError(e.toString()));
    }
  }

  Future<void> _onDeleteRole(
    DeleteRoleEvent event,
    Emitter<AdminRoleState> emit,
  ) async {
    try {
      await repository.deleteRole(event.roleId);
      debugPrint('✅ [AdminRoleBloc] Role deleted successfully');
      emit(const RoleOperationSuccess('Role deleted successfully'));
      add(const FetchAllRolesEvent());
    } catch (e) {
      debugPrint('❌ [AdminRoleBloc] Error deleting role: $e');
      emit(AdminRoleError(e.toString()));
    }
  }

  Future<void> _onAssignRoleToUser(
    AssignRoleToUserEvent event,
    Emitter<AdminRoleState> emit,
  ) async {
    try {
      // Check if user already has this role
      final userRoles = await repository.getUserRoles(event.userId);
      final hasRole = userRoles.any((role) => role.id == event.roleId);

      if (hasRole) {
        debugPrint('⚠️ [AdminRoleBloc] User already has role: ${event.roleId}');
        emit(const RoleOperationSuccess('User already has this role'));
        return;
      }

      await repository.assignRoleToUser(event.userId, event.roleId);
      debugPrint(
        '✅ [AdminRoleBloc] Role assigned successfully to user: ${event.userId}',
      );
      emit(const RoleOperationSuccess('Role assigned successfully'));
      add(const FetchAllRolesEvent());
    } catch (e) {
      debugPrint('❌ [AdminRoleBloc] Assign role error: $e');

      // Handle specific error messages
      final errorMsg = e.toString();
      if (errorMsg.contains('already has this role')) {
        emit(const RoleOperationSuccess('User already has this role'));
      } else {
        emit(AdminRoleError('Failed to assign role: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRemoveRoleFromUser(
    RemoveRoleFromUserEvent event,
    Emitter<AdminRoleState> emit,
  ) async {
    try {
      // Check if user has this role before removing
      final userRoles = await repository.getUserRoles(event.userId);
      final hasRole = userRoles.any((role) => role.id == event.roleId);

      if (!hasRole) {
        debugPrint(
          '⚠️ [AdminRoleBloc] User does not have role: ${event.roleId}',
        );
        emit(const RoleOperationSuccess('User does not have this role'));
        return;
      }

      await repository.removeRoleFromUser(event.userId, event.roleId);
      debugPrint(
        '✅ [AdminRoleBloc] Role removed successfully from user: ${event.userId}',
      );
      emit(const RoleOperationSuccess('Role removed successfully'));
      add(const FetchAllRolesEvent());
    } catch (e) {
      debugPrint('❌ [AdminRoleBloc] Remove role error: $e');
      emit(AdminRoleError(e.toString()));
    }
  }
}
