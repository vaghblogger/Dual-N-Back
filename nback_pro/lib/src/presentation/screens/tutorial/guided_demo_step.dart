import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/services/audio_service.dart';
import 'miniature_grid_demo.dart';

/// Phase of the one-shot guided demo sequence.
enum _GuidedPhase {
  gridAnimation,
  message,
  fingerTap,
  buttonPressed,
  done,
}

/// One-shot guided demo: grid (2s per step) → message (2s) → finger taps button (1s) → button shows pressed (1s) → done.
class GuidedDemoStep extends StatefulWidget {
  const GuidedDemoStep({
    super.key,
    required this.title,
    required this.n,
    required this.mode,
    required this.audioService,
    required this.onSequenceComplete,
  });

  final String title;
  final int n;
  final String mode; // 'positionOnly' | 'audioOnly' | 'mixed'
  final AudioService audioService;
  final VoidCallback onSequenceComplete;

  @override
  State<GuidedDemoStep> createState() => _GuidedDemoStepState();
}

/// Sub-phase within grid animation: show highlight 1s, hide 2s, show again 1s, then next step.
enum _GridSubPhase { on, off, onAgain }

class _GuidedDemoStepState extends State<GuidedDemoStep>
    with TickerProviderStateMixin {
  static const _highlightOnDuration = Duration(milliseconds: 1000);
  static const _highlightOffDuration = Duration(milliseconds: 2000);
  static const _highlightOnAgainDuration = Duration(milliseconds: 1000);
  static const _messageDuration = Duration(milliseconds: 2000);
  static const _fingerDuration = Duration(milliseconds: 1000);
  static const _buttonPressedDuration = Duration(milliseconds: 1000);

  late List<DemoStep> _script;
  int _gridIndex = 0;
  _GridSubPhase _gridSubPhase = _GridSubPhase.on;
  _GuidedPhase _phase = _GuidedPhase.gridAnimation;
  Timer? _timer;
  int _fingerTarget = 0; // 0 = none, 1 = visual, 2 = audio
  bool _buttonPressedVisual = false;
  bool _buttonPressedAudio = false;
  late AnimationController _fingerController;

  @override
  void initState() {
    super.initState();
    _fingerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buildScript();
    _runGridStep();
  }

  void _buildScript() {
    final n = widget.n;
    final mode = widget.mode;
    if (n == 1) {
      if (mode == 'positionOnly') {
        _script = [(position: 0, letter: 'C'), (position: 0, letter: 'H')];
      } else if (mode == 'audioOnly') {
        _script = [(position: 0, letter: 'C'), (position: 1, letter: 'C')];
      } else {
        // Mixed N=1: same position and same audio twice (one cycle).
        _script = [(position: 0, letter: 'C'), (position: 0, letter: 'C')];
      }
    } else {
      if (mode == 'positionOnly') {
        _script = [
          (position: 0, letter: 'C'),
          (position: 1, letter: 'H'),
          (position: 0, letter: 'R'),
        ];
      } else if (mode == 'audioOnly') {
        _script = [
          (position: 0, letter: 'C'),
          (position: 1, letter: 'H'),
          (position: 2, letter: 'C'),
        ];
      } else {
        // N=2 mixed: (1,H) → (2,K) → (1,H). Same position and same letter 2 steps back.
        _script = [
          (position: 1, letter: 'H'),
          (position: 2, letter: 'K'),
          (position: 1, letter: 'H'),
        ];
      }
    }
  }

  void _runGridStep() {
    if (_gridIndex >= _script.length) {
      _showMessage();
      return;
    }
    final step = _script[_gridIndex];
    _timer?.cancel();
    if (_gridSubPhase == _GridSubPhase.on) {
      widget.audioService.playLetter(step.letter);
      setState(() {});
      _timer = Timer(_highlightOnDuration, () {
        if (!mounted) return;
        // N=2: run through all steps (on 1s each, off 2s between). After last step → message.
        if (widget.n == 2) {
          if (_gridIndex == _script.length - 1) {
            _showMessage();
            return;
          }
          setState(() => _gridSubPhase = _GridSubPhase.off);
          _timer?.cancel();
          _timer = Timer(_highlightOffDuration, () {
            if (!mounted) return;
            _gridIndex++;
            _gridSubPhase = _GridSubPhase.on;
            _runGridStep();
          });
          return;
        }
        // N=1: one cycle (on 1s, off 2s, onAgain 1s) then message.
        setState(() => _gridSubPhase = _GridSubPhase.off);
        _timer?.cancel();
        _timer = Timer(_highlightOffDuration, () {
          if (!mounted) return;
          if (_gridIndex + 1 < _script.length) {
            widget.audioService.playLetter(_script[_gridIndex + 1].letter);
          }
          setState(() => _gridSubPhase = _GridSubPhase.onAgain);
          _timer?.cancel();
          _timer = Timer(_highlightOnAgainDuration, () {
            if (!mounted) return;
            _showMessage();
          });
        });
      });
    }
  }

  void _showMessage() {
    setState(() => _phase = _GuidedPhase.message);
    _timer?.cancel();
    _timer = Timer(_messageDuration, () {
      if (!mounted) return;
      _startFingerTap();
    });
  }

  void _startFingerTap() {
    setState(() {
      _phase = _GuidedPhase.fingerTap;
      _fingerTarget = widget.mode == 'mixed' ? 1 : (widget.mode == 'positionOnly' ? 1 : 2);
    });
    _fingerController.forward(from: 0);
    _timer?.cancel();
    _timer = Timer(_fingerDuration, () {
      if (!mounted) return;
      _showButtonPressed();
    });
  }

  void _showButtonPressed() {
    setState(() {
      _phase = _GuidedPhase.buttonPressed;
      if (_fingerTarget == 1) {
        _buttonPressedVisual = true;
      } else {
        _buttonPressedAudio = true;
      }
    });
    _timer?.cancel();
    _timer = Timer(_buttonPressedDuration, () {
      if (!mounted) return;
      if (widget.mode == 'mixed' && _buttonPressedVisual && !_buttonPressedAudio) {
        setState(() {
          _buttonPressedVisual = false;
          _fingerTarget = 2;
          _phase = _GuidedPhase.fingerTap;
        });
        _fingerController.forward(from: 0);
        _timer = Timer(_fingerDuration, () {
          if (!mounted) return;
          setState(() {
            _phase = _GuidedPhase.buttonPressed;
            _buttonPressedAudio = true;
          });
          _timer = Timer(_buttonPressedDuration, _finishSequence);
        });
      } else {
        _finishSequence();
      }
    });
  }

  void _finishSequence() {
    if (!mounted) return;
    setState(() => _phase = _GuidedPhase.done);
    widget.onSequenceComplete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fingerController.dispose();
    super.dispose();
  }

  String get _messageText {
    final n = widget.n;
    final mode = widget.mode;
    final String base;
    if (n == 1) {
      if (mode == 'positionOnly') base = AppStrings.tutorialMessagePositionSameN1;
      else if (mode == 'audioOnly') base = AppStrings.tutorialMessageAudioSameN1;
      else base = AppStrings.tutorialMessageBothSameN1;
    } else {
      if (mode == 'positionOnly') base = AppStrings.tutorialMessagePositionSameN2;
      else if (mode == 'audioOnly') base = AppStrings.tutorialMessageAudioSameN2;
      else base = AppStrings.tutorialMessageBothSameN2;
    }
    final String tapInstruction;
    if (mode == 'positionOnly') {
      tapInstruction = 'Tap ${AppStrings.visualMatch}.';
    } else if (mode == 'audioOnly') {
      tapInstruction = 'Tap ${AppStrings.audioMatch}.';
    } else {
      tapInstruction = 'Tap ${AppStrings.visualMatch} and ${AppStrings.audioMatch}.';
    }
    return '$base\n\n$tapInstruction';
  }

  /// Fixed height for the grid area so it renders correctly inside [SingleChildScrollView].
  static const double _gridAreaHeight = 320;

  int get _displayPosition {
    if (_gridSubPhase == _GridSubPhase.off) return -1;
    if (_gridSubPhase == _GridSubPhase.onAgain &&
        _gridIndex + 1 < _script.length &&
        widget.mode == 'audioOnly') {
      return _script[_gridIndex + 1].position;
    }
    final step = _gridIndex < _script.length ? _script[_gridIndex] : _script.last;
    return step.position;
  }

  @override
  Widget build(BuildContext context) {
    final activePosition = _displayPosition;
    const padding = 20.0;
    const iconSize = 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: _gridAreaHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(padding),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                          );
                        },
                      ),
                      IgnorePointer(
                        child: Opacity(
                          opacity: 0.15,
                          child: Icon(Icons.add, size: iconSize, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_phase == _GuidedPhase.message || _phase == _GuidedPhase.fingerTap || _phase == _GuidedPhase.buttonPressed)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 100,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Text(
                        _messageText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _DemoButton(
                      label: AppStrings.audioMatch,
                      highlighted: _buttonPressedAudio,
                    ),
                    if ((_phase == _GuidedPhase.fingerTap || _phase == _GuidedPhase.buttonPressed) && _fingerTarget == 2)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Center(
                          child: _AnimatedFinger(controller: _fingerController),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _DemoButton(
                      label: AppStrings.visualMatch,
                      highlighted: _buttonPressedVisual,
                    ),
                    if ((_phase == _GuidedPhase.fingerTap || _phase == _GuidedPhase.buttonPressed) && _fingerTarget == 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Center(
                          child: _AnimatedFinger(controller: _fingerController),
                        ),
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
  const _DemoButton({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  static const _pressScale = 0.96;
  static const _pressDuration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: AnimatedScale(
        scale: highlighted ? _pressScale : 1.0,
        duration: _pressDuration,
        curve: Curves.easeOut,
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
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
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
        final v = controller.value;
        final scale = v < 0.5 ? 1.2 - 0.3 * (v * 2) : 0.9 + 0.3 * ((v - 0.5) * 2);
        return Transform.scale(
          scale: scale,
          child: Icon(Icons.touch_app, size: 44, color: Theme.of(context).colorScheme.primary),
        );
      },
    );
  }
}
