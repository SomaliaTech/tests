// lib/features/chat/presentation/widgets/message_bubble.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isImage = message.type == 'image';
    final isTemp = message.id.startsWith('temp_');
    final hasContent = message.content != null && message.content!.isNotEmpty;
    final showText = hasContent && message.content != '📷 Photo';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (isImage && message.mediaUrl != null)
              _buildImageBubble(isTemp, context),
            if (showText) _buildTextBubble(context),
            _buildMetaRow(isTemp),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2ED573) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        message.content!,
        style: TextStyle(
          color: isMe ? Colors.white : const Color(0xFF333333),
          fontSize: 15,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildImageBubble(bool isTemp, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (message.mediaUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenImage(imageUrl: message.mediaUrl!),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImageWidget(),
            ),
          ),
          if (isTemp)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (isMe && !isTemp)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 3),
                    _buildReadReceipt(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (message.mediaUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: message.mediaUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Icon(
            Iconsax.gallery_slash,
            color: Colors.grey,
            size: 40,
          ),
        ),
      );
    }

    final file = File(message.mediaUrl!);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Icon(
            Iconsax.gallery_slash,
            color: Colors.grey,
            size: 40,
          ),
        ),
      );
    }

    return Container(
      width: 200,
      height: 200,
      color: Colors.grey.shade200,
      child: const Icon(Iconsax.gallery_slash, color: Colors.grey, size: 40),
    );
  }

  Widget _buildMetaRow(bool isTemp) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          if (isMe) ...[const SizedBox(width: 4), _buildReadReceipt()],
        ],
      ),
    );
  }

  Widget _buildReadReceipt() {
    if (message.id.startsWith('temp_')) {
      return Icon(Icons.access_time, size: 14, color: Colors.grey.shade400);
    }
    return Icon(
      Icons.done_all,
      size: 16,
      color: message.isRead ? Colors.blue : Colors.grey.shade400,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    final hour = '${time.hour}'.padLeft(2, '0');
    final minute = '${time.minute}'.padLeft(2, '0');

    if (messageDate == today) return '$hour:$minute';
    if (messageDate == today.subtract(const Duration(days: 1)))
      return 'Yesterday $hour:$minute';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: imageUrl.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                )
              : Image.file(
                  File(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Iconsax.gallery_slash,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// In your MessageBubble class
String _formatTime(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(time.year, time.month, time.day);

  // Format in 12-hour format
  final hour = time.hour > 12
      ? (time.hour - 12)
      : (time.hour == 0 ? 12 : time.hour);
  final minute = '${time.minute}'.padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  final timeStr = '$hour:$minute $period';

  if (messageDate == today) return timeStr;
  if (messageDate == today.subtract(const Duration(days: 1)))
    return 'Yesterday $timeStr';
  return '${time.day}/${time.month}/${time.year} $timeStr';
}

// Also fix the formatChatTime function
String formatChatTime(dynamic timestamp) {
  if (timestamp == null) return '';

  DateTime dateTime;

  if (timestamp is String) {
    dateTime = DateTime.parse(timestamp).toLocal(); // ✅ Convert to local
  } else if (timestamp is DateTime) {
    dateTime = timestamp.toLocal(); // ✅ Convert to local
  } else {
    return '';
  }

  return DateFormat('h:mm a').format(dateTime);
}
