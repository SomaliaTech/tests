// lib/features/chat/presentation/bloc/conversations_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();
  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {}

class ConversationsError extends ConversationsState {
  final String message;
  const ConversationsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  const ConversationsLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class ConversationsSearchResults extends ConversationsState {
  final List<Conversation> conversations;
  final String query;
  const ConversationsSearchResults(this.conversations, this.query);
  @override
  List<Object?> get props => [conversations, query];
}
