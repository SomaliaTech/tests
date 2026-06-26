import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/chat/presentation/screens/chat_room_screen.dart';
import 'admin_service.dart';

class ChatAdminService {
  // ✅ Start chat with admin - handles everything
  static Future<void> startChatWithAdmin(BuildContext context) async {
    // Show loading indicator
    if (!context.mounted) return;
    final socketService = GetIt.instance<ChatSocketService>();
    if (!socketService.isConnected) {
      await socketService.connect();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2ED573)),
      ),
    );

    try {
      // Fetch admin user
      final admin = await AdminService.getFirstAdmin();

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Check if context is still valid
      if (!context.mounted) return;

      if (admin == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No support admin available. Please try again later.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Navigate to chat room
      if (context.mounted) {
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
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ Check if admin is available
  static Future<bool> isAdminAvailable() async {
    try {
      final admin = await AdminService.getFirstAdmin();
      return admin != null;
    } catch (e) {
      return false;
    }
  }

  // ✅ Get first available admin
  static Future<AdminUser?> getFirstAdmin() async {
    try {
      return await AdminService.getFirstAdmin();
    } catch (e) {
      return null;
    }
  }
}
