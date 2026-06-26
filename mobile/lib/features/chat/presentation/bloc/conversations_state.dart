import 'package:equatable/equatable.dart';
import 'package:mobile/features/chat/domain/entities/conversation.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();
  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {}

class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  final int _updateCount; // ✅ Forces different state each time

  ConversationsLoaded(this.conversations) : _updateCount = _counter++;

  static int _counter = 0;

  @override
  List<Object?> get props => [conversations, _updateCount];
}

class ConversationsError extends ConversationsState {
  final String message;
  const ConversationsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ConversationsSearchResults extends ConversationsState {
  final List<Conversation> conversations;
  final String query;
  const ConversationsSearchResults(this.conversations, this.query);
  @override
  List<Object?> get props => [conversations, query];
}
