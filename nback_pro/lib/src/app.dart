import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/adaptive_theme_wrapper.dart';
import 'data/services/sync_service.dart';
import 'logic/providers/audio_service_provider.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/game_provider.dart';
import 'logic/providers/router_provider.dart';
import 'logic/providers/settings_provider.dart';
import 'logic/providers/stats_provider.dart';
import 'logic/providers/subscription_provider.dart';

class NBackApp extends ConsumerStatefulWidget {
  const NBackApp({super.key});

  @override
  ConsumerState<NBackApp> createState() => _NBackAppState();
}

class _NBackAppState extends ConsumerState<NBackApp> with WidgetsBindingObserver {
  bool _didSyncOnStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Stop focus music on app start (e.g. after hot restart, old native player
    // may still be playing; creating the service and stopping helps on some setups).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).stopFocusMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(audioServiceProvider).stopFocusMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null && !_didSyncOnStart) {
      _didSyncOnStart = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final sync = SyncService();
        final settingsRepo = ref.read(settingsRepositoryProvider);
        final statsRepo = ref.read(statsRepositoryProvider);
        await sync.pull(user.uid, settingsRepo, statsRepo);
        if (!mounted) return;
        ref.invalidate(settingsProvider);
        ref.invalidate(allSessionsProvider);
        ref.invalidate(averageNProvider);
        ref.invalidate(highestNProvider);
        ref.invalidate(currentStreakProvider);
        ref.invalidate(streakDataProvider);
        ref.invalidate(isChallengeCompleteTodayProvider);
        ref.invalidate(daysTrainedInLast7DaysProvider);
        ref.invalidate(last7DaysCompletedProvider);
      });
    }

    final settingsAsync = ref.watch(settingsProvider);
    final storedThemeId = settingsAsync.valueOrNull?.selectedThemeId ?? 0;
    final isPremium = ref.watch(isPremiumProvider);
    final themeId = isPremium ? storedThemeId : 0;
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'N-Back Pro',
      theme: AppTheme.getTheme(themeId),
      routerConfig: router,
      builder: (context, child) => AdaptiveThemeWrapper(child: child),
    );
  }
}
