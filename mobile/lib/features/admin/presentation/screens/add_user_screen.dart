import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _phoneFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  /// ✅ Validate Somali phone number
  /// Must be 9 digits and start with 61 (e.g., 61XXXXXXX)
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) {
      return 'Phone number must be exactly 9 digits';
    }
    if (!digits.startsWith('61')) {
      return 'Phone number must start with 61';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
      return 'Phone number must contain only digits';
    }
    return null;
  }

  /// ✅ Auto-prepend +252 to the phone number before saving
  String _getFullPhoneNumber() {
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    return '+252$digits';
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void _showToast(String message, bool isSuccess) {
    toastification.show(
      context: context,
      title: Text(isSuccess ? 'Success' : 'Error'),
      description: Text(message),
      type: isSuccess ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _saveUser() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final fullPhone = _getFullPhoneNumber();

    final userData = {
      'phoneNumber': fullPhone,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    };

    context.read<UserBloc>().add(CreateUserEvent(userData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserOperationSuccess) {
            setState(() => _isLoading = false);
            _showToast(state.message, true);
            Navigator.pop(context, true);
          } else if (state is UserError) {
            setState(() => _isLoading = false);
            HapticFeedback.heavyImpact();
            _showToast(state.message, false);
          }
        },
        child: CustomScrollView(
          slivers: [
            // ✅ Modern Gradient Header
            _buildHeader(),

            // ✅ Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // ✅ User Info Card
                      _buildSectionTitle(
                        icon: Iconsax.user,
                        title: 'User Information',
                        subtitle: 'Enter the new user details below',
                      ),
                      const SizedBox(height: 16),

                      // ✅ Phone Input with Auto +252
                      _buildPhoneInput(),
                      const SizedBox(height: 20),

                      // ✅ Name Input
                      _buildModernTextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        label: 'Full Name',
                        hint: 'Jamac Farah',
                        icon: Iconsax.user,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: _validateName,
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(_emailFocusNode),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Email Input
                      _buildModernTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Email (Optional)',
                        hint: 'jamac@example.com',
                        icon: Iconsax.message,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: _validateEmail,
                        onFieldSubmitted: (_) => _saveUser(),
                      ),
                      const SizedBox(height: 32),

                      // ✅ Info Card
                      _buildInfoCard(),
                      const SizedBox(height: 24),

                      // ✅ Save Button
                      _buildSaveButton(),
                      const SizedBox(height: 40),
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

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Iconsax.arrow_left_2,
              color: Color(0xFF1F2937),
              size: 22,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Add New User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2ED573), Color(0xFF1ABC9C), Color(0xFF16A085)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Iconsax.user_add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2ED573).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2ED573), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ Unified Phone Input with auto +252 prefix
  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Country code section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4189DD),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(
                        child: Text('🇸🇴', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+252',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2ED573),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
              const SizedBox(width: 12),
              // Phone input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 9,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '61 XXX XXXX',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  validator: _validatePhone,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_nameFocusNode),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter 9 digits starting with 61 (country code +252 will be added automatically)',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                width: 48,
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF2ED573), size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 16,
              ),
            ),
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2ED573).withValues(alpha: 0.08),
            const Color(0xFF1ABC9C).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2ED573).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A2ED573),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Iconsax.shield_tick,
              color: Color(0xFF2ED573),
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Validation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Somali numbers start with 61 and have 9 digits total',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF2ED573).withValues(alpha: 0.4),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.user_add, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
