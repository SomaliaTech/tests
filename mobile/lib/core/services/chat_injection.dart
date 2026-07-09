import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart'; // Add logger package
import 'package:mobile/core/services/storage/storage_service.dart';
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

  // Repositories
  // In chat_injection.dart or wherever you register ChatRepositoryImpl
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl<ChatRemoteDataSource>(),
      storageService: sl<StorageService>(), // ✅ Add this
    ),
  );

  // Use Cases
  if (!sl.isRegistered<GetConversations>()) {
    sl.registerLazySingleton<GetConversations>(
      () => GetConversations(sl<ChatRepository>()),
    );
  }
  if (!sl.isRegistered<GetChatHistory>()) {
    sl.registerLazySingleton<GetChatHistory>(
      () => GetChatHistory(sl<ChatRepository>()),
    );
  }
  if (!sl.isRegistered<chat.MarkAsRead>()) {
    sl.registerLazySingleton<chat.MarkAsRead>(
      () => chat.MarkAsRead(sl<ChatRepository>()),
    );
  }
  if (!sl.isRegistered<SearchConversations>()) {
    sl.registerLazySingleton(() => SearchConversations(sl<ChatRepository>()));
  }
  // BLoCs
  if (!sl.isRegistered<ConversationsBloc>()) {
    sl.registerLazySingleton(
      () => ConversationsBloc(
        getConversations: sl<GetConversations>(),
        searchConversations: sl<SearchConversations>(),
        socketService: sl<ChatSocketService>(),
      ),
    );
  }
  // ✅ FIX: Removed 'dataSource' parameter
  // In chat_injection.dart
  if (!sl.isRegistered<ChatRoomBloc>()) {
    sl.registerFactory(
      () => ChatRoomBloc(
        getChatHistory: sl<GetChatHistory>(),
        markAsRead: sl<chat.MarkAsRead>(),
        socketService: sl<ChatSocketService>(),
      ),
    );
  }

  _logger.i('✅ Chat Dependencies Registered');
}
