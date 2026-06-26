import '../../domain/entities/chat_message.dart';

abstract class ChatRoomEvent {}

class SendMessageEvent extends ChatRoomEvent {
  final String partnerId;
  final String? content;
  final String type;
  final String? mediaUrl;

  SendMessageEvent(this.partnerId, this.content, this.type, this.mediaUrl);
}

class ReceiveMessageEvent extends ChatRoomEvent {
  final ChatMessage message;
  ReceiveMessageEvent(this.message);
}

class LoadChatHistoryEvent extends ChatRoomEvent {
  final String partnerId;
  final bool isOnline; // 🚨 ADDED

  // 🚨 CHANGED: Added optional named parameter
  LoadChatHistoryEvent(this.partnerId, {this.isOnline = false});

  @override
  List<Object?> get props => [partnerId, isOnline];
}

class UpdatePartnerStatusEvent extends ChatRoomEvent {
  final String userId;
  final bool isOnline;
  UpdatePartnerStatusEvent(this.userId, this.isOnline);
}
