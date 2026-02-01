import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/services/audio_service.dart';

/// A single step in the demo script: grid position (0–8) and letter to play.
typedef DemoStep = ({int position, String letter});

/// Animated miniature 3×3 grid matching the game: steps through [script],
/// highlights active cell, plays letter via [audioService], optionally shows
/// letter in the active cell. Loops until disposed.
class MiniatureGridDemo extends StatefulWidget {
  const MiniatureGridDemo({
    super.key,
    required this.script,
    required this.audioService,
    this.showLetterInCell = false,
    this.showGridLines = true,
    this.stepDuration = const Duration(milliseconds: 800),
    this.compact = false,
  });

  final List<DemoStep> script;
  final AudioService audioService;
  final bool showLetterInCell;
  final bool showGridLines;
  final Duration stepDuration;
  /// If true, use smaller padding and icon (e.g. for hub preview).
  final bool compact;

  @override
  State<MiniatureGridDemo> createState() => _MiniatureGridDemoState();
}

class _MiniatureGridDemoState extends State<MiniatureGridDemo> {
  int _currentStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.script.isEmpty) return;
    _playCurrentStep();
    _timer = Timer.periodic(widget.stepDuration, (_) {
      if (!mounted) return;
      setState(() => _currentStep = (_currentStep + 1) % widget.script.length);
      _playCurrentStep();
    });
  }

  void _playCurrentStep() {
    if (widget.script.isEmpty) return;
    final step = widget.script[_currentStep];
    widget.audioService.playLetter(step.letter);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.script.isEmpty) {
      return const SizedBox.shrink();
    }
    final step = widget.script[_currentStep];
    final activePosition = step.position;
    final showGrid = widget.showGridLines;
    final padding = widget.compact ? 8.0 : 24.0;
    final iconSize = widget.compact ? 24.0 : 48.0;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: showGrid ? 2 : 0,
                mainAxisSpacing: showGrid ? 2 : 0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isActive = index == activePosition;
                return Container(
                  decoration: BoxDecoration(
                    color: showGrid
                        ? (isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).cardColor)
                        : (isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent),
                    border: showGrid
                        ? Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.25),
                            width: 1,
                          )
                        : null,
                  ),
                  child: widget.showLetterInCell && isActive
                      ? Center(
                          child: Text(
                            step.letter,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        )
                      : null,
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
    );
  }
}
