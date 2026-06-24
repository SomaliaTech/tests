import '../../domain/entities/chat_message.dart';

abstract class ChatRoomEvent {}

class LoadChatHistoryEvent extends ChatRoomEvent {
  final String partnerId;
  LoadChatHistoryEvent(this.partnerId);
}

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

class UpdatePartnerStatusEvent extends ChatRoomEvent {
  final String userId;
  final bool isOnline;
  UpdatePartnerStatusEvent(this.userId, this.isOnline);
}
