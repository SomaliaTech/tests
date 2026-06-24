import 'package:equatable/equatable.dart';
import 'package:mobile/features/chat/domain/entities/conversation.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends ConversationsEvent {}

class ConversationUpdatedEvent extends ConversationsEvent {
  final Conversation conversation;
  const ConversationUpdatedEvent(this.conversation);
  @override
  List<Object?> get props => [conversation];
}
