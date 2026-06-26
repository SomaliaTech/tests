import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/chat/domain/usecases/search_conversations.dart';
import '../../domain/entities/conversation.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../../../core/services/chat_socket_service.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations getConversations;
  final ChatSocketService socketService;
  final SearchConversations searchConversations;
  List<Conversation> _conversations = [];
  StreamSubscription? _messageSub;
  StreamSubscription? _messageSentSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _connectionSub;

  ConversationsBloc({
    required this.getConversations,
    required this.socketService,
    required this.searchConversations,
  }) : super(ConversationsInitial()) {
    on<LoadConversationsEvent>(_onLoad);
    on<ConversationUpdatedEvent>(_onUpdate);
    on<NewMessageReceivedEvent>(_onNewMessage);
    on<MessageSentEvent>(_onMessageSent);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
    on<SearchConversationsEvent>(_onSearch);
    on<ClearSearchEvent>(_onClearSearch);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _connectionSub = socketService.onConnectionChange.listen((isConnected) {
      if (isClosed) return;
      if (isConnected && !isClosed) {
        add(LoadConversationsEvent());
      }
    });

    // ✅ FIXED: Now receives ChatMessage objects directly
    _messageSub = socketService.onNewMessage.listen((message) {
      if (isClosed) return;
      try {
        if (!isClosed) {
          add(
            NewMessageReceivedEvent(
              senderId: message.senderId,
              content: message.content,
              type: message.type,
              createdAt: message.createdAt,
            ),
          );
        }
      } catch (e) {
        // Ignore parse errors
      }
    });

    _messageSentSub = socketService.onMessageSent.listen((data) {
      if (isClosed) return;
      try {
        final receiverId = data['receiverId'] ?? data['receiver_id'];
        final content = data['content'] as String?;
        final type = data['type'] as String? ?? 'text';
        final createdAtStr = data['createdAt'] ?? data['created_at'];

        if (receiverId != null && createdAtStr != null && !isClosed) {
          add(
            MessageSentEvent(
              receiverId: receiverId.toString(),
              content: content,
              type: type,
              createdAt: DateTime.parse(createdAtStr.toString()),
            ),
          );
        }
      } catch (e) {
        // Ignore parse errors
      }
    });

    _statusSub = socketService.onStatusChange.listen((data) {
      if (isClosed) return;
      final userId = data['userId'] as String?;
      final isOnline = data['isOnline'] as bool? ?? false;

      if (userId != null && !isClosed) {
        add(UpdateUserStatusEvent(userId: userId, isOnline: isOnline));
      }
    });
  }

  void _onUpdateUserStatus(
    UpdateUserStatusEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (isClosed) return;

    final index = _conversations.indexWhere((c) => c.partnerId == event.userId);

    if (index != -1 && !isClosed) {
      _conversations[index] = ConversationModel(
        partnerId: _conversations[index].partnerId,
        partnerName: _conversations[index].partnerName,
        partnerImage: _conversations[index].partnerImage,
        isOnline: event.isOnline,
        lastMessage: _conversations[index].lastMessage,
        lastMessageType: _conversations[index].lastMessageType,
        lastMessageTime: _conversations[index].lastMessageTime,
        unreadCount: _conversations[index].unreadCount,
      );

      emit(ConversationsLoaded(List.from(_conversations)));
    }
  }

  Future<void> _onLoad(
    LoadConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    if (isClosed) return;

    emit(ConversationsLoading());
    final result = await getConversations();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(ConversationsError(failure.message));
      },
      (conversations) {
        if (!isClosed) {
          _conversations = List.from(conversations);
          _conversations.sort(
            (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
          );
          emit(ConversationsLoaded(_conversations));
        }
      },
    );
  }

  void _onUpdate(
    ConversationUpdatedEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (isClosed) return;
    final index = _conversations.indexWhere(
      (c) => c.partnerId == event.conversation.partnerId,
    );
    if (index != -1 && !isClosed) {
      _conversations[index] = event.conversation;
      emit(ConversationsLoaded(List.from(_conversations)));
    }
  }

  Future<void> _onSearch(
    SearchConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    if (event.query.trim().length < 2) {
      emit(ConversationsLoaded(_conversations));
      return;
    }

    final result = await searchConversations(event.query);
    result.fold(
      (failure) {
        emit(ConversationsError(failure.message));
      },
      (conversations) {
        emit(ConversationsSearchResults(conversations, event.query));
      },
    );
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<ConversationsState> emit,
  ) {
    emit(ConversationsLoaded(_conversations));
  }

  void _onNewMessage(
    NewMessageReceivedEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (isClosed) return;

    final index = _conversations.indexWhere(
      (c) => c.partnerId == event.senderId,
    );
    final textDisplay = event.type == 'image'
        ? '📷 Photo'
        : (event.content ?? '');

    if (index != -1 && !isClosed) {
      final conv = _conversations[index];
      final updatedConv = ConversationModel(
        partnerId: conv.partnerId,
        partnerName: conv.partnerName,
        partnerImage: conv.partnerImage,
        isOnline: conv.isOnline,
        lastMessage: textDisplay,
        lastMessageType: event.type,
        lastMessageTime: event.createdAt,
        unreadCount: conv.unreadCount + 1,
      );
      _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);
    } else {
      if (!isClosed) {
        _conversations.insert(
          0,
          ConversationModel(
            partnerId: event.senderId,
            partnerName: 'User Chat',
            partnerImage: null,
            isOnline: true,
            lastMessage: textDisplay,
            lastMessageType: event.type,
            lastMessageTime: event.createdAt,
            unreadCount: 1,
          ),
        );
        add(LoadConversationsEvent());
      }
    }
    if (!isClosed) {
      emit(ConversationsLoaded(List.from(_conversations)));
    }
  }

  void _onMessageSent(
    MessageSentEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (isClosed) return;

    final index = _conversations.indexWhere(
      (c) => c.partnerId == event.receiverId,
    );
    final textDisplay = event.type == 'image'
        ? '📷 Photo'
        : (event.content ?? '');

    if (index != -1 && !isClosed) {
      final conv = _conversations[index];
      final updatedConv = ConversationModel(
        partnerId: conv.partnerId,
        partnerName: conv.partnerName,
        partnerImage: conv.partnerImage,
        isOnline: conv.isOnline,
        lastMessage: textDisplay,
        lastMessageType: event.type,
        lastMessageTime: event.createdAt,
        unreadCount: conv.unreadCount,
      );
      _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);
    } else {
      if (!isClosed) {
        add(LoadConversationsEvent());
      }
    }
    if (!isClosed) {
      emit(ConversationsLoaded(List.from(_conversations)));
    }
  }

  @override
  Future<void> close() {
    _messageSub?.cancel();
    _messageSentSub?.cancel();
    _statusSub?.cancel();
    _connectionSub?.cancel();
    return super.close();
  }
}
