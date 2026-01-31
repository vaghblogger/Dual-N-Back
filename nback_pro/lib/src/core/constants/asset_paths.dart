/// Asset path constants for Dual N-Back Pro.
class AssetPaths {
  AssetPaths._();

  static const String _audio = 'assets/audio';
  static const String _animations = 'assets/animations';
  static const String _music = 'assets/music';

  static String letterAudio(String letter) =>
      '$_audio/${letter.toLowerCase()}.mp3';

  static const String n1Demo = '$_animations/n1_demo.json';
  static const String n2Demo = '$_animations/n2_demo.json';

  static const String focusAmbient = '$_music/focus_ambient.mp3';

  static const List<String> letterAudios = [
    '$_audio/c.mp3',
    '$_audio/h.mp3',
    '$_audio/k.mp3',
    '$_audio/l.mp3',
    '$_audio/q.mp3',
    '$_audio/r.mp3',
    '$_audio/s.mp3',
    '$_audio/t.mp3',
  ];
}
