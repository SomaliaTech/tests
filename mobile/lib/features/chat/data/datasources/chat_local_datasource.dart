// lib/features/chat/data/datasources/chat_local_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';

abstract class ChatLocalDataSource {
  Future<List<Conversation>> getCachedConversations();
  Future<void> cacheConversations(List<Conversation> conversations);
  Future<void> updateConversation(Conversation conversation);
  Future<void> clearConversations();

  Future<List<ChatMessage>> getCachedMessages(String partnerId);
  Future<void> cacheMessages(String partnerId, List<ChatMessage> messages);
  Future<void> addMessage(String partnerId, ChatMessage message);
  Future<void> clearMessages(String partnerId);

  Future<DateTime?> getLastSyncTime(String key);
  Future<void> setLastSyncTime(String key, DateTime time);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String _conversationsBoxName = 'conversations_cache';
  static const String _messagesBoxName = 'messages_cache';
  static const String _syncBoxName = 'sync_timestamps';

  // ✅ Use Hive.box() since boxes are already open from main.dart
  Box<String> get _conversationsBox => Hive.box<String>(_conversationsBoxName);
  Box<String> get _messagesBox => Hive.box<String>(_messagesBoxName);
  Box<String> get _syncBox => Hive.box<String>(_syncBoxName);

  @override
  Future<List<Conversation>> getCachedConversations() async {
    try {
      final jsonString = _conversationsBox.get('conversations_list');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final conversations = jsonList
            .map(
              (json) =>
                  ConversationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        // ✅ DEDUPLICATE
        final seenIds = <String>{};
        final uniqueConversations = <Conversation>[];

        for (final conv in conversations) {
          if (!seenIds.contains(conv.partnerId)) {
            seenIds.add(conv.partnerId);
            uniqueConversations.add(conv);
          }
        }

        return uniqueConversations;
      }
    } catch (e) {
      debugPrint('❌ Error reading cached conversations: $e');
    }
    return [];
  }

  @override
  Future<void> cacheConversations(List<Conversation> conversations) async {
    try {
      // ✅ DEDUPLICATE before caching
      final seenIds = <String>{};
      final uniqueConversations = <Conversation>[];

      for (final conv in conversations) {
        if (!seenIds.contains(conv.partnerId)) {
          seenIds.add(conv.partnerId);
          uniqueConversations.add(conv);
        }
      }

      final jsonList = uniqueConversations
          .map(
            (c) => {
              'userId': c.partnerId,
              'name': c.partnerName,
              'profileImage': c.partnerImage,
              'isOnline': c.isOnline,
              'lastMessage': c.lastMessage,
              'lastMessageType': c.lastMessageType,
              'lastMessageTime': c.lastMessageTime.toIso8601String(),
              'unreadCount': c.unreadCount,
            },
          )
          .toList();

      await _conversationsBox.put('conversations_list', json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching conversations: $e');
    }
  }

  @override
  Future<void> updateConversation(Conversation conversation) async {
    try {
      final conversations = await getCachedConversations();
      final index = conversations.indexWhere(
        (c) => c.partnerId == conversation.partnerId,
      );

      if (index != -1) {
        conversations[index] = conversation;
      } else {
        conversations.insert(0, conversation);
      }

      await cacheConversations(conversations);
    } catch (e) {
      debugPrint('❌ Error updating conversation: $e');
    }
  }

  @override
  Future<void> clearConversations() async {
    await _conversationsBox.delete('conversations_list');
  }

  @override
  Future<List<ChatMessage>> getCachedMessages(String partnerId) async {
    try {
      final jsonString = _messagesBox.get('messages_$partnerId');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map(
              (json) => ChatMessageModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error reading cached messages for $partnerId: $e');
    }
    return [];
  }

  @override
  Future<void> cacheMessages(
    String partnerId,
    List<ChatMessage> messages,
  ) async {
    try {
      final jsonList = messages.map((m) {
        // ✅ Convert to a plain Map regardless of whether it's ChatMessage or ChatMessageModel
        return {
          'id': m.id,
          'senderId': m.senderId,
          'receiverId': m.receiverId,
          'content': m.content,
          'type': m.type,
          'mediaUrl': m.mediaUrl,
          'isRead': m.isRead,
          'createdAt': m.createdAt.toUtc().toIso8601String(),
          'senderName': m.senderName,
        };
      }).toList();

      await _messagesBox.put('messages_$partnerId', json.encode(jsonList));
      debugPrint('✅ Cached ${messages.length} messages for $partnerId');
    } catch (e) {
      debugPrint('❌ Error caching messages for $partnerId: $e');
    }
  }

  @override
  Future<void> addMessage(String partnerId, ChatMessage message) async {
    try {
      // Read the raw JSON string directly to avoid type conflicts
      final jsonString = _messagesBox.get('messages_$partnerId');
      List<dynamic> messagesList = [];

      if (jsonString != null && jsonString.isNotEmpty) {
        messagesList = json.decode(jsonString) as List<dynamic>;
      }

      // Convert message to JSON map
      final messageJson = {
        'id': message.id,
        'senderId': message.senderId,
        'receiverId': message.receiverId,
        'content': message.content,
        'type': message.type,
        'mediaUrl': message.mediaUrl,
        'isRead': message.isRead,
        'createdAt': message.createdAt.toUtc().toIso8601String(),
        'senderName': message.senderName,
      };

      // Remove duplicate temp messages
      messagesList.removeWhere((item) {
        final m = item as Map<String, dynamic>;
        return (m['id'] as String).startsWith('temp_') &&
            m['content'] == message.content &&
            m['senderId'] == message.senderId;
      });

      // Update existing or add new
      final index = messagesList.indexWhere((item) {
        final m = item as Map<String, dynamic>;
        return m['id'] == message.id;
      });

      if (index != -1) {
        messagesList[index] = messageJson;
      } else {
        messagesList.insert(0, messageJson);
      }

      // Limit cache size to 100 messages per conversation
      if (messagesList.length > 100) {
        messagesList = messagesList.sublist(0, 100);
      }

      // Save back to storage
      await _messagesBox.put('messages_$partnerId', json.encode(messagesList));

      debugPrint('✅ Message saved to cache: ${message.id} for $partnerId');
    } catch (e) {
      debugPrint('❌ Error adding message for $partnerId: $e');
    }
  }

  @override
  Future<void> clearMessages(String partnerId) async {
    await _messagesBox.delete('messages_$partnerId');
  }

  @override
  Future<DateTime?> getLastSyncTime(String key) async {
    try {
      final timestamp = _syncBox.get(key);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      debugPrint('❌ Error reading sync time: $e');
    }
    return null;
  }

  @override
  Future<void> setLastSyncTime(String key, DateTime time) async {
    await _syncBox.put(key, time.toIso8601String());
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _conversationsBox.clear();
    await _messagesBox.clear();
    await _syncBox.clear();
  }

  /// Get approximate cache size in bytes
  Future<int> getCacheSize() async {
    int size = 0;

    for (final value in _conversationsBox.values) {
      size += value.length;
    }
    for (final value in _messagesBox.values) {
      size += value.length;
    }

    return size;
  }
}
