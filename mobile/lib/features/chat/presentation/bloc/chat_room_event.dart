import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();
  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatRoomEvent {
  final String partnerId;
  final String? content;
  final String type;
  final String? mediaUrl;
  const SendMessageEvent(
    this.partnerId,
    this.content,
    this.type,
    this.mediaUrl,
  );
  @override
  List<Object?> get props => [partnerId, content, type, mediaUrl];
}

class ReceiveMessageEvent extends ChatRoomEvent {
  final ChatMessage message;
  const ReceiveMessageEvent(this.message);
  @override
  List<Object?> get props => [message];
}

class LoadChatHistoryEvent extends ChatRoomEvent {
  final String partnerId;
  final bool isOnline;
  const LoadChatHistoryEvent({required this.partnerId, this.isOnline = false});
  @override
  List<Object?> get props => [partnerId, isOnline];
}

class UpdatePartnerStatusEvent extends ChatRoomEvent {
  final String userId;
  final bool isOnline;
  const UpdatePartnerStatusEvent(this.userId, this.isOnline);
  @override
  List<Object?> get props => [userId, isOnline];
}

class PartnerTypingEvent extends ChatRoomEvent {
  final bool isTyping;
  const PartnerTypingEvent(this.isTyping);
  @override
  List<Object?> get props => [isTyping];
}

class UserTypingEvent extends ChatRoomEvent {
  final bool isTyping;
  const UserTypingEvent(this.isTyping);
  @override
  List<Object?> get props => [isTyping];
}

class RefreshChatEvent extends ChatRoomEvent {
  const RefreshChatEvent();
}

class PickAndSendImageEvent extends ChatRoomEvent {
  final String partnerId;
  const PickAndSendImageEvent(this.partnerId);
  @override
  List<Object?> get props => [partnerId];
}

class MarkMessagesAsReadEvent extends ChatRoomEvent {
  const MarkMessagesAsReadEvent();
}

class CameraImageEvent extends ChatRoomEvent {
  final String partnerId;
  const CameraImageEvent(this.partnerId);
  @override
  List<Object?> get props => [partnerId];
}

class CancelImageSelectionEvent extends ChatRoomEvent {
  const CancelImageSelectionEvent();
  @override
  List<Object?> get props => [];
}

// ✅ NEW: Event to instantly update read receipts without network delay
class UpdateReadReceiptsEvent extends ChatRoomEvent {
  const UpdateReadReceiptsEvent();
  @override
  List<Object?> get props => [];
}

// lib/features/chat/presentation/bloc/chat_room_event.dart
// Update SendSelectedImageEvent to accept optional caption
class SendSelectedImageEvent extends ChatRoomEvent {
  final String? caption;
  const SendSelectedImageEvent({this.caption});
  @override
  List<Object?> get props => [caption];
}

// ✅ ADD THIS EVENT
class LoadPartnerInfoEvent extends ChatRoomEvent {
  final String partnerId;
  const LoadPartnerInfoEvent(this.partnerId);

  @override
  List<Object?> get props => [partnerId];
}
