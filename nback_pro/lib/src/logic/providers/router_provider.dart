import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/debug/simulator_debug_screen.dart';
import '../../presentation/screens/debug/simulator_summary_screen.dart';
import '../../presentation/screens/game/game_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/onboarding/login_screen.dart';
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
