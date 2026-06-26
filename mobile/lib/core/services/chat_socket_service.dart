import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';

class ChatSocketService {
  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentToken;
  final StorageService _storageService = GetIt.instance<StorageService>();
  final Logger _logger = Logger();

  // ✅ Stream controllers
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
  Stream<Map<String, dynamic>> get onNewOrder => _newOrderController.stream;
  // ✅ Getters
  Stream<ChatMessage> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onStatusChange => _statusController.stream;
  Stream<Map<String, dynamic>> get onMessageSent =>
      _messageSentController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;
  Stream<Map<String, dynamic>> get onPartnerStatus =>
      _partnerStatusController.stream;
  Stream<Map<String, dynamic>> get onPartnerStatusChanged =>
      _partnerStatusController.stream; // ✅ Alias for compatibility
  Stream<String> get onError => _errorController.stream;
  Stream<Map<String, dynamic>> get onNewNotification =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get onMessageRead =>
      _messageReadController.stream; // ✅ NEW

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        _logger.w('❌ [WS] No token found');
        _errorController.add('Authentication token not found');
        return;
      }

      if (_isConnected && _currentToken == token) {
        _logger.i('✅ [WS] Already connected');
        return;
      }

      if (_socket != null) {
        await disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _currentToken = token;
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
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        _logger.i('🟢 [WS] Connected - Socket ID: ${_socket!.id}');
        _connectionController.add(true);
        _setupListeners();
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        _logger.e('🔴 [WS] Connection error: $error');
        _connectionController.add(false);
        _errorController.add('Connection failed: $error');
      });

      _socket!.onDisconnect((reason) {
        _isConnected = false;
        _logger.w('🔴 [WS] Disconnected: $reason');
        _connectionController.add(false);
      });

      _socket!.onReconnect((attempt) {
        _isConnected = true;
        _logger.i('🔄 [WS] Reconnected after $attempt attempts');
        _connectionController.add(true);
      });

      _socket!.onReconnectFailed((error) {
        _isConnected = false;
        _logger.e('❌ [WS] Failed to reconnect: $error');
        _errorController.add('Failed to reconnect to chat server');
      });

      _socket!.onReconnectError((error) {
        _logger.e('❌ [WS] Reconnection error: $error');
        _errorController.add('Reconnection error: $error');
      });

      _socket!.connect();
    } catch (e) {
      _logger.e('❌ [WS] Connection setup failed: $e');
      _errorController.add('Connection setup failed: $e');
    }
  }

  void _setupListeners() {
    _logger.i('🔧 [WS] Setting up listeners...');

    _socket?.on('connected', (data) {
      _logger.i('✅ [WS] Server confirmed connection: $data');
    });

    _socket?.on('new_notification', (data) {
      _logger.i('🔔 [WS] Received new_notification');
      if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    // ✅ NEW: Parse new_message into ChatMessage object
    _socket?.on('new_message', (data) {
      _logger.i('📩 [WS] Received new_message');
      if (data is Map) {
        try {
          final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
          _newMessageController.add(message);
        } catch (e) {
          _logger.e('❌ Error parsing message: $e');
        }
      }
    });

    _socket?.on('message_sent', (data) {
      _logger.i('✅ [WS] Received message_sent confirmation');
      if (data is Map) {
        _messageSentController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('user:status', (data) {
      _logger.i('🔄 [WS] Received user:status update');
      if (data is Map) {
        _statusController.add(Map<String, dynamic>.from(data));
      }
    });

    // ✅ UPDATED: partner_status also goes to _partnerStatusController
    _socket?.on('partner_status', (data) {
      _logger.i('🟢 [WS] Received partner_status: $data');
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        _partnerStatusController.add(mapData);
        _statusController.add(
          mapData,
        ); // ✅ Also send to status stream for compatibility
      }
    });

    // ✅ NEW: message_read listener
    _socket?.on('message_read', (data) {
      _logger.i('✅ [WS] Received message_read');
      if (data is Map) {
        _messageReadController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('error', (data) {
      _logger.e('❌ [WS] Server error: $data');
      if (data is Map && data['message'] != null) {
        _errorController.add(data['message'].toString());
      } else if (data is String) {
        _errorController.add(data);
      }
    });
    _socket?.on('new_order', (data) {
      _logger.i('📦 [WS] Received new_order');
      if (data is Map) {
        _newOrderController.add(Map<String, dynamic>.from(data));
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
      _logger.w('⚠️ [WS] Cannot send - not connected');
      _errorController.add('Not connected to chat server');
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

  Future<void> disconnect() async {
    _logger.i('🔌 [WS] Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    _notificationController.close();
    _newMessageController.close();
    _statusController.close();
    _messageSentController.close();
    _connectionController.close();
    _partnerStatusController.close();
    _errorController.close();
    _messageReadController.close(); // ✅ NEW
    _newOrderController.close();
    disconnect();
  }
}
