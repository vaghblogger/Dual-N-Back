import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _letterPlayer = AudioPlayer();

  AudioService() {
    // Stop any previous focus music (e.g. after hot restart the old native
    // player may still be playing; calling stop on the new instance can help
    // on some platforms / plugin versions).
    _musicPlayer.stop();
  }

  Future<void> preloadAudio() async {
    // Warm the asset; letter playback uses setSource + resume each time for reliability.
    try {
      await _letterPlayer.setSource(AssetSource('audio/c.mp3'));
    } catch (_) {
      // Ignore preload failure; letter playback will still attempt per-letter.
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
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> startFocusMusic() async {
    try {
      await _musicPlayer.stop();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.3);
      await _musicPlayer.setSource(AssetSource('music/focus_ambient.mp3'));
      await _musicPlayer.resume();
    } catch (_) {
      // Focus music is optional; ignore failure.
    }
  }

  Future<void> stopFocusMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  void dispose() {
    _musicPlayer.dispose();
    _letterPlayer.dispose();
  }
}
