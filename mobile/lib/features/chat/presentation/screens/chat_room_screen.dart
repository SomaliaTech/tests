import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_bloc.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_event.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_state.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/services/storage/storage_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerImage;

  const ChatRoomScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerImage,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    // ✅ Delay slightly to ensure Bloc is ready
    Future.microtask(() {
      context.read<ChatRoomBloc>().add(LoadChatHistoryEvent(widget.partnerId));
    });
  }

  Future<void> _getCurrentUserId() async {
    try {
      final storageService = GetIt.instance<StorageService>();
      _currentUserId = await storageService.getUserId();
    } catch (e) {
      _currentUserId = 'me';
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    context.read<ChatRoomBloc>().add(
      SendMessageEvent(
        widget.partnerId,
        _messageController.text.trim(),
        'text',
        null,
      ),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.partnerImage != null
                  ? CachedNetworkImageProvider(widget.partnerImage!)
                  : null,
              child: widget.partnerImage == null
                  ? const Icon(Iconsax.user, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partnerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                BlocBuilder<ChatRoomBloc, ChatRoomState>(
                  buildWhen: (previous, current) =>
                      current is ChatRoomLoaded &&
                      previous is ChatRoomLoaded &&
                      (previous as ChatRoomLoaded).isPartnerOnline !=
                          (current as ChatRoomLoaded).isPartnerOnline,
                  builder: (context, state) {
                    final isOnline =
                        state is ChatRoomLoaded && state.isPartnerOnline;
                    return Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? const Color(0xFF2ED573) : Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
              builder: (context, state) {
                if (state is ChatRoomLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ED573)),
                  );
                }

                if (state is ChatRoomLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.message, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet. Say hello!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      return _MessageBubble(message: msg, isMe: isMe);
                    },
                  );
                }

                if (state is ChatRoomError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.warning_2,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatRoomBloc>().add(
                              LoadChatHistoryEvent(widget.partnerId),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF2ED573),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.send_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2ED573) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == 'image' && message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.content != null && message.content!.isNotEmpty)
              Text(
                message.content!,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF333333),
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                    size: 12,
                    color: message.isRead ? Colors.blueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
