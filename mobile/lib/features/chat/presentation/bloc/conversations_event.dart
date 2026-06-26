import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation.dart';

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

class NewMessageReceivedEvent extends ConversationsEvent {
  final String senderId;
  final String? content;
  final String type;
  final DateTime createdAt;

  const NewMessageReceivedEvent({
    required this.senderId,
    this.content,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [senderId, content, type, createdAt];
}

class MessageSentEvent extends ConversationsEvent {
  final String receiverId;
  final String? content;
  final String type;
  final DateTime createdAt;

  const MessageSentEvent({
    required this.receiverId,
    this.content,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [receiverId, content, type, createdAt];
}

// ✅ NEW EVENT for status updates
class UpdateUserStatusEvent extends ConversationsEvent {
  final String userId;
  final bool isOnline;

  const UpdateUserStatusEvent({required this.userId, required this.isOnline});

  @override
  List<Object?> get props => [userId, isOnline];
}

class SearchConversationsEvent extends ConversationsEvent {
  final String query;
  const SearchConversationsEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends ConversationsEvent {
  const ClearSearchEvent();
  @override
  List<Object?> get props => [];
}
