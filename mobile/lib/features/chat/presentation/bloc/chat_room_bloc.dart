import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/usecases/get_chat_history.dart';
import 'package:mobile/features/chat/domain/usecases/mark_as_read.dart' as chat;
import 'chat_room_event.dart';
import 'chat_room_state.dart';
import '../../../../core/services/chat_socket_service.dart';

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final GetChatHistory getChatHistory;
  final chat.MarkAsRead markAsRead;
  final ChatSocketService socketService;

  List<ChatMessage> _messages = [];
  bool _isPartnerOnline = false;
  String? _currentPartnerId;
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;

  ChatRoomBloc({
    required this.getChatHistory,
    required this.markAsRead,
    required this.socketService,
  }) : super(ChatRoomInitial()) {
    print('📦 ChatRoomBloc initialized with socket: ${socketService.hashCode}');

    on<LoadChatHistoryEvent>(_onLoadHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<UpdatePartnerStatusEvent>(_onUpdatePartnerStatus);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    print('🎧 Setting up socket listeners');

    _msgSub = socketService.onNewMessage.listen((data) {
      print('📩 Socket message received: $data');
      try {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        add(ReceiveMessageEvent(message));
      } catch (e) {
        print('❌ Error parsing socket message: $e');
      }
    });

    _statusSub = socketService.onStatusChange.listen((data) {
      print('🔄 Status change received: $data');
      if (data['userId'] == _currentPartnerId) {
        add(
          UpdatePartnerStatusEvent(
            data['userId'] as String,
            data['isOnline'] as bool? ?? false,
          ),
        );
      }
    });
  }

  Future<void> _onLoadHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    print('📂 Loading history for partner: ${event.partnerId}');
    _currentPartnerId = event.partnerId;
    emit(ChatRoomLoading());

    try {
      final result = await getChatHistory(event.partnerId);
      result.fold(
        (failure) {
          print('❌ Failed to load history: ${failure.message}');
          emit(ChatRoomLoaded(messages: [], isPartnerOnline: _isPartnerOnline));
        },
        (messages) {
          print('✅ Loaded ${messages.length} messages');
          _messages = messages;
          emit(
            ChatRoomLoaded(
              messages: _messages,
              isPartnerOnline: _isPartnerOnline,
            ),
          );
          // Mark messages as read
          markAsRead(event.partnerId);
        },
      );
    } catch (e) {
      print('❌ Error loading history: $e');
      emit(ChatRoomError(e.toString()));
    }
  }

  void _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    print('📤 Sending message: ${event.content}');

    // Create optimistic message
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me', // Will be replaced with real ID when server responds
      receiverId: event.partnerId,
      content: event.content,
      type: event.type,
      mediaUrl: event.mediaUrl,
      isRead: false,
      createdAt: DateTime.now(),
    );

    // Add to messages list immediately
    _messages.insert(0, tempMessage);
    emit(
      ChatRoomLoaded(
        messages: List.from(_messages),
        isPartnerOnline: _isPartnerOnline,
      ),
    );

    // Send via socket
    socketService.sendMessage(
      event.partnerId,
      event.content,
      event.type,
      event.mediaUrl,
    );
  }

  void _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    print('📨 Processing received message: ${event.message.id}');

    // Check for duplicates
    final exists = _messages.any((m) => m.id == event.message.id);
    if (!exists) {
      // Add new message at the beginning (newest first)
      _messages.insert(0, event.message);
      emit(
        ChatRoomLoaded(
          messages: List.from(_messages),
          isPartnerOnline: _isPartnerOnline,
        ),
      );

      // Mark as read if it's from the partner
      if (_currentPartnerId != null &&
          event.message.senderId == _currentPartnerId) {
        markAsRead(_currentPartnerId!);
      }
    } else {
      print('⚠️ Duplicate message ignored');
    }
  }

  void _onUpdatePartnerStatus(
    UpdatePartnerStatusEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    print('🔄 Updating partner status: ${event.isOnline}');
    _isPartnerOnline = event.isOnline;

    if (state is ChatRoomLoaded) {
      emit(
        ChatRoomLoaded(messages: _messages, isPartnerOnline: _isPartnerOnline),
      );
    }
  }

  @override
  Future<void> close() {
    print('🔌 Closing ChatRoomBloc');
    _msgSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
