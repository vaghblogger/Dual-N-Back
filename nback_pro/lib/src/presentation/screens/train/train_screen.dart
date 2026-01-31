import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/game_provider.dart';

/// Screen to pick N (1–15) for a single session and start the game.
/// Does not change app-level Settings (Auto N / My N); only this session uses the selected N.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  static const int _minN = 1;
  static const int _maxN = 15;

  int _selectedN = 1;

  void _startSession() {
    ref.read(gameSessionProvider.notifier).startSession(_selectedN);
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          AppStrings.trainYourBrain,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.remove),
                    iconSize: 32,
                    onPressed: _selectedN > _minN
                        ? () => setState(() => _selectedN--)
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'N = $_selectedN',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    iconSize: 32,
                    onPressed: _selectedN < _maxN
                        ? () => setState(() => _selectedN++)
                        : null,
                  ),
                ],
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: FilledButton(
                  onPressed: _startSession,
                  style: FilledButton.styleFrom(
                    textStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text(AppStrings.go),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
