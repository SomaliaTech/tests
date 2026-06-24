import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/admin_service.dart';
import 'package:mobile/features/chat/presentation/screens/chat_room_screen.dart';

class ChatWithAdminButton extends StatelessWidget {
  const ChatWithAdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2ED573)),
          ),
        );

        try {
          // Fetch admin info
          final admin = await AdminService.getFirstAdmin();

          // Close loading dialog
          Navigator.pop(context);

          if (admin != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  partnerId: admin.id,
                  partnerName: admin.displayName,
                  partnerImage: admin.profileImage,
                ),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No support admin available at the moment'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          Navigator.pop(context);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
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
