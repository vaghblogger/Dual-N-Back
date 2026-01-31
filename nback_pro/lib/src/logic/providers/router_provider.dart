import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/game/game_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/onboarding/login_screen.dart';
import '../../presentation/screens/onboarding/theme_selection_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/session_summary/session_summary_screen.dart';
import '../../presentation/screens/statistics/stats_screen.dart';
import '../../presentation/screens/train/train_screen.dart';
import '../../presentation/screens/tutorial/n2_rules_screen.dart';
import '../../presentation/screens/tutorial/progression_info_screen.dart';
import '../../presentation/screens/tutorial/tutorial_screen.dart';
import 'onboarding_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final completed = await ref.read(onboardingCompleteProvider.future);
      final location = state.matchedLocation;
      if (completed && (location == '/' || location == '/login')) {
        return '/home';
      }
      if (!completed && location != '/' && location != '/login') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => const ThemeSelectionScreen(),
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
        path: '/settings',
        builder: (context, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, _) => const StatsScreen(),
      ),
    ],
  );
});
