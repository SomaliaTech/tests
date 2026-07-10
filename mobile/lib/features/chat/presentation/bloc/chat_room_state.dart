import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatRoomState extends Equatable {
  const ChatRoomState();
  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomError extends ChatRoomState {
  final String message;
  const ChatRoomError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatRoomImageSelected extends ChatRoomState {
  final XFile image;
  final bool isPartnerOnline;
  final bool isPartnerTyping;

  const ChatRoomImageSelected({
    required this.image,
    required this.isPartnerOnline,
    this.isPartnerTyping = false,
  });

  @override
  List<Object?> get props => [image, isPartnerOnline, isPartnerTyping];
}

// ✅ UPDATED: Added XFile so we can show the thumbnail while uploading
class ChatRoomImageUploading extends ChatRoomState {
  final XFile image;
  final bool isPartnerOnline;
  final bool isPartnerTyping;

  const ChatRoomImageUploading({
    required this.image,
    required this.isPartnerOnline,
    this.isPartnerTyping = false,
  });

  @override
  List<Object?> get props => [image, isPartnerOnline, isPartnerTyping];
}

// lib/features/chat/presentation/bloc/chat_room_state.dart
class ChatRoomLoaded extends ChatRoomState {
  final List<ChatMessage> messages;
  final bool isPartnerOnline;
  final bool isPartnerTyping;
  final String? currentUserId;
  final bool isHistoryLoaded;
  final String? partnerName; // ✅ Add this field

  const ChatRoomLoaded({
    required this.messages,
    required this.isPartnerOnline,
    this.isPartnerTyping = false,
    this.currentUserId,
    this.isHistoryLoaded = false,
    this.partnerName, // ✅ Add this
  });

  // ✅ ADD THIS METHOD
  ChatRoomLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isPartnerOnline,
    bool? isPartnerTyping,
    String? currentUserId,
    bool? isHistoryLoaded,
    String? partnerName,
  }) {
    return ChatRoomLoaded(
      messages: messages ?? this.messages,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      currentUserId: currentUserId ?? this.currentUserId,
      isHistoryLoaded: isHistoryLoaded ?? this.isHistoryLoaded,
      partnerName: partnerName ?? this.partnerName,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isPartnerOnline,
    isPartnerTyping,
    currentUserId,
    isHistoryLoaded,
    partnerName,
  ];
}
