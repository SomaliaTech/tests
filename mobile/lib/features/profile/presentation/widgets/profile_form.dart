import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/market.dart';

class ProfileForm extends StatefulWidget {
  final Profile profile;
  final Market? selectedMarket;
  final Function(String) onNameChanged;

  final VoidCallback onMarketTap;
  final VoidCallback onUpdatePressed;
  final bool isUpdating;

  const ProfileForm({
    super.key,
    required this.profile,
    required this.selectedMarket,
    required this.onNameChanged,

    required this.onMarketTap,
    required this.onUpdatePressed,
    required this.isUpdating,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // ✅ Fixed
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.user_edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Update your personal details',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 24),

          // Full Name Field
          _buildEditableField(
            controller: _nameController,
            label: 'Full Name',
            icon: Iconsax.user,
            iconColor: const Color(0xFF3B82F6),
            onChanged: widget.onNameChanged,
            hint: 'Enter your full name',
          ),
          const SizedBox(height: 20),

          // Phone Number (Read-only)
          _buildReadOnlyField(
            label: 'Phone Number',
            value: widget.profile.phoneNumber,
            icon: Iconsax.call,
            iconColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 20),

          // Market Selector
          GestureDetector(
            onTap: widget.onMarketTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Market',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.1), // ✅ Fixed
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Iconsax.building,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.selectedMarket?.name ??
                              'Select your market', // ✅ Fixed
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.selectedMarket != null
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2ED573,
                          ).withValues(alpha: 0.1), // ✅ Fixed
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.arrow_down_1,
                          color: Color(0xFF2ED573),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Update Button with gradient
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: widget.isUpdating ? null : widget.onUpdatePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: const Color(
                  0xFF2ED573,
                ).withValues(alpha: 0.4), // ✅ Fixed
                elevation: 8,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: widget.isUpdating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.tick_circle, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Update Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1), // ✅ Fixed
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1), // ✅ Fixed
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.lock_1, size: 12, color: Color(0xFF6B7280)),
                    SizedBox(width: 4),
                    Text(
                      'Read-only',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
