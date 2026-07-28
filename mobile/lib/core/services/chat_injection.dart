import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chat/domain/usecases/get_chat_history.dart';
import 'package:mobile/features/chat/domain/usecases/get_conversations.dart';
import 'package:mobile/features/chat/domain/usecases/mark_as_read.dart' as chat;
import 'package:mobile/features/chat/domain/usecases/search_conversations.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_bloc.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_bloc.dart';
import 'package:mobile/core/services/chat_socket_service.dart';

final GetIt sl = GetIt.instance;
final Logger _logger = Logger();

void registerChatDependencies() {
  _logger.i('📦 Registering Chat Dependencies...');

  // Core Services
  if (!sl.isRegistered<ChatSocketService>()) {
    sl.registerLazySingleton<ChatSocketService>(() => ChatSocketService());
    _logger.i('✅ ChatSocketService registered');
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

  // ✅ REGISTER ChatLocalDataSource ONLY ONCE
  if (!sl.isRegistered<ChatLocalDataSource>()) {
    sl.registerLazySingleton<ChatLocalDataSource>(
      () => ChatLocalDataSourceImpl(),
    );
    _logger.i('✅ ChatLocalDataSource registered');
  }

  // Repositories
  if (!sl.isRegistered<ChatRepository>()) {
    sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: sl<ChatRemoteDataSource>(),
        localDataSource: sl<ChatLocalDataSource>(),
        storageService: sl<StorageService>(),
      ),
    );
    _logger.i('✅ ChatRepository registered');
  }

  // Use Cases
  if (!sl.isRegistered<GetConversations>()) {
    sl.registerLazySingleton<GetConversations>(
      () => GetConversations(sl<ChatRepository>()),
    );
    _logger.i('✅ GetConversations registered');
  }

  if (!sl.isRegistered<GetChatHistory>()) {
    sl.registerLazySingleton<GetChatHistory>(
      () => GetChatHistory(sl<ChatRepository>()),
    );
    _logger.i('✅ GetChatHistory registered');
  }

  if (!sl.isRegistered<chat.MarkAsRead>()) {
    sl.registerLazySingleton<chat.MarkAsRead>(
      () => chat.MarkAsRead(sl<ChatRepository>()),
    );
    _logger.i('✅ MarkAsRead registered');
  }

  if (!sl.isRegistered<SearchConversations>()) {
    sl.registerLazySingleton<SearchConversations>(
      () => SearchConversations(sl<ChatRepository>()),
    );
    _logger.i('✅ SearchConversations registered');
  }

  // BLoCs
  // In your registration function
  if (!sl.isRegistered<ConversationsBloc>()) {
    sl.registerLazySingleton(
      () => ConversationsBloc(
        getConversations: sl<GetConversations>(),
        searchConversations: sl<SearchConversations>(),
        socketService: sl<ChatSocketService>(),
        localDataSource: sl<ChatLocalDataSource>(), // ✅ ADD THIS
      ),
    );
  }
  // ✅ ChatRoomBloc - registered as factory (new instance each time)
  // No need to check isRegistered since it's a factory
  sl.registerFactory<ChatRoomBloc>(
    () => ChatRoomBloc(
      getChatHistory: sl<GetChatHistory>(),
      markAsRead: sl<chat.MarkAsRead>(),
      socketService: sl<ChatSocketService>(),
      localDataSource: sl<ChatLocalDataSource>(),
    ),
  );
  _logger.i('✅ ChatRoomBloc registered as factory');

  _logger.i('✅ Chat Dependencies Registered');
}
