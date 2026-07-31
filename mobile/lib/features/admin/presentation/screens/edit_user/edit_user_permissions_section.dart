// lib/features/admin/presentation/screens/edit_user/edit_user_permissions_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/permission_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_state.dart';
import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_info_box.dart';
import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_role_switch.dart';
import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_section_card.dart';

/// Permission module definition
class _PermissionModule {
  final String name;
  final IconData icon;
  final Color color;
  final String module;

  const _PermissionModule({
    required this.name,
    required this.icon,
    required this.color,
    required this.module,
  });
}

class EditUserPermissionsSection extends StatelessWidget {
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool canToggleAdmin;
  final bool canAssignRoles;
  final Future<List<RoleEntity>>? userRolesFuture;
  final List<RoleEntity> initialUserRoles;
  final List<String> rolesToAdd;
  final List<String> rolesToRemove;
  final List<RoleEntity> allRoles;
  final ValueChanged<bool> onAdminToggle;
  final void Function(String roleId, bool assign) onToggleRole;
  final bool Function(String roleId, List<RoleEntity> currentUserRoles) hasRole;

  const EditUserPermissionsSection({
    super.key,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.canToggleAdmin,
    required this.canAssignRoles,
    required this.userRolesFuture,
    required this.initialUserRoles,
    required this.rolesToAdd,
    required this.rolesToRemove,
    required this.allRoles,
    required this.onAdminToggle,
    required this.onToggleRole,
    required this.hasRole,
  });

  static const List<_PermissionModule> _permissionModules = [
    _PermissionModule(
      name: 'Products',
      icon: Iconsax.box_1,
      color: Color(0xFF2ED573),
      module: 'product',
    ),
    _PermissionModule(
      name: 'Categories',
      icon: Iconsax.category,
      color: Color(0xFF7C3AED),
      module: 'category',
    ),
    _PermissionModule(
      name: 'Orders',
      icon: Iconsax.shopping_cart,
      color: Color(0xFFFFA502),
      module: 'order',
    ),
    _PermissionModule(
      name: 'Markets',
      icon: Iconsax.shop,
      color: Color(0xFF1E90FF),
      module: 'market',
    ),
    _PermissionModule(
      name: 'Colors',
      icon: Iconsax.colorfilter,
      color: Color(0xFFFF6B81),
      module: 'color',
    ),
    _PermissionModule(
      name: 'Sizes',
      icon: Iconsax.ruler,
      color: Color(0xFF5F27CD),
      module: 'size',
    ),
    _PermissionModule(
      name: 'Users',
      icon: Iconsax.user,
      color: Color(0xFF00D2D3),
      module: 'user',
    ),
    _PermissionModule(
      name: 'Revenue',
      icon: Iconsax.money_tick,
      color: Color(0xFF10AC84),
      module: 'revenue',
    ),
    _PermissionModule(
      name: 'Analytics',
      icon: Iconsax.chart_21,
      color: Color(0xFFEE5A24),
      module: 'analytics',
    ),
  ];

  /// Compute permissions BEFORE save (current state)
  Set<String> _computeCurrentPermissions() {
    final perms = <String>{};
    for (final role in initialUserRoles) {
      perms.addAll(role.permissions);
    }
    return perms;
  }

  /// Compute permissions AFTER save (preview)
  Set<String> _computePreviewPermissions() {
    final perms = <String>{};

    // Start with current roles minus removed ones
    for (final role in initialUserRoles) {
      if (!rolesToRemove.contains(role.id)) {
        perms.addAll(role.permissions);
      }
    }

    // Add permissions from roles being added
    for (final roleId in rolesToAdd) {
      final role = allRoles.where((r) => r.id == roleId).firstOrNull;
      if (role != null) {
        perms.addAll(role.permissions);
      }
    }

    return perms;
  }

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Permissions',
      icon: Iconsax.shield_security,
      child: Column(
        children: [
          _buildAdminSwitch(),
          const SizedBox(height: 16),
          if (isSuperAdmin)
            const AdminInfoBox(
              message: 'Super Admin has full access and does not need roles.',
              icon: Iconsax.crown,
              color: Colors.red,
            )
          else if (isAdmin && canAssignRoles) ...[
            _buildRoleManagementSection(context),
            const SizedBox(height: 20),
            _buildPermissionPreview(),
          ] else if (isAdmin && !canAssignRoles)
            const AdminInfoBox(
              message: 'You do not have permission to assign roles.',
              icon: Iconsax.lock_1,
              color: Colors.orange,
            )
          else
            AdminInfoBox(
              message: canToggleAdmin
                  ? 'Enable admin access to assign roles.'
                  : 'This user is not an admin.',
              icon: Iconsax.info_circle,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildAdminSwitch() {
    final bool switchValue = isSuperAdmin ? true : isAdmin;
    final bool canChange = canToggleAdmin && !isSuperAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: switchValue
                ? const LinearGradient(
                    colors: [Color(0x1A7C3AED), Color(0x0D7C3AED)],
                  )
                : null,
            color: switchValue ? null : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: switchValue
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: switchValue
                      ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  switchValue ? Iconsax.shield_tick : Iconsax.shield,
                  color: switchValue ? const Color(0xFF7C3AED) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Access',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: switchValue
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      switchValue
                          ? 'Full access to admin dashboard'
                          : 'Standard user permissions',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: switchValue,
                onChanged: canChange
                    ? (value) {
                        HapticFeedback.lightImpact();
                        onAdminToggle(value);
                      }
                    : null,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF7C3AED),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ],
          ),
        ),
        if (!canToggleAdmin) ...[
          const SizedBox(height: 8),
          Text(
            'Only Super Admin can change admin access.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
        if (isSuperAdmin) ...[
          const SizedBox(height: 8),
          Text(
            'Super Admin always has admin access.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // ROLE MANAGEMENT
  // ==========================================

  Widget _buildRoleManagementSection(BuildContext context) {
    return BlocBuilder<AdminRoleBloc, AdminRoleState>(
      builder: (context, state) {
        if (state is RolesLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is RolesLoaded) {
          if (state.roles.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Iconsax.document_text, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'No roles available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Deduplicate roles by name
          final uniqueRoles = <String, RoleEntity>{};
          for (final role in state.roles) {
            uniqueRoles.putIfAbsent(role.name, () => role);
          }
          final deduplicatedRoles = uniqueRoles.values.toList();

          return FutureBuilder<List<RoleEntity>>(
            future: userRolesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final currentUserRoles = snapshot.data ?? initialUserRoles;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Assign Roles',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  ...deduplicatedRoles.map((role) {
                    final roleHasRole = hasRole(role.id, currentUserRoles);

                    return AdminRoleSwitch(
                      role: role,
                      hasRole: roleHasRole,
                      canChange: canAssignRoles && !isSuperAdmin,
                      onChanged: (value) => onToggleRole(role.id, value),
                    );
                  }).toList(),
                ],
              );
            },
          );
        }

        if (state is AdminRoleError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'Error loading roles: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<AdminRoleBloc>().add(
                      const FetchAllRolesEvent(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is AdminRoleInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminRoleBloc>().add(const FetchAllRolesEvent());
          });

          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ==========================================
  // ✅ LIVE PERMISSION PREVIEW
  // ==========================================

  Widget _buildPermissionPreview() {
    final currentPerms = _computeCurrentPermissions();
    final previewPerms = _computePreviewPermissions();

    final hasChanges = rolesToAdd.isNotEmpty || rolesToRemove.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: hasChanges
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2ED573).withValues(alpha: 0.05),
                  const Color(0xFF1ABC9C).withValues(alpha: 0.03),
                ],
              )
            : null,
        color: hasChanges ? null : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasChanges
              ? const Color(0xFF2ED573).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
          width: hasChanges ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.eye,
                  color: Color(0xFF2ED573),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permission Preview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'What this user will have after saving',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              if (hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.edit_2,
                        color: Color(0xFF2ED573),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Unsaved',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2ED573),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Permission modules
          ..._permissionModules.map((module) {
            return _buildPreviewModuleTile(
              module,
              currentPerms,
              previewPerms,
              hasChanges,
            );
          }),

          // Summary
          if (hasChanges) ...[
            const SizedBox(height: 12),
            _buildChangeSummary(currentPerms, previewPerms),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewModuleTile(
    _PermissionModule module,
    Set<String> currentPerms,
    Set<String> previewPerms,
    bool hasChanges,
  ) {
    final currentHasView = currentPerms.contains('${module.module}:view');
    final currentHasCreate = currentPerms.contains('${module.module}:create');
    final currentHasUpdate = currentPerms.contains('${module.module}:update');
    final currentHasDelete = currentPerms.contains('${module.module}:delete');
    final currentHasManage = currentPerms.contains('${module.module}:manage');

    final previewHasView = previewPerms.contains('${module.module}:view');
    final previewHasCreate = previewPerms.contains('${module.module}:create');
    final previewHasUpdate = previewPerms.contains('${module.module}:update');
    final previewHasDelete = previewPerms.contains('${module.module}:delete');
    final previewHasManage = previewPerms.contains('${module.module}:manage');

    final currentHasAny =
        currentHasView ||
        currentHasCreate ||
        currentHasUpdate ||
        currentHasDelete ||
        currentHasManage;

    final previewHasAny =
        previewHasView ||
        previewHasCreate ||
        previewHasUpdate ||
        previewHasDelete ||
        previewHasManage;

    // Determine change type
    final bool isGaining = !currentHasAny && previewHasAny;
    final bool isLosing = currentHasAny && !previewHasAny;
    final bool isChanging =
        currentHasAny &&
        previewHasAny &&
        (currentHasCreate != previewHasCreate ||
            currentHasUpdate != previewHasUpdate ||
            currentHasDelete != previewHasDelete);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isGaining
            ? const Color(0xFF2ED573).withValues(alpha: 0.08)
            : isLosing
            ? Colors.red.withValues(alpha: 0.06)
            : previewHasAny
            ? module.color.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGaining
              ? const Color(0xFF2ED573).withValues(alpha: 0.4)
              : isLosing
              ? Colors.red.withValues(alpha: 0.3)
              : previewHasAny
              ? module.color.withValues(alpha: 0.2)
              : Colors.grey[200]!,
          width: (isGaining || isLosing) ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Module icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: previewHasAny
                  ? module.color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              module.icon,
              color: previewHasAny ? module.color : Colors.grey[400],
              size: 16,
            ),
          ),
          const SizedBox(width: 10),

          // Module name + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      module.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: previewHasAny
                            ? const Color(0xFF1F2937)
                            : Colors.grey[500],
                      ),
                    ),
                    if (isGaining) ...[
                      const SizedBox(width: 6),
                      _buildChangeBadge('NEW', const Color(0xFF2ED573)),
                    ],
                    if (isLosing) ...[
                      const SizedBox(width: 6),
                      _buildChangeBadge('REMOVED', Colors.red),
                    ],
                    if (isChanging) ...[
                      const SizedBox(width: 6),
                      _buildChangeBadge('CHANGED', Colors.orange),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                // Permission badges (preview state)
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: [
                    if (previewHasManage)
                      _buildPermBadge('Manage', module.color, false)
                    else ...[
                      if (previewHasView)
                        _buildPermBadge(
                          'View',
                          module.color,
                          !currentHasView && hasChanges,
                        ),
                      if (previewHasCreate)
                        _buildPermBadge(
                          'Create',
                          module.color,
                          !currentHasCreate && hasChanges,
                        ),
                      if (previewHasUpdate)
                        _buildPermBadge(
                          'Update',
                          module.color,
                          !currentHasUpdate && hasChanges,
                        ),
                      if (previewHasDelete)
                        _buildPermBadge(
                          'Delete',
                          module.color,
                          !currentHasDelete && hasChanges,
                        ),
                    ],
                    if (!previewHasAny)
                      Text(
                        'No access',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Status icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              previewHasAny
                  ? (isGaining ? Iconsax.add_circle : Iconsax.tick_circle)
                  : (isLosing ? Iconsax.minus_cirlce : Iconsax.close_circle),
              key: ValueKey('$previewHasAny-$isGaining-$isLosing'),
              color: previewHasAny
                  ? (isGaining ? const Color(0xFF2ED573) : module.color)
                  : (isLosing ? Colors.red : Colors.grey[300]),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermBadge(String label, Color color, bool isNew) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isNew
            ? const Color(0xFF2ED573).withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: isNew
            ? Border.all(
                color: const Color(0xFF2ED573).withValues(alpha: 0.4),
                width: 0.5,
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: isNew ? const Color(0xFF2ED573) : color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildChangeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildChangeSummary(
    Set<String> currentPerms,
    Set<String> previewPerms,
  ) {
    final gained = previewPerms.difference(currentPerms);
    final lost = currentPerms.difference(previewPerms);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2ED573).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.info_circle,
                color: Color(0xFF2ED573),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Changes Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (gained.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Iconsax.add_circle,
                  color: Color(0xFF2ED573),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '+${gained.length} permission${gained.length > 1 ? 's' : ''} will be added',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2ED573),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          if (lost.isNotEmpty) ...[
            if (gained.isNotEmpty) const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Iconsax.minus_cirlce, color: Colors.red, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '-${lost.length} permission${lost.length > 1 ? 's' : ''} will be removed',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (gained.isEmpty && lost.isEmpty)
            const Text(
              'No permission changes',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }
}
