import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<void> call({
    required String receiverId,
    required String? content,
    required String type,
    required String? mediaUrl,
  }) async {
    // This is handled by socket, but you can add HTTP fallback here
    // For now, just return as messages are sent via socket
    return;
  }
}
