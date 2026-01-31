/// A single trial in an N-Back session.
class Trial {
  final int position; // 0-8 (3x3 grid)
  final String letter;
  final bool isVisualMatch;
  final bool isAudioMatch;

  const Trial({
    required this.position,
    required this.letter,
    required this.isVisualMatch,
    required this.isAudioMatch,
  });
}
