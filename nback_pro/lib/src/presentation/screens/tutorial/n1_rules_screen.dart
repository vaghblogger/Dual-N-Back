import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/audio_service_provider.dart';
import 'phased_tutorial_demo.dart';
import 'tutorial_helpers.dart';

class N1RulesScreen extends ConsumerStatefulWidget {
  const N1RulesScreen({super.key});

  @override
  ConsumerState<N1RulesScreen> createState() => _N1RulesScreenState();
}

class _N1RulesScreenState extends ConsumerState<N1RulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).preloadAudio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tutorial'),
        ),
        title: const Text(AppStrings.n1RulesTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepItem(number: 1, text: AppStrings.n1Step1),
                    const SizedBox(height: 16),
                    _StepItem(number: 2, text: AppStrings.n1Step2),
                    const SizedBox(height: 16),
                    _StepItem(number: 3, text: AppStrings.n1Step3),
                    const SizedBox(height: 16),
                    _StepItem(number: 4, text: AppStrings.n1Step4),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        height: 380,
                        width: 320,
                        child: PhasedTutorialDemo(
                          n: 1,
                          audioService: audioService,
                          stepDuration: const Duration(milliseconds: 2500),
                          fingerDuration: const Duration(milliseconds: 2000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/tutorial/n2'),
                child: const Text(AppStrings.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(child: buildStepText(context, text)),
      ],
    );
  }
}
