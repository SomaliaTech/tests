// lib/core/services/chat_socket_service.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/widgets.dart'; // 🚀 ADD THIS

class ChatSocketService with WidgetsBindingObserver {
  // 🚀 ADD MIXIN
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  String? _userId;
  bool _isDisposed = false;

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
    if (_isDisposed) return;

    if (_socket?.connected == true) {
      _isConnected = true;
      _isConnecting = false;
      return;
    }

    if (_isConnecting) return;

    _isConnecting = true;

    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        _isConnecting = false;
        _errorController.add('Authentication token not found');
        return;
      }

      if (_socket != null) await _cleanupSocket();

      _reconnectAttempts = 0;
      final wsUrl = ApiConstants.wsUrl;

      _socket = io.io(
        '$wsUrl/chat',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .setTimeout(20000)
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(30000)
            .build(),
      );

      _socket!.onConnect((data) => _onConnect(data));
      _socket!.onConnectError((error) => _onConnectError(error));
      _socket!.onDisconnect((reason) => _onDisconnect(reason));
      _socket!.onReconnect((attempt) => _onReconnect(attempt));
      _socket!.onReconnectFailed((data) => _onReconnectFailed(data));
      _socket!.onReconnectError((error) => _onReconnectError(error));
      _socket!.onReconnectAttempt((attempt) => _onReconnectAttempt(attempt));

      _socket!.connect();

      // 🚀 Register lifecycle observer to handle background/foreground
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      _isConnecting = false;
      _errorController.add('Connection setup failed: $e');
      if (_socket != null) _socket!.connect();
    }
  }

  // 🚀 APP LIFECYCLE HANDLER (Fixes Ghost Online on Mobile)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App is backgrounded. Stop heartbeat so server marks us offline after TTL
      _stopHeartbeat();
      _logger.i('📱 [WS] App backgrounded - stopped heartbeat');
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      if (_socket?.connected == true) {
        _startHeartbeat();
        _logger.i('📱 [WS] App resumed - restarted heartbeat');
      } else {
        connect(); // Force reconnect if dropped in background
      }
    }
  }

  void _onReconnectAttempt(dynamic attempt) {
    _connectionController.add(false);
  }

  void _onConnect(dynamic data) {
    _isConnected = true;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _connectionController.add(true);
    _setupListeners();
    _startHeartbeat();
  }

  void _onConnectError(dynamic error) {
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    if (_reconnectAttempts == 0) {
      _errorController.add('Connection failed: $error');
    }
  }

  void _onDisconnect(dynamic reason) {
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    _stopHeartbeat();
  }

  void _onReconnect(dynamic attempt) {
    _isConnected = true;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _connectionController.add(true);
    _setupListeners();
    _startHeartbeat();
  }

  void _onReconnectFailed(dynamic data) {
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    _errorController.add(
      'Unable to connect to chat server. Please check your internet connection.',
    );
    _statusController.add({
      'event': 'reconnect_failed',
      'message': 'Chat connection lost. Please refresh.',
    });
  }

  void _onReconnectError(dynamic error) {
    _isConnecting = false;
  }

  void sendTypingEvent(String receiverId, bool isTyping) {
    if (_isConnected && _socket != null) {
      _socket!.emit('typing', {'receiverId': receiverId, 'isTyping': isTyping});
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _socket != null && !_isDisposed) {
        _socket!.emit('heartbeat', {});
      } else if (_isDisposed) {
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _setupListeners() {
    _socket?.on('connected', (data) {
      if (data is Map) {
        _userId = data['userId']?.toString();
      }
    });

    _socket?.on('user_deleted', (data) {
      if (data is Map)
        _userDeletedController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('new_message', (data) {
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
      if (data is Map)
        _messageSentController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('partner_status', (data) {
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        _partnerStatusController.add(mapData);
        _statusController.add(mapData);
      }
    });

    _socket?.on('message_read', (data) {
      if (data is Map)
        _messageReadController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('error', (data) {
      String errorMessage = 'Unknown error';
      if (data is Map && data['message'] != null)
        errorMessage = data['message'].toString();
      else if (data is String)
        errorMessage = data;
      _errorController.add(errorMessage);
    });

    _socket?.on('typing', (data) {
      if (data is Map) _typingController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('new_notification', (data) {
      if (data is Map)
        _notificationController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('new_order', (data) {
      if (data is Map) _newOrderController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('role_changed', (data) {
      if (data is Map) {
        final isAdmin = data['isAdmin'] as bool? ?? false;
        final isSuperAdmin = data['isSuperAdmin'] as bool? ?? false;

        try {
          _storageService.saveIsAdmin(isAdmin);
          _storageService.saveIsSuperAdmin(isSuperAdmin);
        } catch (e) {}

        _roleChangeController.add({
          'isAdmin': isAdmin,
          'isSuperAdmin': isSuperAdmin,
        });

        try {
          final authBloc = GetIt.instance<AuthBloc>();
          authBloc.add(const CheckAuthStatusEvent());
        } catch (e) {}
      }
    });
  }

  void sendMessage({
    required String receiverId,
    String? content,
    String type = 'text',
    String? mediaUrl,
  }) {
    if (_isDisposed) return;

    if (!_isConnected) {
      connect();
      return;
    }

    _socket?.emit('send_message', {
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    });
  }

  void markAsRead(String partnerId) {
    if (_isConnected && _socket != null && !_isDisposed) {
      _socket!.emit('mark_read', {'chatPartnerId': partnerId});
    }
  }

  void checkPartnerStatus(String partnerId) {
    if (_isConnected && _socket != null && !_isDisposed) {
      _socket!.emit('check_status', {'partnerId': partnerId});
    }
  }

  Future<void> _cleanupSocket() async {
    _stopHeartbeat();
    try {
      if (_socket != null) {
        _socket!.off('connected');
        _socket!.off('new_message');
        _socket!.off('message_sent');
        _socket!.off('partner_status');
        _socket!.off('message_read');
        _socket!.off('error');
        _socket!.off('new_notification');
        _socket!.off('user_deleted');
        _socket!.off('new_order');
        _socket!.off('role_changed');
        _socket!.off('connect');
        _socket!.off('connect_error');
        _socket!.off('disconnect');
        _socket!.off('reconnect');
        _socket!.off('reconnect_failed');
        _socket!.off('reconnect_error');
        _socket!.off('reconnect_attempt');
        _socket!.off('typing');

        _socket!.disconnect();
        _socket!.dispose();
      }
    } catch (e) {}

    _socket = null;
    _isConnected = false;
    _isConnecting = false;
  }

  Future<void> disconnect() async {
    await _cleanupSocket();
    _connectionController.add(false);
  }

  Future<void> reconnect() async {
    await _cleanupSocket();
    _isConnecting = false;
    _reconnectAttempts = 0;
    await connect();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this); // 🚀 REMOVE OBSERVER
    _stopHeartbeat();
    disconnect();

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
  }
}
