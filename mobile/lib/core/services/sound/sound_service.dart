import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  // ✅ Debounce: prevent multiple plays within 500ms
  DateTime? _lastPlayTime;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _player.setSource(AssetSource('sounds/message_received.mp3'));
      await _player.setReleaseMode(ReleaseMode.stop);
      debugPrint('🔊 Sound service initialized successfully');
    } catch (e) {
      debugPrint('❌ Sound service failed: $e');
    }
  }

  Future<void> playMessageSound() async {
    try {
      // ✅ Debounce: prevent rapid successive plays
      final now = DateTime.now();
      if (_lastPlayTime != null &&
          now.difference(_lastPlayTime!).inMilliseconds < 500) {
        debugPrint('🔊 Sound skipped (debounce)');
        return;
      }
      _lastPlayTime = now;

      await _player.stop();
      await _player.play(AssetSource('sounds/message_received.mp3'));
      debugPrint('🔊 Message sound played');
    } catch (e) {
      debugPrint('❌ Sound play failed: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
