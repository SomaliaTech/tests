import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/conversation.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/search_conversations.dart';
import '../../../../core/services/chat_socket_service.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations getConversations;
  final SearchConversations searchConversations;
  final ChatSocketService socketService;

  List<Conversation> _conversations = [];
  bool _isInitialLoad = true;
  Timer? _reloadTimer;

  StreamSubscription? _messageSub;
  StreamSubscription? _messageSentSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _connectionSub;

  ConversationsBloc({
    required this.getConversations,
    required this.searchConversations,
    required this.socketService,
  }) : super(ConversationsInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<NewMessageReceivedEvent>(_onNewMessage);
    on<MessageSentEvent>(_onMessageSent);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
    on<SearchConversationsEvent>(_onSearch);
    on<ClearSearchEvent>(_onClearSearch);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _connectionSub = socketService.onConnectionChange.listen((isConnected) {
      if (isConnected && !isClosed && _conversations.isEmpty) {
        add(LoadConversationsEvent());
      }
    });

    _messageSub = socketService.onNewMessage.listen((message) {
      if (isClosed) return;
      add(
        NewMessageReceivedEvent(
          senderId: message.senderId,
          content: message.content,
          type: message.type,
          createdAt: message.createdAt,
        ),
      );
    });

    _messageSentSub = socketService.onMessageSent.listen((data) {
      if (isClosed) return;
      try {
        final receiverId = data['receiverId'] ?? data['receiver_id'];
        final content = data['content'] as String?;
        final type = (data['type'] ?? 'text').toString();
        final createdAt = DateTime.tryParse(
          (data['createdAt'] ?? data['created_at'] ?? '').toString(),
        );

        if (receiverId != null && createdAt != null) {
          add(
            MessageSentEvent(
              receiverId: receiverId.toString(),
              content: content,
              type: type,
              createdAt: createdAt,
            ),
          );
        }
      } catch (_) {}
    });

    _statusSub = socketService.onStatusChange.listen((data) {
      if (isClosed) return;
      final userId = data['userId'] as String?;
      final isOnline = data['isOnline'] as bool? ?? false;

      if (userId != null) {
        add(UpdateUserStatusEvent(userId: userId, isOnline: isOnline));
      }
    });
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    if (isClosed) return;

    // Only show loading indicator on first load
    if (_isInitialLoad) {
      emit(ConversationsLoading());
    }

    final result = await getConversations();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (_conversations.isEmpty) {
          emit(ConversationsError(failure.message));
        }
      },
      (conversations) {
        _conversations = List.from(conversations);
        _conversations.sort(
          (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
        );
        _isInitialLoad = false;
        emit(ConversationsLoaded(List.from(_conversations)));
      },
    );
  }

  void _onNewMessage(
    NewMessageReceivedEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (isClosed) return;

    final index = _conversations.indexWhere(
      (c) => c.partnerId == event.senderId,
    );
    final preview = event.type == 'image' ? '📷 Photo' : (event.content ?? '');

    if (index != -1) {
      // Update existing conversation
      final conv = _conversations[index];
      final updatedConv = ConversationModel(
        partnerId: conv.partnerId,
        partnerName: conv.partnerName,
        partnerImage: conv.partnerImage,
        isOnline: true, // Sender is online since they just sent a message
        lastMessage: preview,
        lastMessageType: event.type,
        lastMessageTime: event.createdAt,
        unreadCount: conv.unreadCount + 1,
      );
      _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);
      emit(ConversationsLoaded(List.from(_conversations)));
    } else {
      // ✅ FIX: New conversation - reload from server after a short delay.
      // This prevents the API from returning the old list before the new conversation is saved to the DB.
      Future.delayed(const Duration(seconds: 1), () {
        if (!isClosed) add(LoadConversationsEvent());
      });
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
    final preview = event.type == 'image' ? '📷 Photo' : (event.content ?? '');

    if (index != -1) {
      final conv = _conversations[index];
      final updatedConv = ConversationModel(
        partnerId: conv.partnerId,
        partnerName: conv.partnerName,
        partnerImage: conv.partnerImage,
        isOnline: conv.isOnline,
        lastMessage: preview,
        lastMessageType: event.type,
        lastMessageTime: event.createdAt,
        unreadCount: conv.unreadCount,
      );
      _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);
      emit(ConversationsLoaded(List.from(_conversations)));
    } else {
      // ✅ FIX: If we sent a message to a NEW user, reload conversations after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (!isClosed) add(LoadConversationsEvent());
      });
    }
  }

  void _onUpdateUserStatus(
    UpdateUserStatusEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (isClosed) return;

    final index = _conversations.indexWhere((c) => c.partnerId == event.userId);

    if (index != -1) {
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

  Future<void> _onSearch(
    SearchConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    if (event.query.trim().length < 2) {
      emit(ConversationsLoaded(List.from(_conversations)));
      return;
    }

    final result = await searchConversations(event.query);

    if (isClosed) return;

    result.fold(
      (failure) => emit(ConversationsError(failure.message)),
      (conversations) =>
          emit(ConversationsSearchResults(conversations, event.query)),
    );
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<ConversationsState> emit,
  ) {
    emit(ConversationsLoaded(List.from(_conversations)));
  }

  @override
  Future<void> close() {
    _reloadTimer?.cancel();
    _messageSub?.cancel();
    _messageSentSub?.cancel();
    _statusSub?.cancel();
    _connectionSub?.cancel();
    return super.close();
  }
}
