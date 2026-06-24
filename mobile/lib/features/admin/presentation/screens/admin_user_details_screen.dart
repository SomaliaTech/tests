import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_event.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_state.dart';
import 'package:mobile/features/admin/presentation/screens/edit_user_screen.dart';
import 'package:toastification/toastification.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final AdminUserEntity user;

  const AdminUserDetailsScreen({super.key, required this.user});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
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
          'User Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditUserScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserOperationSuccess) {
            _showToast(state.message, true);
          } else if (state is UserError) {
            _showToast(state.message, false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                      child: Text(
                        widget.user.name?.isNotEmpty == true
                            ? widget.user.name![0].toUpperCase()
                            : widget.user.phoneNumber.substring(0, 2),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.user.name ?? 'No Name',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.email ?? widget.user.phoneNumber,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge(
                          label: widget.user.isVerified
                              ? 'Verified'
                              : 'Not Verified',
                          color: widget.user.isVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        if (widget.user.isAdmin)
                          _buildBadge(label: 'Admin', color: Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // User Information
              _buildSection('Information', [
                _buildInfoRow(Iconsax.call, 'Phone', widget.user.phoneNumber),
                if (widget.user.email != null)
                  _buildInfoRow(Iconsax.message, 'Email', widget.user.email!),
                if (widget.user.marketId != null)
                  _buildInfoRow(
                    Iconsax.shop,
                    'Market ID',
                    widget.user.marketId!,
                  ),
                _buildInfoRow(
                  Iconsax.calendar,
                  'Joined',
                  _formatDate(widget.user.createdAt),
                ),
              ]),
              const SizedBox(height: 24),
              // Actions
              _buildSection('Actions', [
                _buildActionButton(
                  icon: Iconsax.edit,
                  label: 'Edit User',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditUserScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Iconsax.trash,
                  label: 'Delete User',
                  color: Colors.red,
                  onTap: () => _showDeleteConfirmation(),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete User', style: TextStyle(color: Colors.black87)),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserBloc>().add(DeleteUserEvent(widget.user.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}