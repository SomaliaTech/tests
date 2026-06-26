import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_chat_history.dart';
import '../../domain/usecases/mark_as_read.dart' as chat;
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
  StreamSubscription? _sentSub;

  ChatRoomBloc({
    required this.getChatHistory,
    required this.markAsRead,
    required this.socketService,
  }) : super(ChatRoomInitial()) {
    on<LoadChatHistoryEvent>(_onLoadHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<UpdatePartnerStatusEvent>(_onUpdatePartnerStatus);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new messages
    _msgSub = socketService.onNewMessage.listen((message) {
      if (isClosed) return;

      // ✅ Now receives ChatMessage directly, no need to parse
      if ((message.senderId == _currentPartnerId ||
              message.receiverId == _currentPartnerId) &&
          !isClosed) {
        add(ReceiveMessageEvent(message));
      }
    });

    // ✅ Listen for partner status changes
    _statusSub = socketService.onStatusChange.listen((data) {
      if (isClosed) return;

      print('🟢 ChatRoomBloc received status change: $data');

      final userId = data['userId'] as String?;
      final isOnline = data['isOnline'] as bool? ?? false;

      print(
        '🟢 Checking: userId=$userId, currentPartner=$_currentPartnerId, isOnline=$isOnline',
      );

      if (userId == _currentPartnerId && !isClosed) {
        print('✅ Dispatching UpdatePartnerStatusEvent');
        add(UpdatePartnerStatusEvent(userId!, isOnline));
      }
    });

    // Listen for sent message confirmations
    _sentSub = socketService.onMessageSent.listen((data) {
      if (isClosed) return;

      try {
        if (data is Map && !isClosed) {
          final confirmedMessage = ChatMessage.fromJson(data);
          final index = _messages.indexWhere(
            (m) =>
                m.id.startsWith('temp_') &&
                m.content == confirmedMessage.content,
          );
          if (index >= 0 && !isClosed) {
            _messages[index] = confirmedMessage;
            add(ReceiveMessageEvent(confirmedMessage));
          }
        }
      } catch (e) {
        // Ignore parse errors
      }
    });
  }

  Future<void> _onLoadHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (isClosed) return;

    _currentPartnerId = event.partnerId;
    _isPartnerOnline = event.isOnline;

    emit(ChatRoomLoading());

    final result = await getChatHistory(event.partnerId);

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            ChatRoomLoaded(
              messages: const [],
              isPartnerOnline: _isPartnerOnline,
            ),
          );
        }
      },
      (history) {
        if (!isClosed) {
          _messages = List.from(history);
          emit(
            ChatRoomLoaded(
              messages: _messages,
              isPartnerOnline: _isPartnerOnline,
            ),
          );
          markAsRead.call(event.partnerId);
        }
      },
    );
  }

  void _onSendMessage(SendMessageEvent event, Emitter<ChatRoomState> emit) {
    if (isClosed) return;

    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      receiverId: event.partnerId,
      content: event.content,
      type: event.type,
      mediaUrl: event.mediaUrl,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _messages.insert(0, tempMessage);

    if (!isClosed) {
      emit(
        ChatRoomLoaded(
          messages: List.from(_messages),
          isPartnerOnline: _isPartnerOnline,
        ),
      );
    }

    socketService.sendMessage(
      receiverId: event.partnerId,
      content: event.content,
      type: event.type,
      mediaUrl: event.mediaUrl,
    );
  }

  void _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    if (isClosed) return;

    final exists = _messages.any((m) => m.id == event.message.id);
    if (!exists) {
      _messages.removeWhere(
        (m) => m.id.startsWith('temp_') && m.content == event.message.content,
      );
      _messages.insert(0, event.message);
    } else {
      final index = _messages.indexWhere((m) => m.id == event.message.id);
      if (index >= 0) {
        _messages[index] = event.message;
      }
    }

    if (!isClosed) {
      emit(
        ChatRoomLoaded(
          messages: List.from(_messages),
          isPartnerOnline: _isPartnerOnline,
        ),
      );
    }
  }

  void _onUpdatePartnerStatus(
    UpdatePartnerStatusEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    if (isClosed) return;

    print('✅ _onUpdatePartnerStatus called: isOnline=${event.isOnline}');

    _isPartnerOnline = event.isOnline;

    // ✅ Always emit if we have messages loaded
    if (state is ChatRoomLoaded && !isClosed) {
      print('✅ Emitting ChatRoomLoaded with isPartnerOnline=$_isPartnerOnline');
      emit(
        ChatRoomLoaded(
          messages: List.from(_messages),
          isPartnerOnline: _isPartnerOnline,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _msgSub?.cancel();
    _statusSub?.cancel();
    _sentSub?.cancel();
    return super.close();
  }
}
