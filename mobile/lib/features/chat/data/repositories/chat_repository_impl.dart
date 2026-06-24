import 'package:fpdart/fpdart.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

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
  ResultFuture<List<ChatMessage>> getChatHistory(String partnerId) async {
    try {
      final history = await remoteDataSource.getChatHistory(partnerId);
      return Right(history);
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
}
