import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../data/services/audio_service.dart';
import 'miniature_grid_demo.dart';

/// Phase of the one-shot guided demo sequence.
enum _GuidedPhase {
  gridAnimation,
  message,
  waitingForTap,
  showingFeedback,
  done,
}

/// Guided demo: optional 2s delay, then grid → message → user taps correct button(s).
/// Correct tap: show "Great!" etc., then next target or done. Wrong tap: offer retry and replay.
class GuidedDemoStep extends StatefulWidget {
  const GuidedDemoStep({
    super.key,
    required this.title,
    required this.n,
    required this.mode,
    required this.audioService,
    required this.onSequenceComplete,
    this.initialDelaySeconds = 0,
    this.onRegisterRetry,
  });

  final String title;
  final int n;
  final String mode; // 'positionOnly' | 'audioOnly' | 'mixed'
  final AudioService audioService;
  final VoidCallback onSequenceComplete;
  /// Delay in seconds before showing first visual/audio on grid screens (e.g. 2 for steps 2,3,4,6,7,8).
  final int initialDelaySeconds;
  /// Called with [replay] so the parent can trigger replay (e.g. Retry button).
  final void Function(void Function() replay)? onRegisterRetry;

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
  static const _feedbackDisplayDuration = Duration(milliseconds: 1500);

  late List<DemoStep> _script;
  int _gridIndex = 0;
  _GridSubPhase _gridSubPhase = _GridSubPhase.on;
  _GuidedPhase _phase = _GuidedPhase.gridAnimation;
  Timer? _timer;
  int _fingerTarget = 0; // 0 = none, 1 = visual, 2 = audio (which button is correct next)
  bool _buttonPressedVisual = false;
  bool _buttonPressedAudio = false;
  bool _initialDelayActive = false;
  String? _feedbackText;

  @override
  void initState() {
    super.initState();
    _buildScript();
    widget.onRegisterRetry?.call(_replaySequence);
    if (widget.initialDelaySeconds > 0) {
      _initialDelayActive = true;
      _timer = Timer(Duration(seconds: widget.initialDelaySeconds), () {
        if (!mounted) return;
        setState(() => _initialDelayActive = false);
        _runGridStep();
      });
    } else {
      _runGridStep();
    }
  }

  @override
  void didUpdateWidget(GuidedDemoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onRegisterRetry != widget.onRegisterRetry) {
      widget.onRegisterRetry?.call(_replaySequence);
    }
  }

  void _buildScript() {
    final n = widget.n;
    final mode = widget.mode;
    if (n == 1) {
      if (mode == 'positionOnly') {
        _script = [(position: 0, letter: 'S'), (position: 0, letter: 'H')];
      } else if (mode == 'audioOnly') {
        _script = [(position: 0, letter: 'S'), (position: 1, letter: 'S')];
      } else {
        // Mixed N=1: same position and same audio twice (one cycle).
        _script = [(position: 0, letter: 'S'), (position: 0, letter: 'S')];
      }
    } else {
      if (mode == 'positionOnly') {
        _script = [
          (position: 0, letter: 'S'),
          (position: 1, letter: 'H'),
          (position: 0, letter: 'R'),
        ];
      } else if (mode == 'audioOnly') {
        _script = [
          (position: 0, letter: 'S'),
          (position: 1, letter: 'H'),
          (position: 2, letter: 'S'),
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
      setState(() {
        _phase = _GuidedPhase.waitingForTap;
        // Mixed (4/10, 8/10): 0 = both needed (user can press either first)
        _fingerTarget = widget.mode == 'mixed'
            ? 0
            : (widget.mode == 'positionOnly' ? 1 : 2);
      });
    });
  }

  void _onTapVisual() {
    if (_phase != _GuidedPhase.waitingForTap) return;
    // Accept when we need visual: target 1 (position only) or 0 (mixed, both needed)
    if (_fingerTarget == 1 || _fingerTarget == 0) {
      _onCorrectTap(1);
    } else {
      _onWrongTap();
    }
  }

  void _onTapAudio() {
    if (_phase != _GuidedPhase.waitingForTap) return;
    // Accept when we need audio: target 2 (audio only) or 0 (mixed, both needed)
    if (_fingerTarget == 2 || _fingerTarget == 0) {
      _onCorrectTap(2);
    } else {
      _onWrongTap();
    }
  }

  void _onCorrectTap(int which) {
    _timer?.cancel();
    final list = AppStrings.tutorialFeedbackCorrect;
    final feedback = list[Random().nextInt(list.length)];
    setState(() {
      if (which == 1) {
        _buttonPressedVisual = true;
      } else {
        _buttonPressedAudio = true;
      }
      _feedbackText = feedback;
      _phase = _GuidedPhase.showingFeedback;
    });
    _timer = Timer(_feedbackDisplayDuration, () {
      if (!mounted) return;
      setState(() => _feedbackText = null);
      if (widget.mode == 'mixed' && (!_buttonPressedVisual || !_buttonPressedAudio)) {
        setState(() {
          _fingerTarget = _buttonPressedVisual ? 2 : 1; // need the other one
          _phase = _GuidedPhase.waitingForTap;
        });
      } else {
        _finishSequence();
      }
    });
  }

  void _onWrongTap() {
    _timer?.cancel();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.tutorialWrongTitle),
        content: Text(AppStrings.tutorialWrongRetryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.no),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _replaySequence();
            },
            child: Text(AppStrings.tutorialRetry),
          ),
        ],
      ),
    );
  }

  void _replaySequence() {
    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _gridIndex = 0;
      _gridSubPhase = _GridSubPhase.on;
      _phase = _GuidedPhase.gridAnimation;
      _fingerTarget = 0;
      _buttonPressedVisual = false;
      _buttonPressedAudio = false;
      _feedbackText = null;
    });
    _runGridStep();
  }

  void _finishSequence() {
    if (!mounted) return;
    setState(() => _phase = _GuidedPhase.done);
    widget.onSequenceComplete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _messageText {
    if (_phase == _GuidedPhase.waitingForTap && widget.mode == 'mixed') {
      if (_fingerTarget == 2) return 'Now tap ${AppStrings.audioMatch}.';
      if (_fingerTarget == 1) return 'Now tap ${AppStrings.visualMatch}.';
      // _fingerTarget == 0: both needed (either order)
    }
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
    if (_initialDelayActive) return -1;
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
        SizedBox(height: ResponsiveLayout.spacing(context, 20)),
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
              if (_phase == _GuidedPhase.message ||
                  _phase == _GuidedPhase.waitingForTap ||
                  _phase == _GuidedPhase.showingFeedback)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 100,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _messageText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              height: 1.35,
                            ),
                          ),
                          if (_feedbackText != null) ...[
                            SizedBox(height: ResponsiveLayout.spacing(context, 12)),
                            Text(
                              _feedbackText!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
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
                child: _DemoButton(
                  label: AppStrings.audioMatch,
                  highlighted: _buttonPressedAudio,
                  onPressed: _phase == _GuidedPhase.waitingForTap ? _onTapAudio : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DemoButton(
                  label: AppStrings.visualMatch,
                  highlighted: _buttonPressedVisual,
                  onPressed: _phase == _GuidedPhase.waitingForTap ? _onTapVisual : null,
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
    this.onPressed,
  });

  final String label;
  final bool highlighted;
  final VoidCallback? onPressed;

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
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: highlighted
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            foregroundColor: highlighted
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveLayout.scaledFontSize(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
