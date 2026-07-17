import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';

class SuperAdminChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String userName;
  final String adminName;
  final String userId;
  final String adminId;

  const SuperAdminChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.userName,
    required this.adminName,
    required this.userId,
    required this.adminId,
  });

  @override
  State<SuperAdminChatDetailScreen> createState() =>
      _SuperAdminChatDetailScreenState();
}

class _SuperAdminChatDetailScreenState
    extends State<SuperAdminChatDetailScreen> {
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final dataSource = sl<ChatRemoteDataSource>();
      final messages = await dataSource.getConversationMessages(
        widget.conversationId,
      );
      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Admin avatar (small, top-left)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
              child: Text(
                widget.adminName.isNotEmpty
                    ? widget.adminName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // User avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2ED573).withValues(alpha: 0.2),
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Color(0xFF2ED573),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                Text(
                  'with ${widget.adminName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.lock, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Read Only',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            )
          : _messages.isEmpty
          ? const Center(
              child: Text(
                'No messages yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // ✅ Correctly identify sender
                final sentByUser = msg.senderId == widget.userId;
                final sentByAdmin = msg.senderId == widget.adminId;
                final senderName = sentByUser
                    ? widget.userName
                    : sentByAdmin
                    ? widget.adminName
                    : 'Unknown';

                final showTime =
                    index == 0 || _messages[index - 1].senderId != msg.senderId;

                return _MessageBubble(
                  message: msg,
                  isUser:
                      sentByUser, // User messages on left (white), Admin on right (green)
                  showTime: showTime,
                  senderName: senderName,
                  senderColor: sentByUser
                      ? const Color(0xFF2ED573) // Green for user
                      : Colors.orange, // Orange for admin
                );
              },
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final bool showTime;
  final String senderName;
  final Color senderColor;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.showTime,
    required this.senderName,
    required this.senderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  // ✅ Colored dot to indicate sender
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: senderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${senderName} • ${_formatTime(message.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isUser) const SizedBox(width: 12),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    // ✅ Different colors for user (white) vs admin (green)
                    color: isUser ? Colors.white : const Color(0xFF2ED573),
                    border: isUser
                        ? Border.all(
                            color: senderColor.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 4 : 16),
                      bottomRight: Radius.circular(isUser ? 16 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? const Color(0xFF111111) : Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (!isUser) const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
