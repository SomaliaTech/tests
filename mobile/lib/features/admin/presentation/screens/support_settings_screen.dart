import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/utils/toast_helper.dart';
import 'package:mobile/features/support/presentation/bloc/support_settings/support_settings_bloc.dart';
import 'package:mobile/features/support/presentation/bloc/support_settings/support_settings_event.dart';
import 'package:mobile/features/support/presentation/bloc/support_settings/support_settings_state.dart';

class SupportSettingsScreen extends StatefulWidget {
  const SupportSettingsScreen({super.key});

  @override
  State<SupportSettingsScreen> createState() => _SupportSettingsScreenState();
}

class _SupportSettingsScreenState extends State<SupportSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _hasChanges = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupportSettingsBloc>().add(
          const LoadSupportSettingsEvent(),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    context.read<SupportSettingsBloc>().add(
      SaveSupportSettingsEvent(
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: _buildAppBar(),
      body: BlocConsumer<SupportSettingsBloc, SupportSettingsState>(
        listenWhen: (prev, curr) =>
            curr is SupportSettingsLoaded ||
            curr is SupportSettingsSaved ||
            curr is SupportSettingsError,
        listener: (context, state) {
          if (state is SupportSettingsLoaded) {
            if (!_hydrated) {
              _emailController.text = state.contact.email;
              _phoneController.text = state.contact.phoneNumber;
              _hydrated = true;
            }
          } else if (state is SupportSettingsSaved) {
            _emailController.text = state.contact.email;
            _phoneController.text = state.contact.phoneNumber;
            setState(() => _hasChanges = false);
            ToastHelper.showSuccess(context, state.message);
          } else if (state is SupportSettingsError) {
            ToastHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          // Skeleton on first load
          if (state is SupportSettingsLoading && !_hydrated) {
            return _buildSkeleton();
          }
          if (state is SupportSettingsError && !_hydrated) {
            return _buildErrorState(state.message);
          }

          final isSaving = state is SupportSettingsSaving;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSectionLabel('Contact Information'),
                const SizedBox(height: 10),
                _buildField(
                  controller: _emailController,
                  label: 'Support Email',
                  hint: 'support@farxada.com',
                  icon: Iconsax.sms,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Email is required';
                    final emailRegex = RegExp(
                      r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(val)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  onChanged: (_) => _markChanged(),
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneController,
                  label: 'Support Phone Number',
                  hint: '+252615328651',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
                  ],
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Phone number is required';
                    final digits = val.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 4) {
                      return 'Phone number must have at least 4 digits';
                    }
                    return null;
                  },
                  onChanged: (_) => _markChanged(),
                ),
                const SizedBox(height: 24),
                _buildInfoBanner(),
                const SizedBox(height: 32),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: (_hasChanges && !isSaving) ? _save : null,
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Iconsax.tick_circle, size: 18),
                    label: Text(
                      isSaving
                          ? 'Saving…'
                          : _hasChanges
                          ? 'Save Changes'
                          : 'No Changes',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF111827,
                      ).withValues(alpha: 0.35),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _iconBtn(
                    icon: Iconsax.arrow_left_2,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Support Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (_hasChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            size: 12,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Unsaved',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
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
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, color: const Color(0xFF111827), size: 18),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ED573).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.headphone, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These details are shown to users on the support screen.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.black.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: const Color(0xFF2ED573),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  icon,
                  color: const Color(0xFF2ED573),
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: validator,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2ED573).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2ED573).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, color: Color(0xFF16A085), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Users will see these contact details in the Support screen. '
              'Changes take effect immediately.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skel(120, 20),
        const SizedBox(height: 20),
        _skel(40, 10),
        const SizedBox(height: 10),
        _skel(90, 18),
        const SizedBox(height: 16),
        _skel(90, 18),
        const SizedBox(height: 32),
        _skel(54, 16),
      ],
    );
  }

  Widget _skel(double h, double r) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 0.9),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        height: h,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: v * 0.05),
          borderRadius: BorderRadius.circular(r),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 32,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<SupportSettingsBloc>().add(
                const LoadSupportSettingsEvent(),
              ),
              icon: const Icon(Iconsax.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
