import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_event.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_state.dart';
import 'package:toastification/toastification.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
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

      final userData = {
        'phoneNumber': _phoneController.text.trim(),
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      };

      context.read<UserBloc>().add(CreateUserEvent(userData));
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
          'Add User',
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
            // Pop screen passing true to trigger parent update list logic safely
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
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+252612345678',
                  icon: Iconsax.call,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Jamac Farah',
                  icon: Iconsax.user,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'jamac@example.com',
                  icon: Iconsax.message,
                  keyboardType: TextInputType.emailAddress,
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
    String? Function(String?)? validator,
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
            validator: validator,
          ),
        ),
      ],
    );
  }
}
