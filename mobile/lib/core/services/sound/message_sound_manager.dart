// lib/core/services/sound/message_sound_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/services/sound/sound_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';

class MessageSoundManager {
  final ChatSocketService _socketService = GetIt.instance<ChatSocketService>();
  final SoundService _soundService = SoundService();
  final StorageService _storageService = GetIt.instance<StorageService>();
  StreamSubscription? _messageSub;
  StreamSubscription? _connectionSub;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentChatPartnerId;
  bool _isAppInForeground = true;

  static final MessageSoundManager _instance = MessageSoundManager._internal();
  factory MessageSoundManager() => _instance;
  MessageSoundManager._internal();

  void setCurrentChatPartner(String? partnerId) {
    _currentChatPartnerId = partnerId;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // ✅ Don't await sound service init if it might fail
    try {
      await _soundService.init();
    } catch (e) {
      debugPrint('⚠️ Sound service init failed (non-critical): $e');
    }

    _setupLifecycleListener();

    void handleNewMessage(dynamic message) async {
      if (!_isAppInForeground) return;

      if (_currentChatPartnerId == message.senderId) return;

      try {
        final soundEnabled = await _storageService.getMessageSoundEnabled();
        if (!soundEnabled) return;

        final senderId = message.senderId;
        final receiverId = message.receiverId;

        if (receiverId == _currentUserId && senderId != _currentUserId) {
          await _soundService.playMessageSound();
        }
      } catch (e) {
        // Silently ignore sound errors
      }
    }

    _connectionSub = _socketService.onConnectionChange.listen((
      isConnected,
    ) async {
      if (isConnected) {
        try {
          _currentUserId = await _storageService.getUserId();
        } catch (e) {
          _currentUserId = null;
        }

        _messageSub?.cancel();
        _messageSub = _socketService.onNewMessage.listen(handleNewMessage);
      }
    });

    if (_socketService.isConnected) {
      try {
        _currentUserId = await _storageService.getUserId();
        _messageSub?.cancel();
        _messageSub = _socketService.onNewMessage.listen(handleNewMessage);
      } catch (e) {
        // Silently ignore
      }
    }
  }

  void _setupLifecycleListener() {
    try {
      WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
    } catch (e) {
      // Silently ignore
    }
  }

  void setAppInForeground(bool isForeground) {
    _isAppInForeground = isForeground;
  }

  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    // ✅ Don't dispose sound service - it handles its own lifecycle
    // _soundService.dispose();
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final MessageSoundManager manager;

  _LifecycleObserver(this.manager);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        manager.setAppInForeground(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        manager.setAppInForeground(false);
        break;
      default:
        break;
    }
  }
}
