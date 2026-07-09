// lib/features/chat/presentation/widgets/admin_chat_bottom_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/chat/domain/entities/chat_user.dart';
import 'package:mobile/features/chat/domain/usecases/get_admin_users.dart';
import 'package:mobile/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:mobile/features/chat/presentation/screens/conversations_screen.dart';

class AdminChatBottomSheet extends StatefulWidget {
  const AdminChatBottomSheet({super.key});

  @override
  State<AdminChatBottomSheet> createState() => _AdminChatBottomSheetState();
}

class _AdminChatBottomSheetState extends State<AdminChatBottomSheet> {
  List<ChatUser> _admins = [];
  bool _isLoading = true;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
    _setupStatusListener();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  /// ✅ Listen for real-time status changes from WebSocket
  void _setupStatusListener() {
    final socketService = sl<ChatSocketService>();
    _statusSub = socketService.onStatusChange.listen((data) {
      if (!mounted) return;

      final userId = data['userId'] as String?;
      final isOnline = data['isOnline'] as bool? ?? false;

      if (userId == null) return;

      // Update the admin's online status in the list
      setState(() {
        for (int i = 0; i < _admins.length; i++) {
          if (_admins[i].id == userId) {
            _admins[i] = ChatUser(
              id: _admins[i].id,
              name: _admins[i].name,
              phoneNumber: _admins[i].phoneNumber,
              profileImage: _admins[i].profileImage,
              isOnline: isOnline,
              lastSeen: _admins[i].lastSeen,
              isAdmin: _admins[i].isAdmin,
              isSuperAdmin: _admins[i].isSuperAdmin,
            );
            break;
          }
        }
      });
    });
  }

  Future<void> _loadAdmins() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await sl<GetAdminUsers>()();
      result.fold(
        (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        (admins) {
          if (mounted) {
            setState(() {
              _admins = admins;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Text(
            'Chat with Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select an admin to chat with',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          // Admins List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ED573)),
                  )
                : _admins.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.user, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No admins available',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _admins.length,
                    itemBuilder: (context, index) {
                      final admin = _admins[index];
                      return _buildAdminTile(admin);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(ChatUser admin) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2ED573).withOpacity(0.1),
            backgroundImage:
                admin.profileImage != null &&
                    admin.profileImage!.isNotEmpty &&
                    !admin.profileImage!.contains('example.com')
                ? CachedNetworkImageProvider(admin.profileImage!)
                : null,
            child:
                admin.profileImage == null ||
                    admin.profileImage!.isEmpty ||
                    admin.profileImage!.contains('example.com')
                ? Text(
                    (admin.name?.isNotEmpty == true
                            ? admin.name![0]
                            : admin.phoneNumber.substring(0, 1))
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2ED573),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          // ✅ Online/Offline indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: admin.isOnline
                    ? const Color(0xFF2ED573)
                    : Colors.grey[400],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              admin.name ?? admin.phoneNumber,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          if (admin.isSuperAdmin == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Super',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (admin.isAdmin == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        admin.isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          fontSize: 12,
          color: admin.isOnline ? const Color(0xFF2ED573) : Colors.grey[500],
        ),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 18),
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        // Navigate to chat room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              partnerId: admin.id,
              partnerName: admin.name ?? admin.phoneNumber,
              partnerImage: admin.profileImage,
              isOnline: admin.isOnline, // ✅ Pass current online status
            ),
          ),
        ).then((_) {
          // When user presses back from ChatRoom, navigate to ConversationsScreen
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ConversationsScreen()),
            );
          }
        });
      },
    );
  }
}
