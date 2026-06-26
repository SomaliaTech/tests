import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _player.setSource(AssetSource('sounds/message_received.mp3'));
      await _player.setVolume(1.0);
      print('🔊 Sound service initialized successfully');
    } catch (e) {
      print('❌ Sound service failed: $e');
    }
  }

  Future<void> playMessageSound() async {
    try {
      // ✅ Simple approach: just stop and play
      await _player.stop();
      await _player.resume();
    } catch (e) {
      // If resume fails, try setting source again
      try {
        await _player.setSource(AssetSource('sounds/message_received.mp3'));
        await _player.resume();
      } catch (e2) {
        print('❌ Sound play failed: $e2');
      }
    }
  }

  void dispose() {
    _player.dispose();
  }
}
