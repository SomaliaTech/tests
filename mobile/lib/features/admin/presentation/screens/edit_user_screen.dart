import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_event.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_state.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _isAdmin = widget.user.isAdmin;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
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

  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final updateData = {
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'isAdmin': _isAdmin,
      };

      context.read<UserBloc>().add(UpdateUserEvent(widget.user.id, updateData));
    }
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
          'Edit User',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveUser,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserOperationSuccess) {
            setState(() {
              _isLoading = false;
            });
            _showToast(state.message, true);
            // Pass back true indicator status cleanly
            Navigator.pop(context, true);
          } else if (state is UserError) {
            setState(() {
              _isLoading = false;
            });
            _showToast(state.message, false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Farah Jamac',
                  icon: Iconsax.user,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'farah@example.com',
                  icon: Iconsax.message,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildSwitchTile(
                  icon: Iconsax.shield_tick,
                  label: 'Admin Access',
                  value: _isAdmin,
                  onChanged: (value) {
                    setState(() {
                      _isAdmin = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.user.phoneNumber,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
