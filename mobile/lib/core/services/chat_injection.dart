import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chat/domain/usecases/get_chat_history.dart';
import 'package:mobile/features/chat/domain/usecases/get_conversations.dart';
import 'package:mobile/features/chat/domain/usecases/mark_as_read.dart' as chat;
import 'package:mobile/features/chat/presentation/bloc/chat_room_bloc.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_bloc.dart';
import 'package:mobile/core/services/chat_socket_service.dart';

final GetIt sl = GetIt.instance;

void registerChatDependencies() {
  print('📦 Registering Chat Dependencies...');

  // Core Services - Register socket service FIRST
  if (!sl.isRegistered<ChatSocketService>()) {
    sl.registerLazySingleton<ChatSocketService>(() => ChatSocketService());
    print('✅ ChatSocketService registered');
  }

  // Data Sources
  if (!sl.isRegistered<ChatRemoteDataSource>()) {
    sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(
        client: sl<http.Client>(),
        storageService: sl<StorageService>(),
      ),
    );
  }

  // Repositories
  if (!sl.isRegistered<ChatRepository>()) {
    sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: sl<ChatRemoteDataSource>()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetConversations>()) {
    sl.registerLazySingleton(() => GetConversations(sl<ChatRepository>()));
  }
  if (!sl.isRegistered<GetChatHistory>()) {
    sl.registerLazySingleton(() => GetChatHistory(sl<ChatRepository>()));
  }
  if (!sl.isRegistered<chat.MarkAsRead>()) {
    sl.registerLazySingleton(() => chat.MarkAsRead(sl<ChatRepository>()));
  }

  // BLoCs
  if (!sl.isRegistered<ConversationsBloc>()) {
    sl.registerFactory(
      () => ConversationsBloc(
        getConversations: sl<GetConversations>(),
        socketService: sl<ChatSocketService>(),
      ),
    );
  }

  if (!sl.isRegistered<ChatRoomBloc>()) {
    sl.registerFactory(
      () => ChatRoomBloc(
        getChatHistory: sl<GetChatHistory>(),
        markAsRead: sl<chat.MarkAsRead>(),
        socketService: sl<ChatSocketService>(),
      ),
    );
  }

  print('✅ Chat Dependencies Registered');
}
