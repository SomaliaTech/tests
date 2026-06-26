import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/services/sound/sound_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/chat/domain/entities/chat_message.dart';

class MessageSoundManager {
  final ChatSocketService _socketService = GetIt.instance<ChatSocketService>();
  final SoundService _soundService = SoundService();
  final StorageService _storageService = GetIt.instance<StorageService>();
  StreamSubscription? _messageSub;
  StreamSubscription? _connectionSub;
  bool _isInitialized = false;
  String? _currentUserId;

  static final MessageSoundManager _instance = MessageSoundManager._internal();
  factory MessageSoundManager() => _instance;
  MessageSoundManager._internal();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _soundService.init();

    // ✅ Wait for WebSocket to connect before setting up message listener
    _connectionSub = _socketService.onConnectionChange.listen((
      isConnected,
    ) async {
      if (isConnected) {
        // Get current user ID
        try {
          _currentUserId = await _storageService.getUserId();
        } catch (e) {
          _currentUserId = null;
        }

        // Cancel old subscription if exists
        _messageSub?.cancel();

        // ✅ Listen for new messages - now receives ChatMessage directly
        _messageSub = _socketService.onNewMessage.listen((message) async {
          try {
            final soundEnabled = await _storageService.getMessageSoundEnabled();
            if (!soundEnabled) return;

            final senderId = message.senderId;
            final receiverId = message.receiverId;

            // Play sound if message is for current user AND not from self
            if (receiverId == _currentUserId && senderId != _currentUserId) {
              _soundService.playMessageSound();
            }
          } catch (e) {
            // Silently fail
          }
        });
      }
    });

    // If already connected, trigger immediately
    if (_socketService.isConnected) {
      try {
        _currentUserId = await _storageService.getUserId();
        // ✅ Listen for new messages - now receives ChatMessage directly
        _messageSub = _socketService.onNewMessage.listen((message) async {
          try {
            final soundEnabled = await _storageService.getMessageSoundEnabled();
            if (!soundEnabled) return;

            final senderId = message.senderId;
            final receiverId = message.receiverId;

            if (receiverId == _currentUserId && senderId != _currentUserId) {
              _soundService.playMessageSound();
            }
          } catch (e) {
            // Silently fail
          }
        });
      } catch (e) {
        // Silently fail
      }
    }
  }

  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _soundService.dispose();
  }
}
