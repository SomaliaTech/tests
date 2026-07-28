// lib/core/services/sound/sound_service.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundService {
  AudioPlayer? _player;
  bool _isInitialized = false;
  bool _isDisposed = false;

  Future<void> init() async {
    if (_isInitialized || _isDisposed) return;
    _isInitialized = true;

    try {
      _player = AudioPlayer();
    } catch (e) {
      debugPrint('⚠️ Failed to create audio player: $e');
      _player = null;
    }
  }

  Future<void> playMessageSound() async {
    if (_player == null || _isDisposed) return;

    try {
      await _player!.stop();
      await _player!.play(AssetSource('sounds/message.mp3'));
    } catch (e) {
      // Silently ignore - player might not be ready
    }
  }

  void dispose() {
    _isDisposed = true;
    // ✅ Don't call stop/release/dispose on the player directly
    // Just set the flag and let the player handle its own lifecycle
    _player = null;
  }
}
