import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/foundation.dart';

class ChatSocketService {
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false; // ✅ ADD THIS
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _userId;

  final StorageService _storageService = GetIt.instance<StorageService>();
  final Logger _logger = Logger();

  // Stream controllers
  final _newMessageController = StreamController<ChatMessage>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageSentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _partnerStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _newOrderController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _roleChangeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _userDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  Stream<ChatMessage> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onStatusChange => _statusController.stream;
  Stream<Map<String, dynamic>> get onMessageSent =>
      _messageSentController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;
  Stream<Map<String, dynamic>> get onPartnerStatus =>
      _partnerStatusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<Map<String, dynamic>> get onNewNotification =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get onMessageRead =>
      _messageReadController.stream;
  Stream<Map<String, dynamic>> get onNewOrder => _newOrderController.stream;
  Stream<Map<String, dynamic>> get onRoleChange => _roleChangeController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  bool get isConnected => _isConnected;
  String? get userId => _userId;
  Stream<Map<String, dynamic>> get onUserDeleted =>
      _userDeletedController.stream;

  Future<void> connect() async {
    try {
      // Block if already connected
      if (_socket?.connected == true) {
        _logger.i('✅ [WS] Already connected');
        return;
      }

      // Block if connection in progress
      if (_isConnecting) {
        _logger.i('⏳ [WS] Connection in progress');
        return;
      }

      _isConnecting = true;

      final token = await _storageService.getAuthToken();
      if (token == null) {
        _logger.w('❌ [WS] No token found');
        _isConnecting = false;
        _errorController.add('Authentication token not found');
        return;
      }

      // Clean up only if socket exists but is NOT connected
      if (_socket != null && !_socket!.connected) {
        await _cleanupSocket();
      }

      _reconnectAttempts = 0;

      final wsUrl = ApiConstants.wsUrl;
      _logger.i('🔌 [WS] Connecting to: $wsUrl/chat');

      _socket = io.io(
        '$wsUrl/chat',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setTimeout(20000)
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(3000)
            .setReconnectionDelayMax(15000)
            .build(),
      );

      // ✅ FIXED: Use proper parameter names instead of _
      _socket!.onConnect((dynamic data) {
        _isConnecting = false;
        _onConnect(data);
      });

      _socket!.onConnectError((dynamic error) {
        _isConnecting = false;
        _onConnectError(error);
      });

      _socket!.onDisconnect((dynamic reason) {
        _onDisconnect(reason);
      });

      _socket!.onReconnect((dynamic attempt) {
        _isConnecting = false;
        _onReconnect(attempt);
      });

      _socket!.onReconnectFailed((dynamic data) {
        _isConnecting = false;
        _onReconnectFailed(data);
      });

      _socket!.onReconnectError((dynamic error) {
        _isConnecting = false;
        _onReconnectError(error);
      });

      _socket!.connect();
    } catch (e) {
      _isConnecting = false;
      _logger.e('❌ [WS] Connection setup failed: $e');
      _errorController.add('Connection setup failed: $e');
      _scheduleReconnect();
    }
  }

  void sendTypingEvent(String receiverId, bool isTyping) {
    if (_isConnected) {
      _socket?.emit('typing', {'receiverId': receiverId, 'isTyping': isTyping});
    }
  }

  // ✅ FIXED: Use proper parameter names
  void _onConnect(dynamic data) {
    _isConnected = true;
    _reconnectAttempts = 0;
    _logger.i('🟢 [WS] Connected - Socket ID: ${_socket!.id}');
    _connectionController.add(true);
    _setupListeners();
    _startHeartbeat();
  }

  void _onConnectError(dynamic error) {
    _isConnected = false;
    _logger.e('🔴 [WS] Connection error: $error');
    _connectionController.add(false);
    _errorController.add('Connection failed: $error');
    _scheduleReconnect();
  }

  void _onDisconnect(dynamic reason) {
    _isConnected = false;
    _logger.w('🔴 [WS] Disconnected: $reason');
    _connectionController.add(false);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _onReconnect(dynamic attempt) {
    _isConnected = true;
    _reconnectAttempts = 0;
    _logger.i('🔄 [WS] Reconnected after $attempt attempts');
    _connectionController.add(true);
    _setupListeners();
    _startHeartbeat();
  }

  // ✅ FIXED: Proper parameter name
  void _onReconnectFailed(dynamic data) {
    _isConnected = false;
    _logger.e(
      '❌ [WS] Failed to reconnect after $_maxReconnectAttempts attempts',
    );
    _errorController.add('Failed to reconnect to chat server');
  }

  void _onReconnectError(dynamic error) {
    _logger.e('❌ [WS] Reconnection error: $error');
    _errorController.add('Reconnection error: $error');
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.w('⚠️ [WS] Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: min(3 * (_reconnectAttempts + 1), 30));
    _reconnectAttempts++;

    _logger.i(
      '🔄 [WS] Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  int min(int a, int b) => a < b ? a : b;

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _socket != null) {
        _socket!.emit('heartbeat', {});
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _setupListeners() {
    _logger.i('🔧 [WS] Setting up event listeners...');

    _socket?.on('connected', (data) {
      _logger.i('✅ [WS] Server confirmed connection: $data');
      if (data is Map) {
        _userId = data['userId']?.toString();
        final isAdmin = data['isAdmin'];
        _logger.i('👤 [WS] User: $_userId, Admin: $isAdmin');
      }
    });

    _socket?.on('user_deleted', (data) {
      _logger.i('🗑️ [WS] User deleted notification received: $data');
      if (data is Map) {
        _userDeletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('new_message', (data) {
      _logger.i('📩 [WS] New message received');
      if (data is Map) {
        try {
          final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
          _newMessageController.add(message);
        } catch (e) {
          _logger.e('❌ [WS] Error parsing message: $e');
        }
      }
    });

    _socket?.on('message_sent', (data) {
      _logger.i('✅ [WS] Message sent confirmation');
      if (data is Map) {
        _messageSentController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('partner_status', (data) {
      _logger.i('👥 [WS] Partner status update: $data');
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        _partnerStatusController.add(mapData);
        _statusController.add(mapData);
      }
    });

    _socket?.on('message_read', (data) {
      _logger.i('✅ [WS] Messages marked as read');
      if (data is Map) {
        _messageReadController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('error', (data) {
      _logger.e('❌ [WS] Server error: $data');
      String errorMessage = 'Unknown error';
      if (data is Map && data['message'] != null) {
        errorMessage = data['message'].toString();
      } else if (data is String) {
        errorMessage = data;
      }
      _errorController.add(errorMessage);
    });

    _socket?.on('typing', (data) {
      _logger.i('⌨️ [WS] Typing indicator received');
      if (data is Map) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('new_notification', (data) {
      _logger.i('🔔 [WS] New notification');
      if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('new_order', (data) {
      _logger.i('📦 [WS] New order notification');
      if (data is Map) {
        _newOrderController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('role_changed', (data) {
      debugPrint('🔔 [WS] Role changed: $data');
      _logger.i('🔔 [WS] Role change received: $data');

      if (data is Map) {
        final isAdmin = data['isAdmin'] as bool? ?? false;
        final isSuperAdmin = data['isSuperAdmin'] as bool? ?? false;

        try {
          _storageService.saveIsAdmin(isAdmin);
          _storageService.saveIsSuperAdmin(isSuperAdmin);
          _logger.i('💾 [WS] Updated admin status in storage');
        } catch (e) {
          _logger.e('❌ [WS] Failed to save admin status: $e');
        }

        _roleChangeController.add({
          'isAdmin': isAdmin,
          'isSuperAdmin': isSuperAdmin,
        });

        try {
          final authBloc = GetIt.instance<AuthBloc>();
          authBloc.add(const CheckAuthStatusEvent());
          _logger.i('🔄 [WS] Triggered auth refresh due to role change');
        } catch (e) {
          _logger.e('❌ [WS] Failed to trigger auth refresh: $e');
        }
      }
    });
  }

  void sendMessage({
    required String receiverId,
    String? content,
    String type = 'text',
    String? mediaUrl,
  }) {
    if (!_isConnected) {
      _logger.w('⚠️ [WS] Cannot send - not connected. Attempting reconnect...');
      connect();
      return;
    }

    final payload = {
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    };

    _logger.i('📤 [WS] Sending message to: $receiverId');
    _socket?.emit('send_message', payload);
  }

  void markAsRead(String partnerId) {
    if (_isConnected) {
      _socket?.emit('mark_read', {'chatPartnerId': partnerId});
    }
  }

  void checkPartnerStatus(String partnerId) {
    if (_isConnected) {
      _socket?.emit('check_status', {'partnerId': partnerId});
    }
  }

  Future<void> _cleanupSocket() async {
    _logger.i('🧹 [WS] Cleaning up socket...');
    _stopHeartbeat();
    try {
      _socket?.off('connected');
      _socket?.off('new_message');
      _socket?.off('message_sent');
      _socket?.off('partner_status');
      _socket?.off('message_read');
      _socket?.off('error');
      _socket?.off('new_notification');
      _socket?.off('user_deleted');
      _socket?.off('new_order');
      _socket?.off('role_changed');
      _socket?.off('connect');
      _socket?.off('connect_error');
      _socket?.off('disconnect');
      _socket?.off('reconnect');
      _socket?.off('reconnect_failed');
      _socket?.off('reconnect_error');
      _socket?.off('typing');
      _socket?.disconnect();
      _socket?.dispose();
    } catch (e) {
      _logger.e('❌ [WS] Error cleaning up socket: $e');
    }
    _socket = null;
    _isConnected = false;
  }

  Future<void> disconnect() async {
    _logger.i('🔌 [WS] Disconnecting...');
    _reconnectTimer?.cancel();
    await _cleanupSocket();
    _connectionController.add(false);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _newMessageController.close();
    _typingController.close();
    _statusController.close();
    _messageSentController.close();
    _connectionController.close();
    _partnerStatusController.close();
    _errorController.close();
    _notificationController.close();
    _messageReadController.close();
    _newOrderController.close();
    _roleChangeController.close();
    _userDeletedController.close();
    disconnect();
  }
}
