import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../../logic/providers/stats_provider.dart';
import '../../../logic/providers/subscription_provider.dart';
import '../../widgets/paywall_dialog.dart';

/// Screen to pick N (1–14) for the next session. Speed and grid come from Advanced settings.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  static const int _minN = 1;
  static const int _maxN = 14;
  static const int _freeMaxN = 3;
  static const int _freeSessionsPerDay = 2;

  int _selectedN = 1;
  bool _nInitialized = false;

  Future<void> _onStartTapped() async {
    final isPremium = ref.read(isPremiumProvider);
    final nToUse = _selectedN.clamp(_minN, isPremium ? _maxN : _freeMaxN);
    if (!isPremium && nToUse >= 4) {
      showPaywallDialog(
        context,
        paywallContext: PaywallContext.train,
      );
      return;
    }
    if (!isPremium) {
      final sessionsToday = await ref.read(sessionsCompletedTodayProvider.future);
      if (!mounted) return;
      if (sessionsToday >= _freeSessionsPerDay) {
        showPaywallDialogSessionLimit(context, onDismiss: () {});
        return;
      }
    }
    _startSession();
  }

  void _startSession() {
    final isPremium = ref.read(isPremiumProvider);
    final nToUse = _selectedN.clamp(_minN, isPremium ? _maxN : _freeMaxN);
    ref.read(sessionOverridesProvider.notifier).state = null;
    ref.read(currentNProvider.notifier).state = nToUse;
    context.go('/pre-game', extra: {'n': nToUse});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final currentN = ref.watch(currentNProvider);
    final maxNForUser = isPremium ? _maxN : _freeMaxN;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isAutoN = isPremium ? (settings?.isAutoN ?? true) : true;
    if (!_nInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final maxN = isPremium ? _maxN : _freeMaxN;
        final current = ref.read(currentNProvider).clamp(_minN, maxN);
        final s = ref.read(settingsProvider).valueOrNull;
        final autoN = isPremium ? (s?.isAutoN ?? true) : true;
        if (!autoN && s != null) {
          setState(() {
            _selectedN = (s.manualN).clamp(_minN, maxN);
            _nInitialized = true;
          });
          return;
        }
        setState(() {
          _selectedN = current;
          _nInitialized = true;
        });
      });
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 28,
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: ResponsiveLayout.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.currentNLevelDisplay.replaceAll('%d', '$currentN'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.nextNLevel,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filled(
                              icon: const Icon(Icons.remove),
                              iconSize: 40,
                              onPressed: !isAutoN && _selectedN > _minN
                                  ? () {
                                      setState(() => _selectedN--);
                                      ref.read(settingsProvider.notifier).setManualN(_selectedN);
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 28),
                            Text(
                              'N = $_selectedN',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isAutoN ? theme.colorScheme.onSurfaceVariant : null,
                              ),
                            ),
                            const SizedBox(width: 28),
                            IconButton.filled(
                              icon: const Icon(Icons.add),
                              iconSize: 40,
                              onPressed: isAutoN
                                  ? null
                                  : () {
                                      if (_selectedN < maxNForUser) {
                                        setState(() => _selectedN++);
                                        ref.read(settingsProvider.notifier).setManualN(_selectedN);
                                      } else if (!isPremium && _selectedN == _freeMaxN) {
                                        showPaywallDialog(
                                          context,
                                          paywallContext: PaywallContext.train,
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.horizontalPadding(context),
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Text(
                          isAutoN
                              ? AppStrings.proTrainingAutoNMessage
                              : AppStrings.proTrainingManualNMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveLayout.horizontalPadding(context),
                0,
                ResponsiveLayout.horizontalPadding(context),
                32,
              ),
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _onStartTapped,
                  style: FilledButton.styleFrom(
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text(AppStrings.go),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
