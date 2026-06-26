import '../../domain/entities/chat_message.dart';

abstract class ChatRoomState {}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<ChatMessage> messages;
  final bool isPartnerOnline;

  // 🚨 CRITICAL FIX: Added {} and 'required' to make them named parameters
  ChatRoomLoaded({required this.messages, required this.isPartnerOnline});
}

class ChatRoomError extends ChatRoomState {
  final String message;
  ChatRoomError(this.message);
}
