import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/services/audio_service.dart';
import 'miniature_grid_demo.dart';

/// Which button the animated finger is pointing at (or none).
enum _FingerTarget { none, audio, visual, bothVisual, bothAudio }

/// Phased tutorial demo: three phases (position match, audio match, both match),
/// 2 s per step, game-style buttons at bottom, animated finger at match steps.
/// Loops after phase 3. N=1 or N=2 (match = 1 or 2 steps back).
class PhasedTutorialDemo extends StatefulWidget {
  const PhasedTutorialDemo({
    super.key,
    required this.n,
    required this.audioService,
    this.stepDuration = const Duration(milliseconds: 2000),
    this.fingerDuration = const Duration(milliseconds: 1500),
  });

  /// N-back level: 1 or 2 (match = same as 1 or 2 steps back).
  final int n;
  final AudioService audioService;
  final Duration stepDuration;
  final Duration fingerDuration;

  @override
  State<PhasedTutorialDemo> createState() => _PhasedTutorialDemoState();
}

class _PhasedTutorialDemoState extends State<PhasedTutorialDemo>
    with TickerProviderStateMixin {
  static const List<DemoStep> _n1Phase1 = [
    (position: 0, letter: 'C'),
    (position: 1, letter: 'H'),
    (position: 0, letter: 'K'),
  ];
  static const List<DemoStep> _n1Phase2 = [
    (position: 0, letter: 'C'),
    (position: 1, letter: 'C'),
    (position: 2, letter: 'K'),
  ];
  static const List<DemoStep> _n1Phase3 = [
    (position: 0, letter: 'C'),
    (position: 1, letter: 'H'),
    (position: 1, letter: 'H'),
  ];
  static const List<DemoStep> _n2Phase1 = [
    (position: 0, letter: 'C'),
    (position: 1, letter: 'H'),
    (position: 2, letter: 'K'),
    (position: 0, letter: 'R'),
  ];
  static const List<DemoStep> _n2Phase2 = [
    (position: 0, letter: 'C'),
    (position: 1, letter: 'H'),
    (position: 2, letter: 'C'),
  ];
  static const List<DemoStep> _n2Phase3 = [
    (position: 0, letter: 'C'),
    (position: 1, letter: 'H'),
    (position: 2, letter: 'K'),
    (position: 1, letter: 'H'),
  ];

  int _phase = 1;
  int _step = 0;
  _FingerTarget _fingerTarget = _FingerTarget.none;
  Timer? _timer;
  late List<DemoStep> _script;
  late AnimationController _fingerController;

  @override
  void initState() {
    super.initState();
    _fingerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _updateScript();
    _runStep();
  }

  void _updateScript() {
    final n = widget.n;
    if (n == 1) {
      if (_phase == 1) {
        _script = _n1Phase1;
      } else if (_phase == 2) {
        _script = _n1Phase2;
      } else {
        _script = _n1Phase3;
      }
    } else {
      if (_phase == 1) {
        _script = _n2Phase1;
      } else if (_phase == 2) {
        _script = _n2Phase2;
      } else {
        _script = _n2Phase3;
      }
    }
  }

  int get _n => widget.n;

  bool _isVisualMatch(int stepIndex) {
    if (stepIndex < _n) return false;
    return _script[stepIndex].position == _script[stepIndex - _n].position;
  }

  bool _isAudioMatch(int stepIndex) {
    if (stepIndex < _n) return false;
    return _script[stepIndex].letter == _script[stepIndex - _n].letter;
  }

  bool _isBothMatch(int stepIndex) {
    if (stepIndex < _n) return false;
    final prev = _script[stepIndex - _n];
    final curr = _script[stepIndex];
    return prev.position == curr.position && prev.letter == curr.letter;
  }

  void _runStep() {
    if (_step >= _script.length) {
      _phase = _phase >= 3 ? 1 : _phase + 1;
      _step = 0;
      _updateScript();
    }
    if (_script.isEmpty) return;
    final step = _script[_step];
    widget.audioService.playLetter(step.letter);
    setState(() {});

    final isMatchStep = _step >= _n &&
        (_phase == 1 && _isVisualMatch(_step) ||
            _phase == 2 && _isAudioMatch(_step) ||
            _phase == 3 && _isBothMatch(_step));

    if (isMatchStep && _phase == 3) {
      setState(() => _fingerTarget = _FingerTarget.bothVisual);
      _fingerController.forward(from: 0);
      _timer?.cancel();
      _timer = Timer(widget.fingerDuration, () {
        if (!mounted) return;
        setState(() => _fingerTarget = _FingerTarget.bothAudio);
        _fingerController.forward(from: 0);
        _timer = Timer(widget.fingerDuration, _advanceAfterFinger);
      });
    } else if (isMatchStep) {
      setState(() {
        _fingerTarget = _phase == 1 ? _FingerTarget.visual : _FingerTarget.audio;
      });
      _fingerController.forward(from: 0);
      _timer?.cancel();
      _timer = Timer(widget.fingerDuration, _advanceAfterFinger);
    } else {
      setState(() => _fingerTarget = _FingerTarget.none);
      _timer?.cancel();
      _timer = Timer(widget.stepDuration, _advanceStep);
    }
  }

  void _advanceAfterFinger() {
    if (!mounted) return;
    setState(() => _fingerTarget = _FingerTarget.none);
    _advanceStep();
  }

  void _advanceStep() {
    if (!mounted) return;
    _step++;
    _runStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fingerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_script.isEmpty) return const SizedBox.shrink();
    final step = _script[_step];
    final activePosition = step.position;
    const padding = 24.0;
    const iconSize = 48.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final isActive = index == activePosition;
                      return Container(
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).cardColor,
                          border: Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: null,
                      );
                    },
                  ),
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.add,
                        size: iconSize,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DemoButton(
                      label: AppStrings.audioMatch,
                      highlighted: _fingerTarget == _FingerTarget.audio ||
                          _fingerTarget == _FingerTarget.bothAudio,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DemoButton(
                      label: AppStrings.visualMatch,
                      highlighted: _fingerTarget == _FingerTarget.visual ||
                          _fingerTarget == _FingerTarget.bothVisual,
                    ),
                  ),
                ],
              ),
              if (_fingerTarget != _FingerTarget.none)
                Positioned(
                  left: 0,
                  right: 0,
                  top: -36,
                  child: Row(
                    children: [
                      Expanded(
                        child: _fingerTarget == _FingerTarget.audio ||
                                _fingerTarget == _FingerTarget.bothAudio
                            ? _AnimatedFinger(
                                controller: _fingerController,
                              )
                            : const SizedBox(height: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _fingerTarget == _FingerTarget.visual ||
                                _fingerTarget == _FingerTarget.bothVisual
                            ? _AnimatedFinger(
                                controller: _fingerController,
                              )
                            : const SizedBox(height: 48),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.label,
    required this.highlighted,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: highlighted
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          foregroundColor: highlighted
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : null,
        ),
        child: Text(label),
      ),
    );
  }
}

class _AnimatedFinger extends StatelessWidget {
  const _AnimatedFinger({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Tap: scale down then up (1.2 -> 0.9 -> 1.2)
        final v = controller.value;
        final scale = v < 0.5 ? 1.2 - 0.3 * (v * 2) : 0.9 + 0.3 * ((v - 0.5) * 2);
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.touch_app,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
