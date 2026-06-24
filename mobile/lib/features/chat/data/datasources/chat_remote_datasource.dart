import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<Conversation>> getConversations();
  Future<List<ChatMessage>> getChatHistory(String partnerId);
  Future<void> markAsRead(String partnerId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  ChatRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const UnauthorizedException('Token not found');
    return token;
  }

  @override
  Future<List<Conversation>> getConversations() async {
    final token = await _getToken();
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => ConversationModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          'Failed to load conversations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String partnerId) async {
    final token = await _getToken();
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/history/$partnerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ChatMessageModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load chat history: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<void> markAsRead(String partnerId) async {
    final token = await _getToken();
    try {
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/chat/mark-read/$partnerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to mark messages as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);
}
