import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/chat_admin_service.dart';

class ChatWithAdminButton extends StatelessWidget {
  const ChatWithAdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ChatAdminService.startChatWithAdmin(context),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2ED573).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2ED573).withOpacity(0.3)),
        ),
        child: const Icon(Iconsax.message, color: Color(0xFF2ED573), size: 24),
      ),
    );
  }
}
