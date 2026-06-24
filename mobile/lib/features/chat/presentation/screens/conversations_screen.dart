import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_event.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_state.dart';
import '../../../../core/services/injection_container.dart';
import '../bloc/conversations_bloc.dart';
import 'chat_room_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ConversationsBloc>()..add(LoadConversationsEvent()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Messages',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2ED573)),
              );
            }
            if (state is ConversationsLoaded) {
              if (state.conversations.isEmpty) {
                return const Center(child: Text('No conversations yet.'));
              }
              return ListView.builder(
                itemCount: state.conversations.length,
                itemBuilder: (context, index) {
                  final conv = state.conversations[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: conv.partnerImage != null
                          ? CachedNetworkImageProvider(conv.partnerImage!)
                          : null,
                      child: conv.partnerImage == null
                          ? const Icon(Iconsax.user)
                          : null,
                    ),
                    title: Text(
                      conv.partnerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      conv.lastMessageType == 'image'
                          ? '📷 Photo'
                          : (conv.lastMessage ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(conv.lastMessageTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (conv.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2ED573),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            partnerId: conv.partnerId,
                            partnerName: conv.partnerName,
                            partnerImage: conv.partnerImage,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
