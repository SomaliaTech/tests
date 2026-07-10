import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/services/sound/message_sound_manager.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_bloc.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_event.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_state.dart';
import 'package:mobile/features/chat/presentation/screens/chat_profile_view_screen.dart';
import 'package:mobile/features/chat/presentation/widgets/chat_skeletons.dart';
import 'package:mobile/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:mobile/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mobile/features/chat/presentation/widgets/image_picker_sheet.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../../../../core/services/injection_container.dart';

class ChatRoomScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerImage;
  final bool isOnline;

  const ChatRoomScreen({
    super.key,
    required this.partnerId,
    this.partnerName = '', // ✅ Default to empty string
    this.partnerImage,
    this.isOnline = false,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final ChatRoomBloc _chatRoomBloc;
  late final ChatSocketService _socketService;

  bool _isInitialized = false;
  Timer? _typingDebounce;

  XFile? _selectedImage;
  bool _isUploadingLocally = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _socketService = sl<ChatSocketService>();
    _chatRoomBloc = ChatRoomBloc(
      getChatHistory: sl(),
      markAsRead: sl(),
      socketService: _socketService,
    );

    MessageSoundManager().setCurrentChatPartner(widget.partnerId);

    _initializeChat();
    _messageController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _chatRoomBloc.add(const MarkMessagesAsReadEvent());
    }
  }

  Future<void> _initializeChat() async {
    if (_isInitialized || widget.partnerId.isEmpty) return;
    _isInitialized = true;

    await _chatRoomBloc.getCurrentUserId();
    if (!mounted) return;

    // ✅ Fetch partner info if name is not provided
    if (widget.partnerName.isEmpty) {
      _chatRoomBloc.add(LoadPartnerInfoEvent(widget.partnerId));
    }

    if (!_socketService.isConnected) {
      await _socketService.connect();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _socketService.checkPartnerStatus(widget.partnerId);
    _chatRoomBloc.add(
      LoadChatHistoryEvent(
        partnerId: widget.partnerId,
        isOnline: widget.isOnline,
      ),
    );
  }

  void _onTextChanged() {
    _typingDebounce?.cancel();
    final hasText = _messageController.text.isNotEmpty;

    _chatRoomBloc.add(UserTypingEvent(hasText));

    if (hasText) {
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        if (_messageController.text.isEmpty) {
          _chatRoomBloc.add(const UserTypingEvent(false));
        }
      });
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _messageController.text.isEmpty) {
      _chatRoomBloc.add(const UserTypingEvent(false));
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    final hasImage = _selectedImage != null;

    if (hasImage) {
      _chatRoomBloc.add(
        SendSelectedImageEvent(caption: content.isNotEmpty ? content : null),
      );
      _messageController.clear();
      _chatRoomBloc.add(const UserTypingEvent(false));
      _scrollToBottom();
      return;
    }

    if (content.isEmpty) return;

    _chatRoomBloc.add(
      SendMessageEvent(widget.partnerId, content, 'text', null),
    );
    _messageController.clear();
    _chatRoomBloc.add(const UserTypingEvent(false));
    _scrollToBottom();
  }

  void _pickAndSendImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ImagePickerSheet(
        onCameraTap: () {
          Navigator.pop(context);
          _chatRoomBloc.add(CameraImageEvent(widget.partnerId));
        },
        onGalleryTap: () {
          Navigator.pop(context);
          _chatRoomBloc.add(PickAndSendImageEvent(widget.partnerId));
        },
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    MessageSoundManager().setCurrentChatPartner(null);
    WidgetsBinding.instance.removeObserver(this);
    _typingDebounce?.cancel();
    _messageController
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _scrollController.dispose();
    _chatRoomBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatRoomBloc,
      child: BlocListener<ChatRoomBloc, ChatRoomState>(
        listener: (context, state) {
          if (state is ChatRoomImageSelected) {
            setState(() {
              _selectedImage = state.image;
              _isUploadingLocally = false;
            });
          } else if (state is ChatRoomImageUploading) {
            setState(() {
              _selectedImage = state.image;
              _isUploadingLocally = true;
            });
          } else if (state is ChatRoomLoaded && _isUploadingLocally) {
            setState(() {
              _selectedImage = null;
              _isUploadingLocally = false;
            });
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Hero(tag: 'avatar_${widget.partnerId}', child: _buildPartnerAvatar()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPartnerName(), // ✅ Use the new method
                _buildPartnerStatus(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Partner name with loading state
  Widget _buildPartnerName() {
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(
      builder: (context, state) {
        String displayName = widget.partnerName;

        // If partner name is empty, try to get it from state
        if (displayName.isEmpty && state is ChatRoomLoaded) {
          displayName = state.partnerName ?? '';
        }

        // If still empty, show default
        if (displayName.isEmpty) {
          displayName = 'User';
        }

        return Text(
          displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  // ✅ NEW: Partner online/typing status
  Widget _buildPartnerStatus() {
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(
      buildWhen: (p, c) {
        if (p is ChatRoomLoaded && c is ChatRoomLoaded) {
          return p.isPartnerOnline != c.isPartnerOnline ||
              p.isPartnerTyping != c.isPartnerTyping;
        }
        return true;
      },
      builder: (context, state) {
        if (state is ChatRoomLoaded && state.isPartnerTyping) {
          return const Text(
            'typing...',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF2ED573),
              fontStyle: FontStyle.italic,
            ),
          );
        }
        final isOnline = state is ChatRoomLoaded
            ? state.isPartnerOnline
            : widget.isOnline;
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF2ED573) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                color: isOnline ? const Color(0xFF2ED573) : Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(
      buildWhen: (p, c) {
        if (p is ChatRoomLoaded && c is ChatRoomLoaded) {
          return p.isPartnerTyping != c.isPartnerTyping;
        }
        return false;
      },
      builder: (context, state) {
        if (state is ChatRoomLoaded && state.isPartnerTyping) {
          // ✅ Get partner name from state if available
          final name = state.partnerName ?? widget.partnerName;
          return TypingIndicator(
            partnerImage: widget.partnerImage,
            partnerName: name.isNotEmpty ? name : 'User',
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageList() {
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
      buildWhen: (p, c) =>
          c is! ChatRoomImageSelected && c is! ChatRoomImageUploading,
      listener: (context, state) {
        if (state is ChatRoomLoaded && state.isHistoryLoaded) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state is ChatRoomLoaded && !state.isHistoryLoaded) {
          return const MessagesSkeletonList(count: 8);
        }

        if (state is ChatRoomLoading) {
          return const MessagesSkeletonList(count: 8);
        }

        if (state is ChatRoomError) {
          return _buildErrorState(state.message);
        }

        if (state is ChatRoomLoaded) {
          if (state.messages.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final msg = state.messages[index];
              final isMe = msg.senderId == _chatRoomBloc.currentUserId;
              return MessageBubble(
                key: ValueKey(msg.id),
                message: msg,
                isMe: isMe,
              );
            },
          );
        }

        return const MessagesSkeletonList(count: 8);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.message, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello! 👋',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _chatRoomBloc.add(
                  LoadChatHistoryEvent(partnerId: widget.partnerId),
                );
              },
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImage != null)
          _buildImagePreviewBar(_selectedImage!, _isUploadingLocally),
        _buildTextInputArea(hasImage: _selectedImage != null),
      ],
    );
  }

  Widget _buildImagePreviewBar(XFile image, bool isUploading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(image.path),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Iconsax.gallery_slash,
                        color: Colors.grey,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUploading ? 'Uploading image...' : 'Add a caption (optional)',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          if (!isUploading)
            IconButton(
              onPressed: () {
                _chatRoomBloc.add(const CancelImageSelectionEvent());
                setState(() {
                  _selectedImage = null;
                  _isUploadingLocally = false;
                });
              },
              icon: const Icon(Icons.close, color: Colors.red, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextInputArea({bool hasImage = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Material(
              color: Colors.grey.shade100,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _pickAndSendImage,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Iconsax.gallery,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: hasImage
                        ? 'Add a caption...'
                        : 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF2ED573),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _sendMessage,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Iconsax.send_2, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar() {
    final hasImage =
        widget.partnerImage != null && widget.partnerImage!.isNotEmpty;

    final fallbackWidget = CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey.shade100,
      child: Text(
        widget.partnerName.isNotEmpty
            ? widget.partnerName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Color(0xFF2ED573),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );

    if (!hasImage) {
      return GestureDetector(onTap: _navigateToProfile, child: fallbackWidget);
    }

    return GestureDetector(
      onTap: _navigateToProfile,
      child: CachedNetworkImage(
        imageUrl: widget.partnerImage!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade100,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2ED573),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('❌ Failed to load partner avatar: $url');
          return fallbackWidget;
        },
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatProfileViewScreen(
          partnerId: widget.partnerId,
          partnerName: widget.partnerName,
          partnerImage: widget.partnerImage,
          isOnline: widget.isOnline,
        ),
      ),
    );
  }
}
