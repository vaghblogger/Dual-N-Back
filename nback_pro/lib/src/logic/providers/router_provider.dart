import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/debug/simulator_debug_screen.dart';
import '../../presentation/screens/debug/simulator_summary_screen.dart';
import '../../presentation/screens/game/game_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/paywall/paywall_screen.dart';
import '../../presentation/screens/pre_game/pre_game_screen.dart';
import '../../presentation/screens/onboarding/login_screen.dart';
import '../../presentation/screens/settings/advanced_settings_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/session_summary/session_summary_screen.dart';
import '../../presentation/screens/statistics/stats_screen.dart';
import '../../presentation/screens/train/train_screen.dart';
import '../../presentation/screens/tutorial/n1_rules_screen.dart';
import '../../presentation/screens/tutorial/n2_rules_screen.dart';
import '../../presentation/screens/tutorial/progression_info_screen.dart';
import '../../presentation/screens/tutorial/tutorial_flow_screen.dart';
import '../../presentation/screens/tutorial/tutorial_screen.dart';
import 'auth_provider.dart';
import 'onboarding_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final currentUser = ref.read(authServiceProvider).currentUser;
      final completed = await ref.read(onboardingCompleteProvider.future);
      final location = state.matchedLocation;

      // Google signed in: allow all app routes; redirect / or /login to /home (except login from settings)
      if (currentUser != null) {
        if (location == '/' || location == '/login') {
          if (location == '/login' &&
              state.uri.queryParameters['from'] == 'settings') {
            return null;
          }
          return '/home';
        }
        return null;
      }

      // Not signed in with Google: / and /login are the entry points; no theme selection on start
      if (!completed && location != '/' && location != '/login') {
        return '/';
      }
      // First time after onboarding: redirect to tutorial if not yet completed
      if (completed && location == '/home') {
        final tutorialDone = await ref.read(tutorialCompleteProvider.future);
        if (!tutorialDone) return '/tutorial/flow';
      }
      // Redirect old tutorial paths to new flow
      if (location == '/tutorial/n1') return '/tutorial/flow?start=1';
      if (location == '/tutorial/n2') return '/tutorial/flow?start=5';

      // Guest (completed && isGuest): allow all in-app routes - no redirect to /login
      return null;
    },
    routes: [
      // App starts at login; dark theme by default. Theme selection only in Settings.
      GoRoute(
        path: '/',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/train',
        builder: (context, _) => const TrainScreen(),
      ),
      GoRoute(
        path: '/tutorial',
        builder: (context, _) => const TutorialScreen(),
      ),
      GoRoute(
        path: '/tutorial/flow',
        builder: (context, state) {
          final start = int.tryParse(state.uri.queryParameters['start'] ?? '1') ?? 1;
          return TutorialFlowScreen(initialStep: start.clamp(1, 10));
        },
      ),
      GoRoute(
        path: '/tutorial/n1',
        builder: (context, _) => const N1RulesScreen(),
      ),
      GoRoute(
        path: '/tutorial/n2',
        builder: (context, _) => const N2RulesScreen(),
      ),
      GoRoute(
        path: '/tutorial/progression',
        builder: (context, _) => const ProgressionInfoScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) {
          final extra = state.extra is Map ? state.extra as Map<Object?, Object?> : null;
          final title = extra?['title'] as String?;
          final message = extra?['message'] as String?;
          final ctx = extra?['paywallContext'];
          final fromTutorial = extra?['fromTutorial'] == true;
          PaywallContext paywallContext = PaywallContext.progress;
          if (ctx is PaywallContext) paywallContext = ctx;
          return PaywallScreen(
            title: title,
            message: message,
            paywallContext: paywallContext,
            fromTutorial: fromTutorial,
          );
        },
      ),
      GoRoute(
        path: '/pre-game',
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? extra as Map<Object?, Object?> : null;
          final n = map != null ? (map['n'] as int?) ?? 1 : 1;
          final fromDailyChallenge = map != null && (map['fromDailyChallenge'] == true);
          return PreGameScreen(n: n.clamp(1, 14), fromDailyChallenge: fromDailyChallenge);
        },
      ),
      GoRoute(
        path: '/game',
        builder: (context, _) => const GameScreen(),
      ),
      GoRoute(
        path: '/session-summary',
        builder: (context, _) => const SessionSummaryScreen(),
      ),
      GoRoute(
        path: '/simulator-summary',
        builder: (context, _) => const SimulatorSummaryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/advanced',
        builder: (context, _) => const AdvancedSettingsScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, _) => const StatsScreen(),
      ),
      GoRoute(
        path: '/debug',
        builder: (context, _) => const SimulatorDebugScreen(),
      ),
    ],
  );
});
