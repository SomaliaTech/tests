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
  String? _currentChatPartnerId; // ✅ Track which chat room is open
  bool _isAppInForeground = true;

  static final MessageSoundManager _instance = MessageSoundManager._internal();
  factory MessageSoundManager() => _instance;
  MessageSoundManager._internal();

  void setCurrentChatPartner(String? partnerId) {
    _currentChatPartnerId = partnerId;
    debugPrint('💬 [Sound] Current chat partner: $partnerId');
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _soundService.init();

    // ✅ Listen for app lifecycle changes
    _setupLifecycleListener();

    // ✅ Centralized message handler
    void handleNewMessage(dynamic message) async {
      // Only play sound if app is in foreground
      if (!_isAppInForeground) {
        debugPrint('🔇 App in background - skipping sound');
        return;
      }

      // ✅ Skip sound if we're currently viewing the chat with the sender
      if (_currentChatPartnerId == message.senderId) {
        debugPrint('🔇 Viewing chat with sender - skipping sound');
        return;
      }

      try {
        final soundEnabled = await _storageService.getMessageSoundEnabled();
        if (!soundEnabled) return;

        final senderId = message.senderId;
        final receiverId = message.receiverId;

        // Only play sound for incoming messages (not sent by current user)
        if (receiverId == _currentUserId && senderId != _currentUserId) {
          await _soundService.playMessageSound();
          debugPrint('🔊 Message sound played for message from: $senderId');
        }
      } catch (e) {
        debugPrint('❌ Sound play error: $e');
      }
    }

    // Wait for WebSocket to connect
    _connectionSub = _socketService.onConnectionChange.listen((
      isConnected,
    ) async {
      if (isConnected) {
        try {
          _currentUserId = await _storageService.getUserId();
          debugPrint('🔊 [Sound] Current user ID: $_currentUserId');
        } catch (e) {
          _currentUserId = null;
          debugPrint('❌ [Sound] Failed to get user ID: $e');
        }

        // Cancel previous subscription if exists
        _messageSub?.cancel();

        // Listen for new messages
        _messageSub = _socketService.onNewMessage.listen(handleNewMessage);
      }
    });

    // If already connected, trigger immediately
    if (_socketService.isConnected) {
      try {
        _currentUserId = await _storageService.getUserId();
        _messageSub?.cancel();
        _messageSub = _socketService.onNewMessage.listen(handleNewMessage);
      } catch (e) {
        debugPrint('❌ Sound init error: $e');
      }
    }

    debugPrint('🔊 Message sound manager initialized');
  }

  void _setupLifecycleListener() {
    try {
      WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
    } catch (e) {
      debugPrint('⚠️ Could not add lifecycle observer: $e');
    }
  }

  void setAppInForeground(bool isForeground) {
    _isAppInForeground = isForeground;
    debugPrint('📱 App foreground: $isForeground');
  }

  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _soundService.dispose();
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
