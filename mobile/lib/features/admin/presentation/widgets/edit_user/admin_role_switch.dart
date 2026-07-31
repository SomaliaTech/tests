// lib/features/admin/presentation/widgets/edit_user/admin_role_switch.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/permission_entity.dart';

class AdminRoleSwitch extends StatelessWidget {
  final RoleEntity role;
  final bool hasRole;
  final bool canChange;
  final ValueChanged<bool> onChanged;

  const AdminRoleSwitch({
    super.key,
    required this.role,
    required this.hasRole,
    required this.canChange,
    required this.onChanged,
  });

  bool get _isProtected => role.name.toLowerCase() == 'super admin';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasRole
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasRole ? AppTheme.primaryColor : Colors.grey[200]!,
          width: hasRole ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasRole
                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasRole ? Iconsax.tick_circle : Iconsax.shield,
              color: hasRole ? AppTheme.primaryColor : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      role.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasRole ? AppTheme.primaryColor : Colors.black87,
                      ),
                    ),
                    if (hasRole) _buildBadge('Assigned', AppTheme.primaryColor),
                    if (role.isSystem) _buildBadge('System', Colors.grey[600]!),
                    if (_isProtected)
                      _buildBadge('Protected', Colors.red[700]!),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${role.permissions.length} permissions',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasRole
                        ? AppTheme.primaryColor.withValues(alpha: 0.7)
                        : Colors.grey[500],
                  ),
                ),
                if (role.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canChange && !_isProtected)
            Switch(
              value: hasRole,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                onChanged(value);
              },
              activeColor: Colors.white,
              activeTrackColor: AppTheme.primaryColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            )
          else
            const Icon(Iconsax.lock_1, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
