import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/features/chat/domain/entities/chat_user.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<Conversation>> getConversations();
  Future<List<ChatUser>> getAdminUsersForChat();
  // 🚨 ADD THIS: Search method in abstract interface
  Future<List<Conversation>> searchConversations(String query);

  Future<List<ChatMessage>> getMessages(String partnerId, {int limit = 50});
  Future<ChatMessage> sendMessage({
    required String receiverId,
    String? content,
    String type = 'text',
    String? mediaUrl,
  });
  Future<void> markAsRead(String partnerId);
  Future<List<Map<String, dynamic>>> getAvailableAdmins();
  Future<Map<String, dynamic>> createConversation(String participantId);
  Future<Map<String, dynamic>> getUnreadCount();

  Future<Map<String, dynamic>> getAllConversations({
    int page = 1,
    String? search,
  });
  Future<List<ChatMessage>> getConversationMessages(
    String conversationId, {
    int limit = 50,
  });

  Future<List<dynamic>> getUsersForAdmin(String adminId, {String? search});
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  ChatRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  // 🚨 FIX: Use _getHeaders() instead of _getToken()
  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final headers = await _getHeaders();
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/chat/search?q=${Uri.encodeComponent(query)}&limit=20',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => ConversationModel.fromJson(json))
            .toList();
      } else {
        throw ServerException('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const UnauthorizedException('Token not found');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableAdmins() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/chat/admins'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw ServerException('Failed to load admins: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> getAllConversations({
    int page = 1,
    String? search,
  }) async {
    final headers = await _getHeaders();
    String url =
        '${ApiConstants.baseUrl}/chat/admin/all-conversations?page=$page&limit=20';
    if (search != null && search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw ServerException('Failed: ${response.statusCode}');
    }
  }

  @override
  Future<List<ChatMessage>> getConversationMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/chat/admin/conversation/$conversationId/messages?limit=$limit',
      ),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ChatMessageModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> createConversation(String participantId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/chat/conversations'),
      headers: headers,
      body: json.encode({'participantId': participantId}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ServerException(
        'Failed to create conversation: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<Conversation>> getConversations() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/chat/conversations'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ConversationModel.fromJson(json)).toList();
    } else {
      throw ServerException(
        'Failed to load conversations: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String partnerId, {
    int limit = 50,
  }) async {
    if (partnerId.isEmpty) {
      return [];
    }

    final headers = await _getHeaders();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/chat/messages/$partnerId?limit=$limit',
    );

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ChatMessageModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw ServerException('Failed to load messages: ${response.statusCode}');
    }
  }

  @override
  Future<ChatMessage> sendMessage({
    required String receiverId,
    String? content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final headers = await _getHeaders();
    final body = {
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/chat/messages'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return ChatMessageModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to send message: ${response.statusCode}');
    }
  }

  @override
  Future<void> markAsRead(String partnerId) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/chat/messages/$partnerId/read'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw ServerException('Failed to mark as read: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> getUnreadCount() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/chat/messages/unread/count'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ServerException(
        'Failed to get unread count: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<ChatUser>> getAdminUsersForChat() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/chat/admins/chat'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ChatUser.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load admins: ${response.statusCode}');
    }
  }

  @override
  Future<List<dynamic>> getUsersForAdmin(
    String adminId, {
    String? search,
  }) async {
    final headers = await _getHeaders();
    String url = '${ApiConstants.baseUrl}/chat/admin/$adminId/users';
    if (search != null && search.isNotEmpty) {
      url += '?search=${Uri.encodeComponent(search)}';
    }
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw ServerException('Failed: ${response.statusCode}');
    }
  }
}
