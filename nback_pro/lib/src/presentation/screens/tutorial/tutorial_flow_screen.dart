import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../data/services/audio_service.dart';
import '../../../logic/providers/audio_service_provider.dart';
import '../../../logic/providers/onboarding_provider.dart';
import '../../widgets/paywall_dialog.dart';
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
  VoidCallback? _retryCallback;

  static const _demoSteps = [2, 3, 4, 6, 7, 8];

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
      if (!_demoSteps.contains(_currentStep)) _retryCallback = null;
    }
  }

  void _onBackToHub() {
    context.go('/tutorial');
  }

  void _onPrevious() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        if (!_demoSteps.contains(_currentStep)) _retryCallback = null;
      });
    }
  }

  void _onNext() {
    if (_currentStep < 10) {
      setState(() {
        _currentStep++;
        if (!_demoSteps.contains(_currentStep)) _retryCallback = null;
      });
    }
  }

  void _onRetry() {
    _retryCallback?.call();
  }

  void _onGo() async {
    await setTutorialComplete(true);
    if (!mounted) return;
    ref.invalidate(tutorialCompleteProvider);
    context.push('/paywall', extra: <String, dynamic>{
      'title': 'Unlock Pro',
      'message': AppStrings.paywallAfterTutorialMessage,
      'paywallContext': PaywallContext.train,
      'fromTutorial': true,
    });
  }

  void _onSkip() async {
    await setTutorialComplete(true);
    if (!mounted) return;
    ref.invalidate(tutorialCompleteProvider);
    context.push('/paywall', extra: <String, dynamic>{
      'title': 'Unlock Pro',
      'message': AppStrings.paywallAfterTutorialMessage,
      'paywallContext': PaywallContext.train,
      'fromTutorial': true,
    });
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
        padding: EdgeInsets.all(ResponsiveLayout.spacing(context, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildStepContent(context, audioService),
              ),
            ),
            SizedBox(height: ResponsiveLayout.spacing(context, 16)),
            Padding(
              padding: EdgeInsets.only(bottom: ResponsiveLayout.spacing(context, 24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row: < Previous    RETRY    Next >
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavButton(
                        label: '< ${AppStrings.tutorialPrevious}',
                        onPressed: canGoPrevious ? _onPrevious : null,
                      ),
                      _NavButton(
                        label: AppStrings.tutorialRetry.toUpperCase(),
                        onPressed: (_retryCallback != null) ? _onRetry : null,
                        emphasized: true,
                      ),
                      if (isLastStep)
                        _NavButton(
                          label: AppStrings.tutorialGo,
                          onPressed: _onGo,
                          emphasized: true,
                        )
                      else
                        _NavButton(
                          label: '${AppStrings.tutorialNext} >',
                          onPressed: _onNext,
                        ),
                    ],
                  ),
                  SizedBox(height: ResponsiveLayout.spacing(context, 12)),
                  // Full-width: [I know how N-Back works]
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveLayout.buttonMinHeight(context),
                    child: OutlinedButton(
                      onPressed: _onSkip,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveLayout.spacing(context, 14),
                          horizontal: ResponsiveLayout.spacing(context, 20),
                        ),
                      ),
                      child: Text(AppStrings.tutorialSkip),
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
          initialDelaySeconds: 2,
          onRegisterRetry: (replay) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _retryCallback = replay);
          }),
        );
      case 3:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN1Audio,
          n: 1,
          mode: 'audioOnly',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
          initialDelaySeconds: 2,
          onRegisterRetry: (replay) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _retryCallback = replay);
          }),
        );
      case 4:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN1Mixed,
          n: 1,
          mode: 'mixed',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
          initialDelaySeconds: 2,
          onRegisterRetry: (replay) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _retryCallback = replay);
          }),
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
          initialDelaySeconds: 2,
          onRegisterRetry: (replay) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _retryCallback = replay);
          }),
        );
      case 7:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN2Audio,
          n: 2,
          mode: 'audioOnly',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
          initialDelaySeconds: 2,
          onRegisterRetry: (replay) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _retryCallback = replay);
          }),
        );
      case 8:
        return GuidedDemoStep(
          key: ValueKey('tutorial_step_$_currentStep'),
          title: AppStrings.tutorialStepTitleN2Mixed,
          n: 2,
          mode: 'mixed',
          audioService: audioService,
          onSequenceComplete: _onSequenceComplete,
          initialDelaySeconds: 2,
          onRegisterRetry: (replay) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _retryCallback = replay);
          }),
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
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveLayout.spacing(context, 32),
            ),
            child: Text(
              AppStrings.tutorialReadyTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveLayout.scaledFontSize(context, 28),
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
              fontSize: ResponsiveLayout.scaledFontSize(context, 28),
            )
        : Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            );
    final bodyStyle = largeText
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              height: 1.5,
              fontSize: ResponsiveLayout.scaledFontSize(context, 22),
            )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.5,
            );
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveLayout.spacing(context, largeText ? 24 : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveLayout.spacing(context, largeText ? 32 : 24)),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ElevatedButton.styleFrom(
      minimumSize: Size(0, ResponsiveLayout.buttonMinHeight(context)),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.spacing(context, 20),
        vertical: ResponsiveLayout.spacing(context, 14),
      ),
      textStyle: TextStyle(
        fontSize: ResponsiveLayout.scaledFontSize(context, 17),
        fontWeight: emphasized ? FontWeight.bold : FontWeight.w600,
        letterSpacing: emphasized ? 0.5 : 0.2,
      ),
      backgroundColor: emphasized ? theme.colorScheme.primaryContainer : null,
      foregroundColor: emphasized ? theme.colorScheme.onPrimaryContainer : null,
    );
    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}
