// lib/features/admin/presentation/screens/admin_user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_event.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_state.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_state.dart';
import 'package:mobile/features/admin/presentation/screens/admin_user_details_screen.dart';
import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_role_dialog.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:toastification/toastification.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSuperAdmin = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _checkSuperAdmin();
    _loadData();
  }

  Future<void> _checkSuperAdmin() async {
    final storageService = sl<StorageService>();
    final isSuperAdmin = await storageService.getIsSuperAdmin();
    final userId = await storageService.getUserId();
    if (mounted) {
      setState(() {
        _isSuperAdmin = isSuperAdmin;
        _currentUserId = userId ?? '';
      });
    }
  }

  void _loadData() {
    context.read<UserBloc>().add(const FetchAllUsersEvent());
    if (_isSuperAdmin) {
      context.read<AdminRoleBloc>().add(FetchAllRolesEvent());
    }
  }

  void _showToast(String message, bool isSuccess) {
    toastification.show(
      title: Text(message),
      type: isSuccess ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      foregroundColor: Colors.white,
      icon: Icon(
        isSuccess ? Iconsax.tick_circle : Iconsax.warning_2,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSuperAdmin)
            IconButton(
              icon: const Icon(Iconsax.add, color: AppTheme.primaryColor),
              onPressed: () => _showCreateUserDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: BlocListener<UserBloc, UserState>(
              listener: (context, state) {
                if (state is UserOperationSuccess) {
                  _showToast(state.message, true);
                  context.read<UserBloc>().add(const FetchAllUsersEvent());
                } else if (state is UserError) {
                  _showToast(state.message, false);
                }
              },
              child: BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  if (state is UsersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return _buildEmptyState();
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<UserBloc>().add(
                          const FetchAllUsersEvent(),
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.users.length,
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          final isCurrentUser = user.id == _currentUserId;
                          return _buildUserCard(user, isCurrentUser);
                        },
                      ),
                    );
                  }

                  if (state is UserError) {
                    return _buildErrorState(state.message);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          if (_isSuperAdmin) _buildRoleSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or phone...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (value) {
                context.read<UserBloc>().add(FetchAllUsersEvent(search: value));
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              context.read<UserBloc>().add(
                FetchAllUsersEvent(search: _searchController.text),
              );
            },
            icon: const Icon(
              Iconsax.search_normal,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUserEntity user, bool isCurrentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminUserDetailsScreen(user: user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  user.name?.isNotEmpty == true
                      ? user.name![0].toUpperCase()
                      : user.phoneNumber.substring(0, 2),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phoneNumber,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (user.isVerified)
                          _buildBadge('Verified', Colors.green),
                        if (user.isAdmin) _buildBadge('Admin', Colors.purple),
                        if (user.isSuperAdmin ?? false)
                          _buildBadge('Super Admin', Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.user, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Users Found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or create a new user',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<UserBloc>().add(const FetchAllUsersEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection() {
    return BlocBuilder<AdminRoleBloc, AdminRoleState>(
      builder: (context, state) {
        if (state is RolesLoaded) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Role Management',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AdminRoleDialog(),
                        );
                      },
                      icon: const Icon(Iconsax.add, size: 18),
                      label: const Text('New Role'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.roles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final role = state.roles[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: role.isSystem
                              ? Colors.grey[100]
                              : AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: role.isSystem
                                ? Colors.grey[300]!
                                : AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              role.name,
                              style: TextStyle(
                                color: role.isSystem
                                    ? Colors.grey[600]
                                    : AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (role.userCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: role.isSystem
                                      ? Colors.grey[400]
                                      : AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    role.userCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedRoleId;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Iconsax.call),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Iconsax.message),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                BlocBuilder<AdminRoleBloc, AdminRoleState>(
                  builder: (context, state) {
                    if (state is RolesLoaded) {
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Iconsax.shield_tick),
                        ),
                        value: selectedRoleId,
                        items: state.roles.map((role) {
                          return DropdownMenuItem(
                            value: role.id,
                            child: Text(role.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedRoleId = value;
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final userData = {
                  'phoneNumber': phoneController.text,
                  'name': nameController.text.isNotEmpty
                      ? nameController.text
                      : null,
                  'email': emailController.text.isNotEmpty
                      ? emailController.text
                      : null,
                };

                context.read<UserBloc>().add(CreateUserEvent(userData));
                Navigator.pop(dialogContext);

                // If role is selected, assign it after user creation
                if (selectedRoleId != null) {
                  // TODO: Implement role assignment after user creation
                  // This requires the backend endpoint to assign role to user
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
