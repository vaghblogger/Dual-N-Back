import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/game_provider.dart';

String _randomMotivationalMessage() {
  final list = List<String>.from(AppStrings.motivationalMessages);
  list.shuffle(Random());
  return list.isNotEmpty ? list.first : AppStrings.motivationalMessages.first;
}

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(lastSessionSummaryProvider);

    if (data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nMessage = _nMessage(data.isAutoN, data.newN, data.nLevel);
    final motivationalMessage = _randomMotivationalMessage();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                AppStrings.sessionComplete,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Text(
                    motivationalMessage,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.sessionResults,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.nLevel.replaceAll('%d', '${data.nLevel}'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.audioAccuracy
                    .replaceAll('%d', '${(data.audioScore * 100).round()}'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.visualAccuracy
                    .replaceAll('%d', '${(data.visualScore * 100).round()}'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.overallAccuracy
                    .replaceAll('%d', '${(data.totalAccuracy * 100).round()}'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (data.isAutoN) ...[
                const SizedBox(height: 8),
                Text(
                  nMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(lastSessionSummaryProvider.notifier).state = null;
                    context.go('/home');
                  },
                  child: const Text(AppStrings.home),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

String _nMessage(bool isAutoN, int newN, int nLevel) {
  if (!isAutoN) return AppStrings.nLevelMaintained;
  if (newN > nLevel) return AppStrings.nLevelIncreased;
  if (newN < nLevel) return AppStrings.nLevelDecreased;
  return AppStrings.nLevelMaintained;
}
