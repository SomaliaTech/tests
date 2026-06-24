import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/chat/domain/entities/conversation.dart';
import 'package:mobile/features/chat/domain/usecases/get_conversations.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_event.dart';
import 'conversations_state.dart';
import '../../../../core/services/chat_socket_service.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations getConversations;
  final ChatSocketService socketService;
  List<Conversation> _conversations = [];

  ConversationsBloc({
    required this.getConversations,
    required this.socketService,
  }) : super(ConversationsInitial()) {
    on<LoadConversationsEvent>(_onLoad);
    on<ConversationUpdatedEvent>(_onUpdate);
  }

  Future<void> _onLoad(
    LoadConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading());
    final result = await getConversations();
    result.fold((failure) => emit(ConversationsError(failure.message)), (
      conversations,
    ) {
      _conversations = conversations;
      emit(ConversationsLoaded(_conversations));
    });
  }

  void _onUpdate(
    ConversationUpdatedEvent event,
    Emitter<ConversationsState> emit,
  ) {
    final index = _conversations.indexWhere(
      (c) => c.partnerId == event.conversation.partnerId,
    );
    if (index != -1) {
      _conversations[index] = event.conversation;
      emit(ConversationsLoaded(List.from(_conversations)));
    }
  }
}
