import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/services/audio_service.dart';
import '../../../logic/providers/audio_service_provider.dart';
import 'guided_demo_step.dart';

/// Single route for the 10-step guided tutorial flow.
class TutorialFlowScreen extends ConsumerStatefulWidget {
  const TutorialFlowScreen({super.key, this.initialStep = 1});

  final int initialStep;

  @override
  ConsumerState<TutorialFlowScreen> createState() => _TutorialFlowScreenState();
}

class _TutorialFlowScreenState extends ConsumerState<TutorialFlowScreen> {
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(1, 10);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).preloadAudio();
    });
  }

  @override
  void didUpdateWidget(TutorialFlowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStep != widget.initialStep) {
      _currentStep = widget.initialStep.clamp(1, 10);
    }
  }

  void _onBackToHub() {
    context.go('/tutorial');
  }

  void _onPrevious() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _onNext() {
    if (_currentStep < 10) {
      setState(() => _currentStep++);
    }
  }

  void _onGo() {
    context.go('/home');
  }

  void _onSequenceComplete() {
    // Optional: could auto-advance or show feedback; kept for GuidedDemoStep callback.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final isLastStep = _currentStep == 10;
    final canGoPrevious = _currentStep > 1;
    final canGoNext = _currentStep < 10;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackToHub,
          tooltip: 'Back to How to play',
        ),
        title: Text('${AppStrings.helpHubTitle} — $_currentStep/10'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildStepContent(context, audioService),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 48),
                    onPressed: canGoPrevious ? _onPrevious : null,
                    tooltip: 'Previous',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(72, 72),
                    ),
                  ),
                  Expanded(
                    child: isLastStep
                        ? SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _onGo,
                              child: Text(
                                AppStrings.tutorialGo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 72),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 48),
                    onPressed: canGoNext ? _onNext : (isLastStep ? _onGo : null),
                    tooltip: isLastStep ? AppStrings.tutorialGo : 'Next',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(72, 72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, AudioService audioService) {
    switch (_currentStep) {
      case 1:
        return _buildTextStep(
          title: AppStrings.tutorialIntroTitle,
          body: AppStrings.tutorialIntroBody,
          largeText: true,
        );
      case 2:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN1Position,
          n: 1,
          mode: 'positionOnly',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
        );
      case 3:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN1Audio,
          n: 1,
          mode: 'audioOnly',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
        );
      case 4:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN1Mixed,
          n: 1,
          mode: 'mixed',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
        );
      case 5:
        return _buildTextStep(
          title: AppStrings.tutorialN2TransitionTitle,
          body: AppStrings.tutorialN2TransitionBody,
          largeText: true,
        );
      case 6:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN2Position,
          n: 2,
          mode: 'positionOnly',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
        );
      case 7:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN2Audio,
          n: 2,
          mode: 'audioOnly',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
        );
      case 8:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN2Mixed,
          n: 2,
          mode: 'mixed',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
        );
      case 9:
        return _buildTextStep(
          title: AppStrings.tutorialHigherNTitle,
          body: AppStrings.tutorialHigherNBody,
          largeText: true,
        );
      case 10:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              AppStrings.tutorialReadyTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextStep({
    required String title,
    required String body,
    bool largeText = false,
  }) {
    final titleStyle = largeText
        ? Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            )
        : Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            );
    final bodyStyle = largeText
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              height: 1.5,
              fontSize: 22,
            )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.5,
            );
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: largeText ? 24 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: largeText ? 32 : 24),
          Text(
            body,
            style: bodyStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
