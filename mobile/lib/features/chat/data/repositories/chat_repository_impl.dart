// lib/features/chat/data/repositories/chat_repository_impl.dart
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/utils/typedefs.dart';
import 'package:mobile/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chat/data/models/conversation_model.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/entities/chat_user.dart';
import 'package:mobile/features/chat/domain/entities/conversation.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;
  final StorageService storageService;
  final StreamController<List<Conversation>> _conversationUpdateController =
      StreamController<List<Conversation>>.broadcast();

  @override
  Stream<List<Conversation>> get conversationUpdates =>
      _conversationUpdateController.stream;
  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.storageService,
  });

  @override
  ResultFuture<List<Conversation>> getConversations() async {
    try {
      final cachedConversations = await localDataSource
          .getCachedConversations();

      if (cachedConversations.isNotEmpty) {
        _refreshConversationsInBackground();
        return Right(cachedConversations);
      }

      try {
        final remoteConversations = await remoteDataSource.getConversations();
        await localDataSource.cacheConversations(remoteConversations);
        return Right(remoteConversations);
      } catch (e) {
        return Left(ServerFailure('Failed to load conversations'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Background refresh - doesn't block UI
  Future<void> _refreshConversationsInBackground() async {
    try {
      final remoteConversations = await remoteDataSource.getConversations();
      final cachedConversations = await localDataSource
          .getCachedConversations();
      final mergedConversations = _mergeConversations(
        cachedConversations,
        remoteConversations,
      );
      await localDataSource.cacheConversations(mergedConversations);

      // ✅ ADD THIS: Notify listeners that cache was updated
      _conversationUpdateController.add(mergedConversations);
    } catch (e) {
      debugPrint('Background conversation refresh failed: $e');
    }
  }

  @override
  ResultFuture<List<ChatMessage>> getChatHistory(String partnerId) async {
    try {
      // 🚀 STEP 1: Load cached messages IMMEDIATELY
      final cachedMessages = await localDataSource.getCachedMessages(partnerId);

      // ✅ If we have cached data, return it RIGHT NOW
      if (cachedMessages.isNotEmpty) {
        // Sort by newest first
        cachedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // 🔄 Fetch fresh data in background (don't wait for it)
        _refreshMessagesInBackground(partnerId);

        // Return cached data immediately
        return Right(cachedMessages);
      }

      // 🚀 STEP 2: No cache - fetch from network
      try {
        final remoteMessages = await remoteDataSource.getMessages(partnerId);

        // Cache for next time
        await localDataSource.cacheMessages(partnerId, remoteMessages);

        return Right(remoteMessages);
      } catch (e) {
        // Network failed and no cache
        return Left(ServerFailure('Failed to load messages'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Background message refresh - doesn't block UI
  Future<void> _refreshMessagesInBackground(String partnerId) async {
    try {
      final remoteMessages = await remoteDataSource.getMessages(partnerId);

      if (remoteMessages.isNotEmpty) {
        // Merge with existing cache
        final cachedMessages = await localDataSource.getCachedMessages(
          partnerId,
        );
        final mergedMessages = _mergeMessages(cachedMessages, remoteMessages);

        // Update cache
        await localDataSource.cacheMessages(partnerId, mergedMessages);

        // 🔔 Notify UI about new data (if you have a notification mechanism)
        // You could use a stream or callback here to update the UI
      }
    } catch (e) {
      // Silently fail - we already showed cached data
      debugPrint('Background message refresh failed for $partnerId: $e');
    }
  }

  @override
  ResultFuture<List<Conversation>> searchConversations(String query) async {
    try {
      final conversations = await remoteDataSource.searchConversations(query);
      await localDataSource.cacheConversations(conversations);
      return Right(conversations);
    } on ServerException catch (e) {
      try {
        final cached = await localDataSource.getCachedConversations();
        final filtered = cached
            .where(
              (c) => c.partnerName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        return Right(filtered);
      } catch (_) {
        return Left(ServerFailure(e.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> markAsRead(String partnerId) async {
    try {
      await remoteDataSource.markAsRead(partnerId);

      // Update local cache
      final messages = await localDataSource.getCachedMessages(partnerId);
      final updatedMessages = messages.map((m) {
        if (m.senderId == partnerId && !m.isRead) {
          return m.copyWith(isRead: true);
        }
        return m;
      }).toList();
      await localDataSource.cacheMessages(partnerId, updatedMessages);

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

      // Refresh cache in background
      _refreshConversationsInBackground();

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

      // Cache the sent message locally
      await localDataSource.addMessage(receiverId, message);

      // Update conversation cache
      await _updateConversationCache(
        receiverId,
        content,
        type,
        message.createdAt,
      );

      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _updateConversationCache(
    String partnerId,
    String? content,
    String type,
    DateTime messageTime,
  ) async {
    try {
      final conversations = await localDataSource.getCachedConversations();
      final index = conversations.indexWhere((c) => c.partnerId == partnerId);

      if (index != -1) {
        final updatedConv = ConversationModel(
          partnerId: conversations[index].partnerId,
          partnerName: conversations[index].partnerName,
          partnerImage: conversations[index].partnerImage,
          isOnline: conversations[index].isOnline,
          lastMessage: type == 'image' ? '📷 Photo' : content,
          lastMessageType: type,
          lastMessageTime: messageTime,
          unreadCount: conversations[index].unreadCount,
        );
        await localDataSource.updateConversation(updatedConv);
      }
    } catch (e) {
      debugPrint('Failed to update conversation cache: $e');
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> getUnreadCount() async {
    try {
      final result = await remoteDataSource.getUnreadCount();
      return Right(result);
    } on ServerException catch (e) {
      try {
        final conversations = await localDataSource.getCachedConversations();
        final totalUnread = conversations.fold<int>(
          0,
          (sum, c) => sum + c.unreadCount,
        );
        return Right({'total': totalUnread});
      } catch (_) {
        return Left(ServerFailure(e.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatUser>>> getAdminUsersForChat() async {
    try {
      final token = await storageService.getAuthToken();
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

  // Helper methods
  List<Conversation> _mergeConversations(
    List<Conversation> cached,
    List<Conversation> remote,
  ) {
    final Map<String, Conversation> merged = {};

    // 1. Remote is the source of truth for WHICH conversations exist
    for (final conv in remote) {
      merged[conv.partnerId] = conv;
    }

    // 2. Check cache for newer local updates (e.g. user just sent a message)
    for (final conv in cached) {
      final remoteConv = merged[conv.partnerId];

      // ✅ CRITICAL FIX: If it's in cache but NOT in remote, the user was deleted.
      // DO NOT add it to merged. This drops ghost users from the list automatically!
      if (remoteConv == null) {
        continue;
      }

      // If cache has a newer message than remote, use the cached version
      if (conv.lastMessageTime.isAfter(remoteConv.lastMessageTime)) {
        merged[conv.partnerId] = conv;
      }
    }

    final result = merged.values.toList();
    result.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return result;
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> cached,
    List<ChatMessage> remote,
  ) {
    final Map<String, ChatMessage> merged = {};

    // Add cached messages first
    for (final msg in cached) {
      merged[msg.id] = msg;
    }

    // Override/Add remote messages (but preserve temp messages)
    for (final msg in remote) {
      if (!merged.containsKey(msg.id) || !msg.id.startsWith('temp_')) {
        merged[msg.id] = msg;
      }
    }

    // Remove temp messages that have been confirmed by server
    final tempIds = cached
        .where((m) => m.id.startsWith('temp_'))
        .map((m) => m.id)
        .toSet();

    for (final tempId in tempIds) {
      final tempMsg = merged[tempId];
      if (tempMsg != null) {
        final serverMsg = remote.where(
          (m) =>
              !m.id.startsWith('temp_') &&
              m.content == tempMsg.content &&
              m.senderId == tempMsg.senderId &&
              m.receiverId == tempMsg.receiverId,
        );

        if (serverMsg.isNotEmpty) {
          merged.remove(tempId);
        }
      }
    }

    // Sort by timestamp (newest first)
    final result = merged.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  // Add import for debugPrint
  static void debugPrint(String message) {
    // if (kDebugMode) {
    // }
    print(message);
  }

  void dispose() {
    _conversationUpdateController.close();
  }
}
