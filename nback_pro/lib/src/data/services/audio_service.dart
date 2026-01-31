import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _letterPlayer = AudioPlayer();

  Future<void> preloadAudio() async {
    // Warm the asset; letter playback uses setSource + resume each time for reliability.
    try {
      await _letterPlayer.setSource(AssetSource('audio/c.mp3'));
    } catch (e) {
      debugPrint('AudioService preload warm: $e');
    }
  }

  Future<void> playLetter(String letter) async {
    final key = letter.toLowerCase();
    try {
      try {
        await _letterPlayer.stop();
      } catch (_) {
        // Ignore if already stopped
      }
      // Let Android MediaPlayer reach Idle before setDataSource (avoids IllegalStateException).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _letterPlayer.play(AssetSource('audio/$key.mp3'));
    } catch (e, st) {
      debugPrint('AudioService playLetter failed for $key: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> startFocusMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.3);
      await _musicPlayer.play(AssetSource('music/focus_ambient.mp3'));
    } catch (_) {
      // Focus music optional
    }
  }

  Future<void> stopFocusMusic() async {
    await _musicPlayer.stop();
  }

  void dispose() {
    _musicPlayer.dispose();
    _letterPlayer.dispose();
  }
}
