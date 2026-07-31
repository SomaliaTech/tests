// lib/features/admin/presentation/screens/edit_user/edit_user_personal_info.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/edit_user/admin_text_field.dart';

class EditUserPersonalInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;

  const EditUserPersonalInfo({
    super.key,
    required this.nameController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Personal Information',
      icon: Iconsax.user_edit,
      child: Column(
        children: [
          AdminTextField(
            controller: nameController,
            label: 'Full Name',
            hint: 'Farah Jamac',
            icon: Iconsax.user,
          ),
          const SizedBox(height: 16),
          AdminTextField(
            controller: emailController,
            label: 'Email Address',
            hint: 'farah@example.com',
            icon: Iconsax.message,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }
}
