// lib/features/chat/presentation/bloc/conversations_bloc.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/conversation.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/search_conversations.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../../data/datasources/chat_local_datasource.dart'; // ✅ ADD THIS
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations getConversations;
  final SearchConversations searchConversations;
  final ChatSocketService socketService;
  final ChatLocalDataSource localDataSource; // ✅ ADD THIS
  final ChatRepository chatRepository; // ✅ ADD THIS
  StreamSubscription? _userDeletedSub; // ✅ ADD THIS
  List<Conversation> get cachedConversations =>
      List.unmodifiable(_conversations);

  List<Conversation> _conversations = [];
  bool _isInitialLoad = true;
  Timer? _reloadTimer;

  StreamSubscription? _messageSub;
  StreamSubscription? _messageSentSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _conversationUpdateSub; // ✅ ADD THIS

  ConversationsBloc({
    required this.getConversations,
    required this.searchConversations,
    required this.socketService,
    required this.localDataSource, // ✅ ADD THIS
    required this.chatRepository,
  }) : super(ConversationsInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<NewMessageReceivedEvent>(_onNewMessage);
    on<MessageSentEvent>(_onMessageSent);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
    on<SearchConversationsEvent>(_onSearch);
    on<ClearSearchEvent>(_onClearSearch);
    on<ClearConversationsCacheEvent>(_onClearCache);
    on<ConversationsCacheUpdatedEvent>(_onCacheUpdated); // ✅ ADD THIS

    _setupSocketListeners();
    _setupRepositoryListeners(); // ✅ ADD THIS
  }
  void _setupRepositoryListeners() {
    _conversationUpdateSub = chatRepository.conversationUpdates.listen((
      updatedConversations,
    ) {
      if (!isClosed) {
        add(ConversationsCacheUpdatedEvent(updatedConversations));
      }
    });
  }

  void _setupSocketListeners() {
    _connectionSub = socketService.onConnectionChange.listen((isConnected) {
      if (isConnected && !isClosed && _conversations.isEmpty) {
        add(LoadConversationsEvent());
      }
    });

    _messageSub = socketService.onNewMessage.listen((message) async {
      if (isClosed) return;

      // ✅ CRITICAL FIX: Save the new message to local cache immediately.
      // Because ChatRoomBloc is only created when the chat screen opens,
      // it misses messages that arrive while the user is on the Conversations screen.
      // We save it here so it's already in Hive when the user clicks the chat.
      final currentUserId = socketService.userId ?? '';
      final partnerId = message.senderId == currentUserId
          ? message.receiverId
          : message.senderId;

      if (partnerId != null && partnerId.isNotEmpty) {
        try {
          await localDataSource.addMessage(partnerId, message);
        } catch (e) {
          debugPrint(
            '⚠️ [ConversationsBloc] Error saving received message: $e',
          );
        }
      }

      add(
        NewMessageReceivedEvent(
          senderId: message.senderId,
          content: message.content,
          type: message.type,
          createdAt: message.createdAt,
        ),
      );
    });

    _userDeletedSub = socketService.onUserDeleted.listen((data) {
      if (!isClosed) {
        // Force a full refresh from the server to drop the deleted user
        add(LoadConversationsEvent());
      }
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

  Future<void> _onCacheUpdated(
    ConversationsCacheUpdatedEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    _conversations = List.from(event.conversations);
    _conversations.sort(
      (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
    );
    emit(ConversationsLoaded(List.from(_conversations)));
  }

  // ==========================================
  // LOAD CONVERSATIONS - LOCAL FIRST
  // ==========================================

  Future<void> _onClearCache(
    ClearConversationsCacheEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    _conversations.clear();
    _isInitialLoad = true;
    emit(ConversationsInitial());
  }
  // In ConversationsBloc - Update _onLoadConversations

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    if (isClosed) return;

    // Don't show loading if we already have cached conversations
    if (_conversations.isNotEmpty && _isInitialLoad) {
      _isInitialLoad = false;
      emit(ConversationsLoaded(List.from(_conversations)));
    } else if (_isInitialLoad && _conversations.isEmpty) {
      emit(ConversationsLoading());
    }

    final result = await getConversations();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (_conversations.isEmpty) {
          emit(ConversationsError(failure.message));
        }
        _isInitialLoad = false;
      },
      (conversations) {
        // ✅ DEDUPLICATE conversations by partnerId
        final seenIds = <String>{};
        final uniqueConversations = <Conversation>[];

        for (final conv in conversations) {
          if (!seenIds.contains(conv.partnerId)) {
            seenIds.add(conv.partnerId);
            uniqueConversations.add(conv);
          }
        }

        _conversations = List.from(uniqueConversations);
        _conversations.sort(
          (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
        );
        _isInitialLoad = false;

        _saveConversationsToCache();
        emit(ConversationsLoaded(List.from(_conversations)));
      },
    );
  }

  // ✅ Add helper to save conversations to cache
  Future<void> _saveConversationsToCache() async {
    try {
      await localDataSource.cacheConversations(_conversations);
    } catch (e) {
      // Silently fail - cache update is not critical
    }
  }

  // ==========================================
  // NEW MESSAGE RECEIVED
  // ==========================================

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
      final conv = _conversations[index];
      final updatedConv = ConversationModel(
        partnerId: conv.partnerId,
        partnerName: conv.partnerName,
        partnerImage: conv.partnerImage,
        isOnline: true,
        lastMessage: preview,
        lastMessageType: event.type,
        lastMessageTime: event.createdAt,
        unreadCount: conv.unreadCount + 1,
      );
      _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);

      // ✅ Save to cache
      _saveConversationsToCache();

      emit(ConversationsLoaded(List.from(_conversations)));
    } else {
      // New conversation - reload from server
      Future.delayed(const Duration(seconds: 1), () {
        if (!isClosed) add(LoadConversationsEvent());
      });
    }
  }

  // ==========================================
  // MESSAGE SENT
  // ==========================================

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

      // ✅ Save to cache
      _saveConversationsToCache();

      emit(ConversationsLoaded(List.from(_conversations)));
    } else {
      // New conversation - reload
      Future.delayed(const Duration(seconds: 1), () {
        if (!isClosed) add(LoadConversationsEvent());
      });
    }
  }

  // ==========================================
  // USER STATUS UPDATE
  // ==========================================

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

  // ==========================================
  // SEARCH
  // ==========================================

  Future<void> _onSearch(
    SearchConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    if (event.query.trim().length < 2) {
      if (_conversations.isNotEmpty) {
        emit(ConversationsLoaded(List.from(_conversations)));
      }
      return;
    }

    final result = await searchConversations(event.query);

    if (isClosed) return;

    result.fold(
      (failure) {
        final filtered = _conversations
            .where(
              (c) => c.partnerName.toLowerCase().contains(
                event.query.toLowerCase(),
              ),
            )
            .toList();
        emit(ConversationsSearchResults(filtered, event.query));
      },
      (conversations) =>
          emit(ConversationsSearchResults(conversations, event.query)),
    );
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (_conversations.isNotEmpty) {
      emit(ConversationsLoaded(List.from(_conversations)));
    }
  }

  @override
  Future<void> close() {
    _reloadTimer?.cancel();
    _messageSub?.cancel();
    _messageSentSub?.cancel();
    _statusSub?.cancel();
    _connectionSub?.cancel();
    _conversationUpdateSub?.cancel(); // ✅ ADD THIS
    _userDeletedSub?.cancel(); // ✅ ADD THIS

    return super.close();
  }
}
