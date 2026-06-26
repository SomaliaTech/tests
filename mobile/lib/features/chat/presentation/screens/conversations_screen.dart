import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_event.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_state.dart';
import '../../domain/entities/conversation.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../bloc/conversations_bloc.dart';
import 'chat_room_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  StreamSubscription? _connectionSub;
  bool _hasReloadedAfterConnect = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    final socketService = sl<ChatSocketService>();
    _connectionSub = socketService.onConnectionChange.listen((isConnected) {
      if (isConnected && mounted && !_hasReloadedAfterConnect) {
        _hasReloadedAfterConnect = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Use the global singleton bloc
            sl<ConversationsBloc>().add(LoadConversationsEvent());
          }
        });
      }
    });

    // Load conversations on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<ConversationsBloc>().add(LoadConversationsEvent());
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (query.trim().isEmpty) {
        setState(() => _isSearching = false);
        sl<ConversationsBloc>().add(const ClearSearchEvent());
      } else if (query.trim().length >= 2) {
        setState(() => _isSearching = true);
        sl<ConversationsBloc>().add(SearchConversationsEvent(query));
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearching = false);
    sl<ConversationsBloc>().add(const ClearSearchEvent());
  }

  @override
  Widget build(BuildContext context) {
    // Use BlocProvider.value to provide the singleton bloc
    return BlocProvider.value(
      value: sl<ConversationsBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Messages',
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Iconsax.setting_4,
                color: Color(0xFF111111),
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Builder(
          builder: (context) {
            return RefreshIndicator(
              color: const Color(0xFF2ED573),
              onRefresh: () async {
                sl<ConversationsBloc>().add(LoadConversationsEvent());
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by name, phone, or message...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Iconsax.search_normal,
                            color: Colors.grey.shade400,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Iconsax.close_circle,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2ED573),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  Expanded(
                    child: BlocConsumer<ConversationsBloc, ConversationsState>(
                      listener: (context, state) {
                        if (state is ConversationsSearchResults) {
                          setState(() => _isSearching = false);
                        }
                      },
                      builder: (context, state) {
                        if (state is ConversationsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2ED573),
                            ),
                          );
                        }

                        if (state is ConversationsError) {
                          return _buildErrorState(state.message, context);
                        }

                        if (state is ConversationsSearchResults) {
                          if (state.conversations.isEmpty) {
                            return _buildNoSearchResultsState(state.query);
                          }

                          return _buildConversationsList(
                            state.conversations,
                            context,
                          );
                        }

                        if (state is ConversationsLoaded) {
                          if (state.conversations.isEmpty) {
                            return _buildEmptyState(context);
                          }
                          return _buildConversationsList(
                            state.conversations,
                            context,
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationsList(
    List<Conversation> conversations,
    BuildContext context,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: conversations.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return _ConversationCard(
          conversation: conv,
          onTap: () async {
            final socketService = sl<ChatSocketService>();
            if (!socketService.isConnected) {
              await socketService.connect();
            }
            socketService.checkPartnerStatus(conv.partnerId);

            if (!context.mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  key: ValueKey(conv.partnerId),
                  partnerId: conv.partnerId,
                  partnerName: conv.partnerName,
                  partnerImage: conv.partnerImage,
                  isOnline: conv.isOnline,
                ),
              ),
            );

            if (!context.mounted) return;
            sl<ConversationsBloc>().add(LoadConversationsEvent());
          },
        );
      },
    );
  }

  Widget _buildNoSearchResultsState(String query) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.search_status,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No conversations found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No results for "$query"',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.message_text,
                  size: 48,
                  color: Color(0xFF2ED573),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start chatting with your friends!',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.danger, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  sl<ConversationsBloc>().add(LoadConversationsEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final conv = conversation;
    final hasUnread = conv.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      (conv.partnerImage != null &&
                          conv.partnerImage!.isNotEmpty)
                      ? CachedNetworkImageProvider(conv.partnerImage!)
                      : null,
                  backgroundColor: Colors.grey.shade100,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: conv.isOnline
                          ? const Color(0xFF2ED573)
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.partnerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasUnread)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Iconsax.message_text,
                            size: 14,
                            color: Color(0xFF2ED573),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          conv.lastMessageType == 'image'
                              ? '📷 Photo'
                              : (conv.lastMessage ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? const Color(0xFF111111)
                                : Colors.grey.shade500,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conv.lastMessageTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread
                        ? const Color(0xFF2ED573)
                        : Colors.grey.shade400,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ED573),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conv.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    try {
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inDays == 0) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return _getDayName(time.weekday);
      } else {
        return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
      }
    } catch (_) {
      return '';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }
}
