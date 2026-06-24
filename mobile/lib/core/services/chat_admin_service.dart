import 'package:flutter/material.dart';
import 'package:mobile/features/chat/presentation/screens/chat_room_screen.dart';
import 'admin_service.dart';

class ChatAdminService {
  static Future<void> startChatWithAdmin(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2ED573)),
        ),
      );

      // Fetch admin user
      final admin = await AdminService.getFirstAdmin();

      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (admin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No support admin available. Please try again later.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Navigate to chat room
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
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to check if admin is available
  static Future<bool> isAdminAvailable() async {
    try {
      final admin = await AdminService.getFirstAdmin();
      return admin != null;
    } catch (e) {
      return false;
    }
  }
}
