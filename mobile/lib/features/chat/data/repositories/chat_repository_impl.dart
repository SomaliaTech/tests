import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/services/storage/storage_service.dart'; // ✅ Add import
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chat/domain/entities/chat_user.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final StorageService storageService; // ✅ Add this field

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService, // ✅ Add this parameter
  });

  @override
  ResultFuture<List<Conversation>> getConversations() async {
    try {
      final conversations = await remoteDataSource.getConversations();
      return Right(conversations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<Conversation>> searchConversations(String query) async {
    try {
      final conversations = await remoteDataSource.searchConversations(query);
      return Right(conversations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ChatMessage>> getChatHistory(String partnerId) async {
    try {
      final messages = await remoteDataSource.getMessages(partnerId);
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> markAsRead(String partnerId) async {
    try {
      await remoteDataSource.markAsRead(partnerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<Map<String, dynamic>>> getAvailableAdmins() async {
    try {
      final admins = await remoteDataSource.getAvailableAdmins();
      return Right(admins);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> createConversation(
    String participantId,
  ) async {
    try {
      final result = await remoteDataSource.createConversation(participantId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ChatMessage> sendMessage({
    required String receiverId,
    String? content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        receiverId: receiverId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
      );
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> getUnreadCount() async {
    try {
      final result = await remoteDataSource.getUnreadCount();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatUser>>> getAdminUsersForChat() async {
    try {
      final token = await storageService.getAuthToken(); // ✅ Now works
      if (token == null) {
        return Left(ServerFailure('No token found'));
      }

      final users = await remoteDataSource.getAdminUsersForChat();
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get admins: $e'));
    }
  }
}
