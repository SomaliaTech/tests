import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/storage/storage_service.dart';

class ChatSocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentToken;
  final StorageService _storageService = GetIt.instance<StorageService>();

  final _newMessageController = StreamController<dynamic>.broadcast();
  final _statusController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get onNewMessage => _newMessageController.stream;
  Stream<dynamic> get onStatusChange => _statusController.stream;
  bool get isConnected => _isConnected;

  Completer<void>? _connectionCompleter;

  Future<void> connect() async {
    final token = await _storageService.getAuthToken();
    if (token == null) {
      print('❌ No token found, cannot connect to WebSocket');
      return;
    }

    // If already connected with same token, skip
    if (_socket != null && _isConnected && _currentToken == token) {
      print('✅ Already connected with same token');
      return;
    }

    // If token changed, disconnect old socket
    if (_socket != null) {
      print('🔄 Token changed, reconnecting...');
      disconnect();
    }

    _currentToken = token;
    print('🔌 Connecting to WebSocket...');

    _connectionCompleter = Completer<void>();

    // ✅ Use your actual server URL
    const serverUrl = 'http://10.0.2.2:8080'; // For Android Emulator
    // const serverUrl = 'http://localhost:8080'; // For iOS Simulator
    // const serverUrl = 'https://your-server.com'; // For production

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/chat')
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('✅ WebSocket connected successfully!');
      _setupListeners();
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }
    });

    _socket!.onConnectError((error) {
      print('❌ WebSocket connection error: $error');
      _isConnected = false;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(error);
      }
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      print('❌ WebSocket disconnected: $reason');
    });

    _socket!.onError((error) {
      print('❌ WebSocket error: $error');
    });

    _socket!.connect();

    try {
      await _connectionCompleter!.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ Connection timeout or error: $e');
    }
  }

  void _setupListeners() {
    _socket?.off('new_message'); // Remove old listeners
    _socket?.off('user_status');
    _socket?.off('message_sent');
    _socket?.off('connected');
    _socket?.off('error');

    _socket?.on('new_message', (data) {
      print('📩 New message received via socket: $data');
      _newMessageController.add(data);
    });

    _socket?.on('user_status', (data) {
      print('🔄 Status change via socket: $data');
      _statusController.add(data);
    });

    _socket?.on('message_sent', (data) {
      print('✅ Message sent confirmation: $data');
      // You can add this to your stream if needed
      _newMessageController.add(data);
    });

    _socket?.on('connected', (data) {
      print('🔌 Server acknowledged connection: $data');
    });

    _socket?.on('error', (data) {
      print('❌ Server error: $data');
    });
  }

  Future<void> ensureConnected() async {
    if (!_isConnected) {
      await connect();
    }
  }

  void sendMessage(
    String receiverId,
    String? content,
    String type,
    String? mediaUrl,
  ) async {
    if (!_isConnected) {
      print('⚠️ Socket not connected, attempting to connect...');
      await connect();

      if (!_isConnected) {
        print('❌ Cannot send message - socket not connected');
        return;
      }
    }

    final data = {
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    };

    print('📤 Sending message: $data');
    _socket?.emit('send_message', data);
  }

  void markAsRead(String partnerId) {
    if (_isConnected) {
      print('📤 Marking as read: $partnerId');
      _socket?.emit('mark_read', {'chatPartnerId': partnerId});
    }
  }

  void disconnect() {
    print('🔌 Disconnecting WebSocket');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentToken = null;
  }

  void dispose() {
    _newMessageController.close();
    _statusController.close();
    disconnect();
  }
}
