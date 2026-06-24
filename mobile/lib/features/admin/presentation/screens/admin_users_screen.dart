import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_event.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_state.dart';
import 'package:mobile/features/admin/presentation/screens/admin_user_details_screen.dart';
import 'package:mobile/features/admin/presentation/screens/add_user_screen.dart';
import 'package:toastification/toastification.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(const FetchAllUsersEvent());
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<UserBloc>().add(FetchAllUsersEvent(search: query));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(
              Iconsax.arrow_left,
              color: Color(0xFF2ED573),
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'Users',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddUserScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserOperationSuccess) {
            toastification.show(
              title: Text(state.message),
              type: ToastificationType.success,
              style: ToastificationStyle.flat,
              autoCloseDuration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Iconsax.tick_circle, color: Colors.white),
            );
          } else if (state is UserError) {
            toastification.show(
              title: Text(state.message),
              type: ToastificationType.error,
              style: ToastificationStyle.flat,
              autoCloseDuration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: const Icon(Iconsax.warning_2, color: Colors.white),
            );
          }
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Iconsax.close_circle,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Users List
            Expanded(
              child: BlocBuilder<UserBloc, UserState>(
                buildWhen: (prev, current) =>
                    current is UsersLoading ||
                    current is UsersLoaded ||
                    current is UserError,
                builder: (context, state) {
                  if (state is UsersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  if (state is UsersLoaded) {
                    final users = state.users;
                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.user,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No users found'
                                  : 'No users yet',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(context, user);
                      },
                    );
                  }
                  return const Center(
                    child: Text(
                      'Failed to load users',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AdminUserEntity user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminUserDetailsScreen(user: user)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              child: Text(
                user.name?.isNotEmpty == true
                    ? user.name![0].toUpperCase()
                    : user.phoneNumber.substring(0, 2),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'No Name',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? user.phoneNumber,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Time
            Text(
              _getRelativeTime(user.createdAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
