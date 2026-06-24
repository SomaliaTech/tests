// File: lib/features/chat/presentation/bloc/chat_room_state.dart
import '../../domain/entities/chat_message.dart';

abstract class ChatRoomState {}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<ChatMessage> messages;
  final bool isPartnerOnline;

  ChatRoomLoaded({required this.messages, required this.isPartnerOnline});
}

class ChatRoomError extends ChatRoomState {
  final String message;
  ChatRoomError(this.message);
}
