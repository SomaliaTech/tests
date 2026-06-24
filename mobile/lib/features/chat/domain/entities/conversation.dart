import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String partnerId;
  final String partnerName;
  final String? partnerImage;
  final bool isOnline;
  final String? lastMessage;
  final String lastMessageType;
  final DateTime lastMessageTime;
  final int unreadCount;

  const Conversation({
    required this.partnerId,
    required this.partnerName,
    this.partnerImage,
    required this.isOnline,
    this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [
    partnerId,
    partnerName,
    partnerImage,
    isOnline,
    lastMessage,
    lastMessageType,
    lastMessageTime,
    unreadCount,
  ];
}
