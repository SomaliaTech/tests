// lib/features/admin/presentation/screens/edit_user/edit_user_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';

import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/permission_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';

import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mobile/features/admin/domain/entities/permission_entity.dart';

import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_state.dart';

import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_event.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_state.dart';

import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_page_header.dart';
import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_save_button.dart';

import 'package:mobile/features/admin/presentation/screens/edit_user/edit_user_profile_card.dart';
import 'package:mobile/features/admin/presentation/screens/edit_user/edit_user_personal_info.dart';
import 'package:mobile/features/admin/presentation/screens/edit_user/edit_user_contact_info.dart';
import 'package:mobile/features/admin/presentation/screens/edit_user/edit_user_permissions_section.dart';

import 'package:toastification/toastification.dart';

class EditUserScreen extends StatefulWidget {
  final AdminUserEntity user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  bool _isAdmin = false;
  bool _isSuperAdmin = false;

  bool _isLoading = false;
  bool _hasChanges = false;

  bool _isCurrentUserSuperAdmin = false;
  bool _canToggleAdmin = false;
  bool _canAssignRoles = false;

  final List<String> _rolesToAdd = [];
  final List<String> _rolesToRemove = [];

  Future<List<RoleEntity>>? _userRolesFuture;
  List<RoleEntity> _initialUserRoles = [];
  List<RoleEntity> _allRoles = [];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.name ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');

    _isAdmin = widget.user.isAdmin;
    _isSuperAdmin = widget.user.isSuperAdmin ?? false;

    _nameController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);

    _loadCurrentUserAccess();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminRoleBloc>().add(const FetchAllRolesEvent());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userRolesFuture ??= _loadUserRoles();
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkChanges);
    _emailController.removeListener(_checkChanges);
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ==========================================
  // PERMISSIONS
  // ==========================================

  Future<void> _loadCurrentUserAccess() async {
    try {
      final storageService = sl<StorageService>();
      final isSuperAdmin = await storageService.getIsSuperAdmin();

      bool canToggleAdmin = isSuperAdmin;
      bool canAssignRoles = isSuperAdmin;

      try {
        final permissionService = GetIt.instance<PermissionService>();
        final permissions = await permissionService.loadPermissions(
          forceRefresh: false,
        );

        bool has(String p) {
          if (permissions.contains('*')) return true;
          if (permissions.contains(p)) return true;
          final module = p.split(':').first;
          return permissions.contains('$module:manage');
        }

        canAssignRoles =
            isSuperAdmin ||
            has('admin:update') ||
            has('admin:manage') ||
            has('user:manage');

        canToggleAdmin = isSuperAdmin;
      } catch (e) {
        debugPrint('❌ [EditUser] PermissionService unavailable: $e');
      }

      if (!mounted) return;

      setState(() {
        _isCurrentUserSuperAdmin = isSuperAdmin;
        _canToggleAdmin = canToggleAdmin;
        _canAssignRoles = canAssignRoles;
      });
    } catch (e) {
      debugPrint('❌ [EditUser] Failed to load access: $e');
      if (!mounted) return;
      setState(() {
        _isCurrentUserSuperAdmin = false;
        _canToggleAdmin = false;
        _canAssignRoles = false;
      });
    }
  }

  Future<List<RoleEntity>> _loadUserRoles() async {
    try {
      final repository = context.read<AdminRoleBloc>().repository;
      final roles = await repository.getUserRoles(widget.user.id);
      if (mounted) setState(() => _initialUserRoles = roles);
      return roles;
    } catch (e) {
      debugPrint('❌ [EditUser] Failed to load user roles: $e');
      return [];
    }
  }

  // ==========================================
  // STATE MANAGEMENT
  // ==========================================

  bool _computeHasChanges() {
    final nameChanged = _nameController.text.trim() != (widget.user.name ?? '');
    final emailChanged =
        _emailController.text.trim() != (widget.user.email ?? '');
    final adminChanged =
        _canToggleAdmin && !_isSuperAdmin && _isAdmin != widget.user.isAdmin;
    final rolesChanged =
        _canAssignRoles &&
        (_rolesToAdd.isNotEmpty || _rolesToRemove.isNotEmpty);
    return nameChanged || emailChanged || adminChanged || rolesChanged;
  }

  void _checkChanges() {
    setState(() => _hasChanges = _computeHasChanges());
  }

  void _toggleRole(String roleId, bool assign) {
    setState(() {
      final isInitiallyAssigned = _initialUserRoles.any(
        (role) => role.id == roleId,
      );

      if (assign) {
        _rolesToRemove.remove(roleId);
        if (!isInitiallyAssigned) {
          _rolesToAdd.remove(roleId);
          _rolesToAdd.add(roleId);
        }
      } else {
        _rolesToAdd.remove(roleId);
        if (isInitiallyAssigned) {
          _rolesToRemove.remove(roleId);
          _rolesToRemove.add(roleId);
        }
      }

      _hasChanges = _computeHasChanges();
    });
  }

  bool _hasRole(String roleId, List<RoleEntity> currentUserRoles) {
    if (_rolesToAdd.contains(roleId)) return true;
    if (_rolesToRemove.contains(roleId)) return false;
    return currentUserRoles.any((role) => role.id == roleId);
  }

  // ==========================================
  // SAVE
  // ==========================================

  void _showToast(String message, bool isSuccess) {
    if (!mounted) return;
    toastification.show(
      context: context,
      title: Text(isSuccess ? 'Success' : 'Error'),
      description: Text(message),
      type: isSuccess ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (!_hasChanges || _isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final userBloc = context.read<UserBloc>();
      final roleRepository = context.read<AdminRoleBloc>().repository;

      final nameChanged =
          _nameController.text.trim() != (widget.user.name ?? '');
      final emailChanged =
          _emailController.text.trim() != (widget.user.email ?? '');
      final adminChanged =
          _canToggleAdmin && !_isSuperAdmin && _isAdmin != widget.user.isAdmin;
      final rolesChanged =
          _canAssignRoles &&
          (_rolesToAdd.isNotEmpty || _rolesToRemove.isNotEmpty);

      final updateData = <String, dynamic>{};
      if (nameChanged) updateData['name'] = _nameController.text.trim();
      if (emailChanged) updateData['email'] = _emailController.text.trim();
      if (adminChanged) updateData['isAdmin'] = _isAdmin;

      // 1. Update user info
      if (updateData.isNotEmpty) {
        final userResultFuture = userBloc.stream.firstWhere(
          (state) => state is UserOperationSuccess || state is UserError,
        );

        userBloc.add(UpdateUserEvent(widget.user.id, updateData));

        final userState = await userResultFuture.timeout(
          const Duration(seconds: 20),
        );

        if (userState is UserError) throw userState.message;
      }

      // 2. Assign / remove roles
      if (rolesChanged) {
        for (final roleId in List<String>.from(_rolesToAdd)) {
          debugPrint('📤 [EditUser] Assigning role: $roleId');
          await roleRepository.assignRoleToUser(widget.user.id, roleId);
        }

        for (final roleId in List<String>.from(_rolesToRemove)) {
          debugPrint('📤 [EditUser] Removing role: $roleId');
          try {
            await roleRepository.removeRoleFromUser(widget.user.id, roleId);
          } catch (e) {
            if (!e.toString().contains('404')) rethrow;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _rolesToAdd.clear();
        _rolesToRemove.clear();
        _hasChanges = false;
        _isLoading = false;
      });

      context.read<AdminRoleBloc>().add(const FetchAllRolesEvent());
      _showToast('User updated successfully', true);
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ [EditUser] Save error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showToast(e.toString(), false);
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminRoleBloc, AdminRoleState>(
      listener: (context, state) {
        if (state is RolesLoaded) {
          setState(() => _allRoles = state.roles);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: CustomScrollView(
          slivers: [
            AdminPageHeader(
              title: 'Edit User',
              subtitle: 'Update user information',
              icon: Iconsax.user_edit,
              action: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: (_hasChanges && !_isLoading) ? _saveUser : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: (_hasChanges && !_isLoading)
                          ? const LinearGradient(
                              colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                            )
                          : null,
                      color: (!_hasChanges || _isLoading) ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.tick_circle,
                                color: _hasChanges
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _hasChanges ? 'Save' : 'Saved',
                                style: TextStyle(
                                  color: _hasChanges
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditUserProfileCard(
                        user: widget.user,
                        isAdmin: _isAdmin,
                        isSuperAdmin: _isSuperAdmin,
                      ),
                      const SizedBox(height: 20),
                      EditUserPersonalInfo(
                        nameController: _nameController,
                        emailController: _emailController,
                      ),
                      const SizedBox(height: 20),
                      EditUserContactInfo(phoneNumber: widget.user.phoneNumber),
                      const SizedBox(height: 20),
                      EditUserPermissionsSection(
                        isAdmin: _isAdmin,
                        isSuperAdmin: _isSuperAdmin,
                        canToggleAdmin: _canToggleAdmin,
                        canAssignRoles: _canAssignRoles,
                        userRolesFuture: _userRolesFuture,
                        initialUserRoles: _initialUserRoles,
                        rolesToAdd: _rolesToAdd,
                        rolesToRemove: _rolesToRemove,
                        allRoles: _allRoles,
                        onAdminToggle: (value) {
                          setState(() {
                            _isAdmin = value;
                            _hasChanges = _computeHasChanges();
                          });
                        },
                        onToggleRole: _toggleRole,
                        hasRole: _hasRole,
                      ),
                      const SizedBox(height: 32),
                      AdminSaveButton(
                        hasChanges: _hasChanges,
                        isLoading: _isLoading,
                        onSave: _saveUser,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
