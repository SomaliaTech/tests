// lib/features/chat/domain/usecases/get_admin_users.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_user.dart';
import '../repositories/chat_repository.dart';

class GetAdminUsers {
  final ChatRepository repository;

  GetAdminUsers(this.repository);

  Future<Either<Failure, List<ChatUser>>> call() async {
    return await repository.getAdminUsersForChat();
  }
}
