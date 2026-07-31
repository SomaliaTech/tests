// lib/features/admin/presentation/widgets/admin_role_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_event.dart';

class AdminRoleDialog extends StatefulWidget {
  const AdminRoleDialog({super.key});

  @override
  State<AdminRoleDialog> createState() => _AdminRoleDialogState();
}

class _AdminRoleDialogState extends State<AdminRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedPermissions = [];

  final Map<String, List<String>> _permissionCategories = {
    'Products': [
      'product:create',
      'product:update',
      'product:delete',
      'product:view',
      'product:manage',
    ],
    'Orders': ['order:view', 'order:update', 'order:delete', 'order:manage'],
    'Users': [
      'user:view',
      'user:create',
      'user:update',
      'user:delete',
      'user:manage',
    ],
    'Categories': [
      'category:create',
      'category:update',
      'category:delete',
      'category:view',
      'category:manage',
    ],
    'Markets': [
      'market:create',
      'market:update',
      'market:delete',
      'market:view',
      'market:manage',
    ],
    'Content': [
      'faq:create',
      'faq:update',
      'faq:delete',
      'faq:view',
      'banner:create',
      'banner:update',
      'banner:delete',
      'banner:view',
    ],
    'Revenue': ['revenue:view', 'revenue:export', 'revenue:manage'],
    'Analytics': ['analytics:view', 'analytics:export', 'analytics:manage'],
    'Admin': [
      'admin:manage',
      'admin:create',
      'admin:delete',
      'admin:update',
      'admin:view',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Role'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Role Name',
                  prefixIcon: Icon(Iconsax.tag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Role name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Iconsax.document_text),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'Permissions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._permissionCategories.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    children: entry.value.map((permission) {
                      final isSelected = _selectedPermissions.contains(
                        permission,
                      );
                      return CheckboxListTile(
                        title: Text(
                          permission,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedPermissions.add(permission);
                            } else {
                              _selectedPermissions.remove(permission);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final roleData = {
                'name': _nameController.text,
                'description': _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : null,
                'permissions': _selectedPermissions,
              };

              context.read<AdminRoleBloc>().add(CreateRoleEvent(roleData));
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
