import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/game_provider.dart';
import '../../logic/providers/onboarding_provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../../logic/providers/stats_provider.dart';
import 'notification_service.dart';

/// Performs a full app reset: clears all local data (Hive, SharedPreferences),
/// signs out, cancels daily reminder, and invalidates providers so the app
/// behaves like a fresh installation. Call this then navigate to '/' (onboarding).
Future<void> resetApp(WidgetRef ref) async {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final statsRepo = ref.read(statsRepositoryProvider);
  await settingsRepo.closeAndDeleteAll();
  await statsRepo.closeAndDeleteAll();

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_complete');
  await prefs.remove('is_guest');

  final auth = ref.read(authServiceProvider);
  await auth.signOut();

  final notificationService = NotificationService();
  await notificationService.cancelDailyReminder();

  ref.invalidate(authStateChangesProvider);
  ref.invalidate(onboardingCompleteProvider);
  ref.invalidate(isGuestProvider);
  ref.invalidate(settingsProvider);
  ref.invalidate(allSessionsProvider);
  ref.invalidate(averageNProvider);
  ref.invalidate(highestNProvider);
  ref.invalidate(currentStreakProvider);
  ref.invalidate(streakDataProvider);
  ref.invalidate(isChallengeCompleteTodayProvider);
  ref.invalidate(daysTrainedInLast7DaysProvider);
  ref.invalidate(last7DaysCompletedProvider);
}
